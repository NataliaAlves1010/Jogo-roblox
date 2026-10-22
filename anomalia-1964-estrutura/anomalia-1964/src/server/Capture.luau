--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverFolder = script.Parent
local guardFolder = serverFolder:WaitForChild("Guard")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local checkpointsModule = serverFolder:WaitForChild("Checkpoints") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local chaseModule = guardFolder:WaitForChild("Chase") :: ModuleScript
local patrolModule = guardFolder:WaitForChild("Patrol") :: ModuleScript
local Checkpoints = require(checkpointsModule)
local Config = require(configModule)
local Chase = require(chaseModule)
local Patrol = require(patrolModule)

local Capture = {}

type Controle = {
    Conexoes: { RBXScriptConnection },
    ContatoValidado: { [Player]: boolean },
    EmCaptura: boolean,
}

local controles: { [Model]: Controle } = {}

local function obterPersonagem(jogador: Player): (Model?, Humanoid?, BasePart?)
    local personagem = jogador.Character
    if personagem == nil then
        return nil, nil, nil
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if humanoide == nil or raiz == nil or not raiz:IsA("BasePart") then
        return personagem, nil, nil
    end

    return personagem, humanoide, raiz
end

local function reiniciarPatrulha(guarda: Model)
    local zona = guarda.Parent
    local mapa = if zona ~= nil then zona.Parent else nil
    if mapa ~= nil and mapa:IsA("Folder") and guarda.Parent ~= nil then
        Patrol.iniciar(guarda, mapa)
    end
end

function Capture.capturar(guarda: Model, jogador: Player): ()
    local controle = controles[guarda]
    if controle == nil or controle.EmCaptura or controle.ContatoValidado[jogador] ~= true then
        return
    end

    local personagem, humanoide, raiz = obterPersonagem(jogador)
    local humanoideGuarda = guarda:FindFirstChildOfClass("Humanoid")
    if
        jogador.Parent ~= Players
        or personagem == nil
        or humanoide == nil
        or humanoide.Health <= 0
        or raiz == nil
        or humanoideGuarda == nil
        or humanoideGuarda.Health <= 0
    then
        return
    end

    local checkpoint = Checkpoints.obter(jogador)
    if checkpoint == nil then
        warn("A captura foi ignorada porque o jogador ainda não tem checkpoint inicializado.")
        return
    end

    controle.EmCaptura = true
    Chase.parar(guarda)
    Patrol.parar(guarda)

    task.delay(Config.Timing.CaptureRespawnDelay, function()
        if jogador.Parent == Players then
            local personagemAtual, humanoideAtual, raizAtual = obterPersonagem(jogador)
            local checkpointAtual = Checkpoints.obter(jogador)
            if personagemAtual ~= nil and humanoideAtual ~= nil and raizAtual ~= nil and checkpointAtual ~= nil then
                personagemAtual:PivotTo(checkpointAtual)
                raizAtual.AssemblyLinearVelocity = Vector3.zero
                raizAtual.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if humanoideGuarda ~= nil and humanoideGuarda.Health > 0 and guarda.Parent ~= nil then
            guarda:SetAttribute("EstadoGuarda", "Patrulha")
            guarda:SetAttribute("UltimoPontoVisto", nil)
            reiniciarPatrulha(guarda)
        end
        controle.EmCaptura = false
    end)
end

function Capture.inicializar(guarda: Model): ()
    if controles[guarda] ~= nil then
        return
    end

    local controle: Controle = {
        Conexoes = {},
        ContatoValidado = {},
        EmCaptura = false,
    }
    controles[guarda] = controle

    for _, parte in guarda:GetDescendants() do
        if parte:IsA("BasePart") and parte.CanTouch then
            table.insert(
                controle.Conexoes,
                parte.Touched:Connect(function(parteTocada)
                    local personagem = parteTocada:FindFirstAncestorOfClass("Model")
                    if personagem == nil then
                        return
                    end

                    local jogador = Players:GetPlayerFromCharacter(personagem)
                    if jogador == nil then
                        return
                    end

                    controle.ContatoValidado[jogador] = true
                    Capture.capturar(guarda, jogador)
                    controle.ContatoValidado[jogador] = nil
                end)
            )
        end
    end

    table.insert(
        controle.Conexoes,
        guarda.Destroying:Connect(function()
            for _, conexao in controle.Conexoes do
                conexao:Disconnect()
            end
            controles[guarda] = nil
        end)
    )
end

return Capture
