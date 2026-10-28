--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local FallingFloor = {}

type EstadoPiso = {
    CFrameOriginal: CFrame,
    AnchoredOriginal: boolean,
    CanCollideOriginal: boolean,
    TransparencyOriginal: number,
    Ativo: boolean,
    Versao: number,
    Conexao: RBXScriptConnection?,
}

local estados: { [BasePart]: EstadoPiso } = {}

function FallingFloor.reiniciar(piso: BasePart): ()
    local estado = estados[piso]
    if estado == nil then
        return
    end

    estado.Versao += 1
    estado.Ativo = false
    if piso.Parent == nil then
        return
    end

    piso.Anchored = true
    piso.CFrame = estado.CFrameOriginal
    piso.Transparency = estado.TransparencyOriginal
    piso.CanCollide = estado.CanCollideOriginal
    piso.Anchored = estado.AnchoredOriginal
end

function FallingFloor.ativar(piso: BasePart): ()
    local estado = estados[piso]
    if estado == nil or estado.Ativo then
        return
    end

    estado.Ativo = true
    estado.Versao += 1
    local versao = estado.Versao
    task.delay(Config.Timing.FallingFloorDelay, function()
        if estados[piso] ~= estado or estado.Versao ~= versao or not estado.Ativo or piso.Parent == nil then
            return
        end

        piso.CanCollide = false
        piso.Anchored = false
        task.delay(Config.Timing.FallingFloorDuration, function()
            if estados[piso] == estado and estado.Versao == versao and estado.Ativo then
                FallingFloor.reiniciar(piso)
            end
        end)
    end)
end

function FallingFloor.configurar(piso: BasePart): ()
    assert(estados[piso] == nil, "O piso já está configurado")
    piso:SetAttribute("TipoObstaculo", "PisoInstavel")

    local estado: EstadoPiso = {
        CFrameOriginal = piso.CFrame,
        AnchoredOriginal = piso.Anchored,
        CanCollideOriginal = piso.CanCollide,
        TransparencyOriginal = piso.Transparency,
        Ativo = false,
        Versao = 0,
        Conexao = nil,
    }
    estados[piso] = estado
    estado.Conexao = piso.Touched:Connect(function(parte)
        local personagem = parte:FindFirstAncestorOfClass("Model")
        if personagem == nil then
            return
        end

        local jogador = Players:GetPlayerFromCharacter(personagem)
        if jogador ~= nil then
            FallingFloor.ativar(piso)
        end
    end)

    piso.Destroying:Connect(function()
        if estado.Conexao ~= nil then
            estado.Conexao:Disconnect()
        end
        estados[piso] = nil
    end)
end

return FallingFloor
