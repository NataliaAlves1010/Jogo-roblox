--!strict

local Lever = {}

local portoesPorAlavanca: { [BasePart]: BasePart } = {}

local function jogadorNoAlcance(jogador: Player, alavanca: BasePart): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    local prompt = alavanca:FindFirstChildOfClass("ProximityPrompt")
    if humanoide == nil or humanoide.Health <= 0 or raiz == nil or not raiz:IsA("BasePart") or prompt == nil then
        return false
    end

    return (raiz.Position - alavanca.Position).Magnitude <= prompt.MaxActivationDistance
end

function Lever.ativar(alavanca: BasePart, jogador: Player): boolean
    local portao = portoesPorAlavanca[alavanca]
    if portao == nil or alavanca:GetAttribute("Ativada") == true or not jogadorNoAlcance(jogador, alavanca) then
        return false
    end

    alavanca:SetAttribute("Ativada", true)
    portao:SetAttribute("AbertoPelaAlavanca", true)
    portao.CanCollide = false
    portao.Transparency = 1

    local prompt = alavanca:FindFirstChildOfClass("ProximityPrompt")
    if prompt ~= nil then
        prompt.Enabled = false
    end

    return true
end

function Lever.configurar(alavanca: BasePart, portao: BasePart): ()
    assert(alavanca ~= portao, "A alavanca e o portão precisam ser objetos diferentes")
    assert(portoesPorAlavanca[alavanca] == nil, "A alavanca já está configurada")

    portoesPorAlavanca[alavanca] = portao
    alavanca:SetAttribute("Ativada", false)
    portao:SetAttribute("AbertoPelaAlavanca", false)

    local prompt = alavanca:FindFirstChildOfClass("ProximityPrompt")
    if prompt == nil then
        prompt = Instance.new("ProximityPrompt")
        prompt.Parent = alavanca
    end

    prompt.ActionText = "Acionar"
    prompt.ObjectText = "Alavanca"
    prompt.Triggered:Connect(function(jogador: Player)
        Lever.ativar(alavanca, jogador)
    end)
end

return Lever
