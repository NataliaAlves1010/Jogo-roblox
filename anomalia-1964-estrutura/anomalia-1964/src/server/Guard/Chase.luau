--!strict

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local visionModule = script.Parent:WaitForChild("Vision") :: ModuleScript
local Config = require(configModule)
local Vision = require(visionModule)

local Chase = {}

type Controle = {
    Ativo: boolean,
}

local controles: { [Model]: Controle } = {}

local function obterRaiz(modelo: Model): BasePart?
    local raiz = modelo:FindFirstChild("HumanoidRootPart")
    if raiz ~= nil and raiz:IsA("BasePart") then
        return raiz
    end

    return nil
end

local function calcularProximoPonto(guarda: Model, raizGuarda: BasePart, raizAlvo: BasePart): Vector3?
    local caminho = PathfindingService:CreatePath()
    local calculado = pcall(function()
        caminho:ComputeAsync(raizGuarda.Position, raizAlvo.Position)
    end)

    if not calculado or caminho.Status ~= Enum.PathStatus.Success then
        caminho:Destroy()
        return nil
    end

    local waypoints = caminho:GetWaypoints()
    local proximoWaypoint = waypoints[2] or waypoints[1]
    local posicao = if proximoWaypoint ~= nil then proximoWaypoint.Position else raizAlvo.Position
    if proximoWaypoint ~= nil and proximoWaypoint.Action == Enum.PathWaypointAction.Jump then
        local humanoide = guarda:FindFirstChildOfClass("Humanoid")
        if humanoide ~= nil then
            humanoide.Jump = true
        end
    end

    caminho:Destroy()
    return posicao
end

local function encerrar(guarda: Model, controle: Controle)
    controle.Ativo = false
    if controles[guarda] ~= controle then
        return
    end

    controles[guarda] = nil
    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raiz = obterRaiz(guarda)
    if humanoide ~= nil and raiz ~= nil then
        humanoide:MoveTo(raiz.Position)
    end
end

function Chase.parar(guarda: Model): ()
    local controle = controles[guarda]
    if controle ~= nil then
        encerrar(guarda, controle)
    end
end

function Chase.iniciar(guarda: Model, alvo: Player): ()
    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raizGuarda = obterRaiz(guarda)
    assert(humanoide ~= nil, "O guarda precisa ter um Humanoid para perseguir")
    assert(raizGuarda ~= nil, "O guarda precisa ter uma raiz válida para perseguir")
    local velocidadeConfigurada = guarda:GetAttribute("VelocidadeAgressiva")
    local velocidade = if typeof(velocidadeConfigurada) == "number"
        then velocidadeConfigurada
        else Config.Movement.GuardWalkSpeed
    assert(velocidade < Config.Movement.PlayerWalkSpeed, "A velocidade do guarda precisa ser menor que a do jogador")

    Chase.parar(guarda)
    humanoide.WalkSpeed = velocidade
    local controle: Controle = { Ativo = true }
    controles[guarda] = controle

    task.spawn(function()
        while controle.Ativo and guarda.Parent ~= nil and alvo.Parent == Players do
            local personagem = alvo.Character
            local humanoideAlvo = if personagem ~= nil then personagem:FindFirstChildOfClass("Humanoid") else nil
            local raizAlvo = if personagem ~= nil then obterRaiz(personagem) else nil

            if
                humanoide.Health <= 0
                or humanoideAlvo == nil
                or humanoideAlvo.Health <= 0
                or raizAlvo == nil
                or not Vision.detectar(guarda, alvo)
            then
                break
            end

            local proximaPosicao = calcularProximoPonto(guarda, raizGuarda, raizAlvo)
            if proximaPosicao ~= nil and controle.Ativo then
                humanoide:MoveTo(proximaPosicao)
            end

            task.wait(Config.Timing.GuardRepathInterval)
        end

        encerrar(guarda, controle)
    end)
end

return Chase
