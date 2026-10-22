--!strict

local Interact = {}

function Interact.distanciaValida(jogador: Player, alvo: BasePart): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    local prompt = alvo:FindFirstChildOfClass("ProximityPrompt")
    if humanoide == nil or humanoide.Health <= 0 or raiz == nil or not raiz:IsA("BasePart") or prompt == nil then
        return false
    end

    return (raiz.Position - alvo.Position).Magnitude <= prompt.MaxActivationDistance
end

function Interact.criar(alvo: BasePart, texto: string, acao: (Player) -> ()): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = texto
    prompt.ObjectText = alvo.Name
    prompt.Parent = alvo

    prompt.Triggered:Connect(function(jogador: Player)
        if Interact.distanciaValida(jogador, alvo) then
            acao(jogador)
        end
    end)

    return prompt
end

return Interact
