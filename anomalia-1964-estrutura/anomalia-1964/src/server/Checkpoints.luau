--!strict

local Players = game:GetService("Players")
local zonesModule = script.Parent:WaitForChild("Zones") :: ModuleScript
local Zones = require(zonesModule)

local Checkpoints = {}

type Zona = Zones.Zona

type Ponto = {
    Nome: string,
    CFrameBase: CFrame,
}

local pontoInicial: Ponto? = nil
local pontosPorJogador: { [number]: Ponto } = {}
local inicializado = false

local function cframeDoPersonagem(ponto: Ponto, personagem: Model?): CFrame
    if personagem == nil then
        return ponto.CFrameBase
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")

    if humanoide ~= nil and raiz ~= nil and raiz:IsA("BasePart") then
        local altura = humanoide.HipHeight + raiz.Size.Y / 2
        return ponto.CFrameBase + Vector3.new(0, altura, 0)
    end

    return ponto.CFrameBase
end

local function pontoDoJogador(jogador: Player): Ponto?
    return pontosPorJogador[jogador.UserId] or pontoInicial
end

local function restaurarPersonagem(jogador: Player, personagem: Model)
    task.spawn(function()
        personagem:WaitForChild("Humanoid")
        local raiz = personagem:WaitForChild("HumanoidRootPart") :: BasePart
        local ponto = pontoDoJogador(jogador)

        if ponto == nil then
            return
        end

        local cframe = cframeDoPersonagem(ponto, personagem)
        raiz.CFrame = cframe
        raiz.AssemblyLinearVelocity = Vector3.zero
        raiz.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function conectarJogador(jogador: Player)
    jogador.CharacterAdded:Connect(function(personagem)
        restaurarPersonagem(jogador, personagem)
    end)

    if jogador.Character ~= nil then
        restaurarPersonagem(jogador, jogador.Character)
    end
end

local function configurarZona(zona: Zona): Ponto
    local linhaCentral = math.floor((zona.LinhaInicial + zona.LinhaFinal) / 2)
    local colunaCentral = math.floor((zona.ColunaInicial + zona.ColunaFinal) / 2)
    local nomePiso = string.format("Piso_%d_%d", linhaCentral, colunaCentral)
    local piso = zona.Pasta:FindFirstChild(nomePiso)
    assert(piso ~= nil and piso:IsA("BasePart"), "A zona precisa ter um piso central válido")

    piso:SetAttribute("PontoCheckpoint", true)
    piso:SetAttribute("ZonaCheckpoint", zona.Nome)

    local ponto: Ponto = {
        Nome = zona.Nome,
        CFrameBase = piso.CFrame + Vector3.new(0, piso.Size.Y / 2, 0),
    }

    piso.Touched:Connect(function(parte)
        local personagem = parte:FindFirstAncestorOfClass("Model")
        if personagem == nil then
            return
        end

        local jogador = Players:GetPlayerFromCharacter(personagem)
        if jogador ~= nil then
            pontosPorJogador[jogador.UserId] = ponto
            jogador:SetAttribute("UltimoCheckpoint", ponto.Nome)
        end
    end)

    return ponto
end

function Checkpoints.inicializar(zonas: { Zona }): ()
    if inicializado then
        return
    end

    assert(#zonas > 0, "É necessário inicializar pelo menos um checkpoint")

    for indice, zona in zonas do
        local ponto = configurarZona(zona)
        if indice == 1 then
            pontoInicial = ponto
        end
    end

    inicializado = true
    Players.PlayerAdded:Connect(conectarJogador)
    Players.PlayerRemoving:Connect(function(jogador)
        pontosPorJogador[jogador.UserId] = nil
    end)

    for _, jogador in Players:GetPlayers() do
        conectarJogador(jogador)
    end
end

function Checkpoints.obter(jogador: Player): CFrame?
    local ponto = pontoDoJogador(jogador)
    if ponto == nil then
        return nil
    end

    return cframeDoPersonagem(ponto, jogador.Character)
end

return Checkpoints
