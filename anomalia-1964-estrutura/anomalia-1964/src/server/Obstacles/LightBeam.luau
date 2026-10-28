--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local LightBeam = {}

local barreirasPorEmissor: { [BasePart]: BasePart } = {}

local function definirIntervalo(barreira: BasePart, seguro: boolean): ()
    barreira:SetAttribute("IntervaloSeguro", seguro)
    barreira.CanCollide = not seguro
    barreira.Transparency = if seguro then 1 else 0.45
    barreira.Color = if seguro then Color3.fromRGB(40, 255, 100) else Color3.fromRGB(255, 35, 35)
end

function LightBeam.estaSeguro(feixe: Instance): boolean
    return feixe:GetAttribute("IntervaloSeguro") == true
end

function LightBeam.configurar(emissor: BasePart, destino: BasePart): ()
    assert(emissor ~= destino, "O emissor e o destino do feixe precisam ser diferentes")
    assert(barreirasPorEmissor[emissor] == nil, "O emissor já tem um feixe configurado")

    emissor:SetAttribute("TipoObstaculo", "FeixeDeLuz")
    local deslocamento = destino.Position - emissor.Position
    assert(deslocamento.Magnitude > 0, "O destino do feixe precisa estar afastado do emissor")

    local anexoInicial = Instance.new("Attachment")
    anexoInicial.Name = "AnexoFeixeInicial"
    anexoInicial.Parent = emissor

    local anexoFinal = Instance.new("Attachment")
    anexoFinal.Name = "AnexoFeixeFinal"
    anexoFinal.Parent = destino

    local visual = Instance.new("Beam")
    visual.Name = "FeixeVisual"
    visual.Attachment0 = anexoInicial
    visual.Attachment1 = anexoFinal
    visual.FaceCamera = true
    visual.LightEmission = 1
    visual.Width0 = Config.Obstacles.LightBeamWidth
    visual.Width1 = Config.Obstacles.LightBeamWidth
    visual.Parent = emissor

    local barreira = Instance.new("Part")
    barreira.Name = "BarreiraFeixe"
    barreira.Anchored = true
    barreira.CanCollide = true
    barreira.CanTouch = false
    barreira.Material = Enum.Material.Neon
    barreira.Size =
        Vector3.new(Config.Obstacles.LightBeamThickness, Config.Obstacles.LightBeamHeight, deslocamento.Magnitude)
    barreira.CFrame = CFrame.lookAt((emissor.Position + destino.Position) / 2, destino.Position)
    barreira.Parent = emissor
    barreirasPorEmissor[emissor] = barreira
    definirIntervalo(barreira, false)

    barreira.Destroying:Connect(function()
        if barreirasPorEmissor[emissor] == barreira then
            barreirasPorEmissor[emissor] = nil
        end
    end)

    task.spawn(function()
        while barreirasPorEmissor[emissor] == barreira and barreira.Parent ~= nil do
            task.wait(Config.Timing.LightBeamActiveDuration)
            if barreirasPorEmissor[emissor] ~= barreira or barreira.Parent == nil then
                break
            end

            definirIntervalo(barreira, true)
            task.wait(Config.Timing.LightBeamSafeDuration)
            if barreirasPorEmissor[emissor] ~= barreira or barreira.Parent == nil then
                break
            end

            definirIntervalo(barreira, false)
        end
    end)
end

return LightBeam
