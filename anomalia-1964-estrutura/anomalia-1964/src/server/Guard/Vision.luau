--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local Vision = {}

function Vision.detectar(guarda: Model, jogador: Player): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end
    if
        jogador:GetAttribute("Escondido") == true
        or personagem:GetAttribute("Escondido") == true
        or jogador:GetAttribute("DentroDoDuto") == true
        or personagem:GetAttribute("DentroDoDuto") == true
    then
        return false
    end

    local humanoideGuarda = guarda:FindFirstChildOfClass("Humanoid")
    local raizGuarda = guarda:FindFirstChild("HumanoidRootPart")
    local humanoideJogador = personagem:FindFirstChildOfClass("Humanoid")
    local raizJogador = personagem:FindFirstChild("HumanoidRootPart")
    if
        humanoideGuarda == nil
        or humanoideGuarda.Health <= 0
        or raizGuarda == nil
        or not raizGuarda:IsA("BasePart")
        or humanoideJogador == nil
        or humanoideJogador.Health <= 0
        or raizJogador == nil
        or not raizJogador:IsA("BasePart")
    then
        return false
    end

    local raiz = raizJogador :: BasePart
    local raizDoGuarda = raizGuarda :: BasePart
    local deslocamento = raiz.Position - raizDoGuarda.Position
    if deslocamento.Magnitude > Config.GuardVision.Range then
        return false
    end

    if Config.GuardVision.FieldOfViewDegrees < 360 then
        local direcaoHorizontal = Vector3.new(deslocamento.X, 0, deslocamento.Z)
        local frente = raizDoGuarda.CFrame.LookVector
        local frenteHorizontal = Vector3.new(frente.X, 0, frente.Z)
        if direcaoHorizontal.Magnitude > 0 and frenteHorizontal.Magnitude > 0 then
            local anguloMetade = math.rad(Config.GuardVision.FieldOfViewDegrees / 2)
            local limiteCone = math.cos(anguloMetade)
            if frenteHorizontal.Unit:Dot(direcaoHorizontal.Unit) < limiteCone then
                return false
            end
        end
    end

    return true
end

return Vision
