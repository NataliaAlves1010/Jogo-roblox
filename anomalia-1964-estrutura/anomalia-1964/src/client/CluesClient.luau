--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes") :: ModuleScript)
local CluesClient = {}
local inicializado = false

function CluesClient.ocultarPista(pistaId: string): ()
    local mapa = workspace:FindFirstChild("Labirinto")
    if mapa == nil then
        return
    end

    for _, objeto in mapa:GetDescendants() do
        if objeto:IsA("BasePart") and objeto:GetAttribute("PistaId") == pistaId then
            objeto.LocalTransparencyModifier = 1
            objeto.CanCollide = false
            objeto.CanTouch = false
            objeto.CanQuery = false
            for _, filho in objeto:GetChildren() do
                if filho:IsA("ProximityPrompt") then
                    filho.Enabled = false
                end
            end
            return
        end
    end
end

function CluesClient.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    Remotes.obter("PistaColetadaCliente").OnClientEvent:Connect(function(pistaId: unknown)
        if typeof(pistaId) == "string" then
            CluesClient.ocultarPista(pistaId)
        end
    end)
end

return CluesClient
