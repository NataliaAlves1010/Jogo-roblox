--!strict

local LockedDoor = {}

local function jogadorNoAlcance(jogador: Player, porta: BasePart, prompt: ProximityPrompt): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if humanoide == nil or humanoide.Health <= 0 or raiz == nil or not raiz:IsA("BasePart") then
        return false
    end

    return (raiz.Position - porta.Position).Magnitude <= prompt.MaxActivationDistance
end

function LockedDoor.abrir(porta: BasePart): ()
    if porta:GetAttribute("Aberta") == true then
        return
    end

    porta:SetAttribute("Aberta", true)
    porta.CanCollide = false
    porta.Transparency = 1

    local prompt = porta:FindFirstChildOfClass("ProximityPrompt")
    if prompt ~= nil then
        prompt.Enabled = false
    end
end

function LockedDoor.configurar(porta: BasePart, corChave: string, validarChave: (Player, string) -> boolean): ()
    assert(corChave ~= "", "A cor da chave não pode estar vazia")
    porta:SetAttribute("TipoObstaculo", "PortaTrancada")
    porta:SetAttribute("CorChave", corChave)
    porta:SetAttribute("Aberta", false)

    local prompt = porta:FindFirstChildOfClass("ProximityPrompt")
    if prompt == nil then
        prompt = Instance.new("ProximityPrompt")
        prompt.Parent = porta
    end

    prompt.ActionText = "Destrancar"
    prompt.ObjectText = `Porta {corChave}`
    prompt.Triggered:Connect(function(jogador: Player)
        if not jogadorNoAlcance(jogador, porta, prompt :: ProximityPrompt) then
            return
        end

        if validarChave(jogador, corChave) then
            LockedDoor.abrir(porta)
        end
    end)
end

return LockedDoor
