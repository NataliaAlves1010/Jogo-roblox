--!strict

local Players = game:GetService("Players")

local AlertHUD = require(script.Parent:WaitForChild("AlertHUD") :: ModuleScript)
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI") :: ModuleScript)
local DialogueUI = require(script.Parent:WaitForChild("DialogueUI") :: ModuleScript)
local EndingUI = require(script.Parent:WaitForChild("EndingUI") :: ModuleScript)
local ZoneAtmosphere = require(script.Parent:WaitForChild("ZoneAtmosphere") :: ModuleScript)
local PlayerMovement = require(script.Parent:WaitForChild("PlayerMovement") :: ModuleScript)
local CoverUI = require(script.Parent:WaitForChild("CoverUI") :: ModuleScript)

local jogador = Players.LocalPlayer

local function travarMovimento(): ()
    local personagem = jogador.Character
    if personagem == nil then
        return
    end
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    if humanoide ~= nil then
        humanoide.WalkSpeed = 0
        humanoide.JumpPower = 0
    end
end

local function liberarMovimento(): ()
    local personagem = jogador.Character
    if personagem == nil then
        return
    end
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    if humanoide ~= nil then
        humanoide.WalkSpeed = 16
        humanoide.JumpPower = 50
    end
end

AlertHUD.inicializar()
InventoryUI.inicializar()
DialogueUI.inicializar()
EndingUI.inicializar()
ZoneAtmosphere.inicializar()
PlayerMovement.inicializar()

travarMovimento()
jogador.CharacterAdded:Connect(function()
    if CoverUI.estaAtivo() then
        task.defer(travarMovimento)
    end
end)

CoverUI.montar(function()
    liberarMovimento()
end)
