--!strict

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local config = Config.ZoneAtmosphere
local player = Players.LocalPlayer
local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    AmbientReverb = SoundService.AmbientReverb,
}

local ZoneAtmosphere = {}
local ambientSound: Sound? = nil
local musicSound: Sound? = nil
local currentZone: string? = nil
local running = false
local generation = 0

local function criarSom(nome: string, somId: string, volume: number, velocidade: number): Sound
    local som = Instance.new("Sound")
    som.Name = nome
    som.SoundId = somId
    som.Volume = 0
    som.Looped = true
    som.PlaybackSpeed = velocidade
    som.Parent = SoundService
    som:Play()
    TweenService:Create(som, TweenInfo.new(config.TransitionDuration), { Volume = volume }):Play()
    return som
end

local function atualizarSom(som: Sound?, id: string, volume: number, velocidade: number, nome: string): Sound
    if som == nil or som.Parent == nil then
        return criarSom(nome, id, volume, velocidade)
    end

    if som.SoundId ~= id then
        local tween = TweenService:Create(som, TweenInfo.new(config.TransitionDuration), { Volume = 0 })
        tween:Play()
        tween.Completed:Once(function()
            if som.Parent ~= nil then
                som.SoundId = id
                som.PlaybackSpeed = velocidade
                som:Play()
                TweenService:Create(som, TweenInfo.new(config.TransitionDuration), { Volume = volume }):Play()
            end
        end)
    else
        som.PlaybackSpeed = velocidade
        TweenService:Create(som, TweenInfo.new(config.TransitionDuration), { Volume = volume }):Play()
    end

    return som
end

function ZoneAtmosphere.aplicar(zona: string)
    local definicao = config.Zonas[zona]
    if definicao == nil or currentZone == zona then
        return
    end

    currentZone = zona
    local transicao = TweenInfo.new(config.TransitionDuration)
    TweenService:Create(Lighting, transicao, {
        Ambient = definicao.Ambient,
        OutdoorAmbient = definicao.OutdoorAmbient,
        FogColor = definicao.FogColor,
        FogStart = definicao.FogStart,
        FogEnd = definicao.FogEnd,
        Brightness = definicao.Brightness,
        ClockTime = definicao.ClockTime,
    }):Play()
    SoundService.AmbientReverb = definicao.Reverb
    ambientSound = atualizarSom(ambientSound, definicao.AmbientSoundId, definicao.AmbientVolume, 1, "AmbienteZona")
    musicSound =
        atualizarSom(musicSound, config.MusicSoundId, definicao.MusicVolume, definicao.MusicPlaybackSpeed, "MusicaZona")
end

local function localizarZona(): string?
    local personagem = player.Character
    local raiz = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
    local mapa = workspace:FindFirstChild("Labirinto")
    if raiz == nil or not raiz:IsA("BasePart") or mapa == nil then
        return nil
    end

    local cellSize = Config.Maze.CellSize
    local largura = Config.Maze.Columns * cellSize
    local profundidade = Config.Maze.Rows * cellSize
    local coluna = math.floor((raiz.Position.X + largura / 2) / cellSize) + 1
    local linha = math.floor((raiz.Position.Z + profundidade / 2) / cellSize) + 1

    for _, zona in mapa:GetChildren() do
        if zona:IsA("Folder") then
            local linhaInicial = zona:GetAttribute("LinhaInicial")
            local linhaFinal = zona:GetAttribute("LinhaFinal")
            local colunaInicial = zona:GetAttribute("ColunaInicial")
            local colunaFinal = zona:GetAttribute("ColunaFinal")
            if
                typeof(linhaInicial) == "number"
                and typeof(linhaFinal) == "number"
                and typeof(colunaInicial) == "number"
                and typeof(colunaFinal) == "number"
                and linha >= linhaInicial
                and linha <= linhaFinal
                and coluna >= colunaInicial
                and coluna <= colunaFinal
            then
                return zona.Name
            end
        end
    end

    return nil
end

function ZoneAtmosphere.limpar()
    running = false
    generation += 1
    currentZone = nil
    for _, som in { ambientSound, musicSound } do
        if som ~= nil then
            som:Stop()
            som:Destroy()
        end
    end
    ambientSound = nil
    musicSound = nil
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.FogColor = originalLighting.FogColor
    Lighting.FogStart = originalLighting.FogStart
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    SoundService.AmbientReverb = originalLighting.AmbientReverb
end

function ZoneAtmosphere.inicializar()
    if running then
        return
    end
    running = true
    generation += 1
    local minhaGeracao = generation
    task.spawn(function()
        while running and generation == minhaGeracao do
            local zona = localizarZona()
            if zona ~= nil then
                ZoneAtmosphere.aplicar(zona)
            end
            task.wait(config.CheckInterval)
        end
    end)
end

return ZoneAtmosphere
