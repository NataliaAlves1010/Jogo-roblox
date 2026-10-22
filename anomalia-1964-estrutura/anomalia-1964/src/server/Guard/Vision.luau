--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local Vision = {}

local function obterParteDeVisao(modelo: Model, nome: string, fallback: BasePart): BasePart
    local parte = modelo:FindFirstChild(nome)
    if parte ~= nil and parte:IsA("BasePart") then
        return parte
    end

    return fallback
end

function Vision.detectar(guarda: Model, jogador: Player): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end
    if jogador:GetAttribute("DentroDoDuto") == true or personagem:GetAttribute("DentroDoDuto") == true then
        return false
    end

    local humanoideGuarda = guarda:FindFirstChildOfClass("Humanoid")
    local raizGuarda = guarda:FindFirstChild("HumanoidRootPart")
    local humanoideJogador = personagem:FindFirstChildOfClass("Humanoid")
    local raizJogador = personagem:FindFirstChild("HumanoidRootPart")
    if
        humanoideGuarda == nil
        or humanoideGuarda.Health <= 0
        or raizGuarda == nil
        or not raizGuarda:IsA("BasePart")
        or humanoideJogador == nil
        or humanoideJogador.Health <= 0
        or raizJogador == nil
        or not raizJogador:IsA("BasePart")
    then
        return false
    end

    local cabecaGuarda = obterParteDeVisao(guarda, "Head", raizGuarda)
    local cabecaJogador = obterParteDeVisao(personagem, "Head", raizJogador)
    local deslocamento = cabecaJogador.Position - cabecaGuarda.Position
    local distancia = deslocamento.Magnitude
    if distancia > Config.GuardVision.Range then
        return false
    end

    local direcaoHorizontal = Vector3.new(deslocamento.X, 0, deslocamento.Z)
    local frente = raizGuarda.CFrame.LookVector
    local frenteHorizontal = Vector3.new(frente.X, 0, frente.Z)
    if direcaoHorizontal.Magnitude > 0 and frenteHorizontal.Magnitude > 0 then
        local anguloMetade = math.rad(Config.GuardVision.FieldOfViewDegrees / 2)
        local limiteCone = math.cos(anguloMetade)
        if frenteHorizontal.Unit:Dot(direcaoHorizontal.Unit) < limiteCone then
            return false
        end
    end

    local parametrosRaio = RaycastParams.new()
    parametrosRaio.FilterType = Enum.RaycastFilterType.Exclude
    parametrosRaio.FilterDescendantsInstances = { guarda }
    parametrosRaio.IgnoreWater = true

    local resultado = Workspace:Raycast(cabecaGuarda.Position, deslocamento, parametrosRaio)
    return resultado == nil or resultado.Instance:IsDescendantOf(personagem)
end

return Vision
