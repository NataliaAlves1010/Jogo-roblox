--!strict

local AlertHUD = require(script.Parent:WaitForChild("AlertHUD") :: ModuleScript)
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI") :: ModuleScript)
local DialogueUI = require(script.Parent:WaitForChild("DialogueUI") :: ModuleScript)
local EndingUI = require(script.Parent:WaitForChild("EndingUI") :: ModuleScript)

AlertHUD.inicializar()
InventoryUI.inicializar()
DialogueUI.inicializar()
EndingUI.inicializar()
