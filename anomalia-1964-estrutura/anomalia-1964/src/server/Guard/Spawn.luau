--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local zonesModule = script.Parent.Parent:WaitForChild("Zones") :: ModuleScript
local Config = require(configModule)
local Zones = require(zonesModule)

local Spawn = {}

function Spawn.criar(zona: Zones.Zona): Model
    local linhaCentral = math.floor((zona.LinhaInicial + zona.LinhaFinal) / 2)
    local colunaCentral = math.floor((zona.ColunaInicial + zona.ColunaFinal) / 2)
    local nomePiso = string.format("Piso_%d_%d", linhaCentral, colunaCentral)
    local piso = zona.Pasta:FindFirstChild(nomePiso)
    assert(piso ~= nil and piso:IsA("BasePart"), "A zona precisa ter um piso central válido")

    local descricao = Instance.new("HumanoidDescription")
    local guarda = Players:CreateHumanoidModelFromDescriptionAsync(descricao, Enum.HumanoidRigType.R15)
    descricao:Destroy()
    guarda.Name = "Guarda"
    guarda:SetAttribute("Zona", zona.Nome)

    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    assert(humanoide ~= nil, "O modelo do guarda precisa ter um Humanoid")
    humanoide.DisplayName = "Guarda"
    humanoide.WalkSpeed = Config.Movement.GuardWalkSpeed
    humanoide.AutoRotate = true

    local raiz = guarda:FindFirstChild("HumanoidRootPart")
    assert(raiz ~= nil and raiz:IsA("BasePart"), "O modelo do guarda precisa ter uma raiz válida")
    guarda.PrimaryPart = raiz
    local alturaRaiz = humanoide.HipHeight + raiz.Size.Y / 2
    local posicaoInicial = piso.Position + Vector3.new(0, piso.Size.Y / 2 + alturaRaiz, 0)
    guarda:PivotTo(CFrame.new(posicaoInicial))
    guarda.Parent = zona.Pasta

    return guarda
end

return Spawn
