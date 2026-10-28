--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local visionModule = script.Parent:WaitForChild("Vision") :: ModuleScript
local Config = require(configModule)
local Vision = require(visionModule)

local StateMachine = {}

export type Estado = "Patrulha" | "Suspeito" | "Perseguição" | "Busca"

type Controle = {
    Estado: Estado,
    Ativo: boolean,
    InicioBusca: number?,
    UltimoPontoVisto: Vector3?,
}

local controles: { [Model]: Controle } = {}
local velocidadeBase = Config.Movement.GuardWalkSpeed
local alcanceBase = Config.GuardVision.Range

local function alterarEstado(guarda: Model, controle: Controle, estado: Estado)
    if controle.Estado == estado then
        return
    end

    controle.Estado = estado
    guarda:SetAttribute("EstadoGuarda", estado)

    if estado == "Busca" then
        controle.InicioBusca = os.clock()
    elseif estado == "Patrulha" then
        controle.InicioBusca = nil
        controle.UltimoPontoVisto = nil
        guarda:SetAttribute("UltimoPontoVisto", nil)
    end
end

local function obterJogadorVisivel(guarda: Model): Player?
    local raizGuarda = guarda:FindFirstChild("HumanoidRootPart")
    if raizGuarda == nil or not raizGuarda:IsA("BasePart") then
        return nil
    end

    local jogadorMaisProximo: Player? = nil
    local menorDistancia = math.huge

    for _, jogador in Players:GetPlayers() do
        if Vision.detectar(guarda, jogador) then
            local personagem = jogador.Character
            local raizJogador = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
            if raizJogador ~= nil and raizJogador:IsA("BasePart") then
                local distancia = (raizJogador.Position - raizGuarda.Position).Magnitude
                if distancia < menorDistancia then
                    menorDistancia = distancia
                    jogadorMaisProximo = jogador
                end
            end
        end
    end

    return jogadorMaisProximo
end

local function registrarPontoVisto(guarda: Model, controle: Controle, jogador: Player)
    local personagem = jogador.Character
    local raiz = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
    if raiz ~= nil and raiz:IsA("BasePart") then
        controle.UltimoPontoVisto = raiz.Position
        guarda:SetAttribute("UltimoPontoVisto", raiz.Position)
    end
end

function StateMachine.inicializar(guarda: Model): ()
    if controles[guarda] ~= nil then
        return
    end

    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    if humanoide == nil then
        warn("A máquina de estados não iniciou: o guarda não tem Humanoid.")
        return
    end

    local controle: Controle = {
        Estado = "Patrulha",
        Ativo = true,
        InicioBusca = nil,
        UltimoPontoVisto = nil,
    }
    controles[guarda] = controle
    guarda:SetAttribute("EstadoGuarda", controle.Estado)
    guarda:SetAttribute("UltimoPontoVisto", nil)
    guarda:SetAttribute("VelocidadeAgressiva", Config.Movement.GuardWalkSpeed)

    task.spawn(function()
        while controle.Ativo and guarda.Parent ~= nil and humanoide.Health > 0 do
            local jogadorVisivel = obterJogadorVisivel(guarda)
            if jogadorVisivel ~= nil then
                registrarPontoVisto(guarda, controle, jogadorVisivel)
            end

            if controle.Estado == "Patrulha" then
                if jogadorVisivel ~= nil then
                    alterarEstado(guarda, controle, "Suspeito")
                end
            elseif controle.Estado == "Suspeito" then
                if jogadorVisivel ~= nil then
                    alterarEstado(guarda, controle, "Perseguição")
                else
                    alterarEstado(guarda, controle, "Busca")
                end
            elseif controle.Estado == "Perseguição" then
                if jogadorVisivel == nil then
                    alterarEstado(guarda, controle, "Busca")
                end
            elseif controle.Estado == "Busca" then
                if jogadorVisivel ~= nil then
                    alterarEstado(guarda, controle, "Suspeito")
                elseif
                    controle.InicioBusca ~= nil
                    and os.clock() - controle.InicioBusca >= Config.Timing.GuardSearchDuration
                then
                    alterarEstado(guarda, controle, "Patrulha")
                end
            end

            task.wait(Config.Timing.GuardRepathInterval)
        end

        controle.Ativo = false
        if controles[guarda] == controle then
            controles[guarda] = nil
        end
    end)
end

function StateMachine.investigarRuido(posicao: Vector3): ()
    for guarda, controle in controles do
        if controle.Ativo and guarda.Parent ~= nil then
            controle.UltimoPontoVisto = posicao
            controle.InicioBusca = nil
            guarda:SetAttribute("UltimoPontoVisto", posicao)
            alterarEstado(guarda, controle, "Suspeito")
        end
    end
end

function StateMachine.atualizarAgressividade(totalPistasColetadas: number): ()
    local agressividade = Config.GuardAggression
    local nivel = if totalPistasColetadas == totalPistasColetadas
        then math.clamp(math.floor(totalPistasColetadas), 0, agressividade.MaximumClues)
        else 0
    local velocidade = math.min(velocidadeBase + nivel * agressividade.WalkSpeedPerClue, agressividade.MaximumWalkSpeed)
    Config.Movement.GuardWalkSpeed = velocidade
    Config.GuardVision.Range = alcanceBase + nivel * agressividade.VisionRangePerClue

    for guarda, controle in controles do
        if controle.Ativo and guarda.Parent ~= nil then
            guarda:SetAttribute("VelocidadeAgressiva", velocidade)
            local humanoide = guarda:FindFirstChildOfClass("Humanoid")
            if humanoide ~= nil and humanoide.Health > 0 then
                humanoide.WalkSpeed = velocidade
            end
        end
    end
end

function StateMachine.obter(guarda: Model): Estado
    local controle = controles[guarda]
    return if controle ~= nil then controle.Estado else "Patrulha"
end

return StateMachine
