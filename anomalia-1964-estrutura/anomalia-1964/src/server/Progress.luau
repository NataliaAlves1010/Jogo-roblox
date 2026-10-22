--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local inventoryModule = script.Parent:WaitForChild("Inventory") :: ModuleScript
local interactModule = script.Parent:WaitForChild("Interact") :: ModuleScript
local obstaclesFolder = script.Parent:WaitForChild("Obstacles")
local lockedDoorModule = obstaclesFolder:WaitForChild("LockedDoor") :: ModuleScript

local Config = require(configModule)
local Inventory = require(inventoryModule)
local Interact = require(interactModule)
local LockedDoor = require(lockedDoorModule)

local Progress = {}
local salasInicializadas: { [Model]: boolean } = {}

function Progress.validarEntrada(jogador: Player): boolean
    if jogador.Parent ~= Players then
        return false
    end

    local configProgresso = Config.Progress
    for _, chave in configProgresso.RequiredKeys do
        if not Inventory.temChave(jogador, chave) then
            return false
        end
    end

    return Inventory.quantidadePistas(jogador) >= configProgresso.MinimumClues
end

function Progress.inicializar(sala: Model): ()
    if salasInicializadas[sala] then
        return
    end

    local porta = sala.PrimaryPart
    assert(porta ~= nil, "A Sala 214 precisa ter a porta final como peça principal")
    assert(porta:GetAttribute("PortaFinal") == true, "A peça principal precisa ser a porta final")

    local prompt = Interact.criar(porta, "Abrir", function(jogador: Player)
        if not Progress.validarEntrada(jogador) then
            return
        end

        LockedDoor.abrir(porta)
    end)
    prompt.ObjectText = "Sala 214"
    prompt.MaxActivationDistance = Config.Progress.InteractionDistance
    porta:SetAttribute("ProgressaoValidadaPeloServidor", true)
    salasInicializadas[sala] = true
end

return Progress
