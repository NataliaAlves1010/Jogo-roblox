--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local configModule = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local Vent = {}

type EstadoDuto = {
    Entrada: BasePart,
    Saida: BasePart,
    PromptEntrada: ProximityPrompt,
    PromptSaida: ProximityPrompt,
}

type EstadoJogador = {
    Duto: Model,
    Personagem: Model,
    Humanoide: Humanoid,
    WalkSpeed: number,
    HipHeight: number,
    JumpPower: number,
    JumpHeight: number,
    JumpingEnabled: boolean,
    ConexaoPersonagem: RBXScriptConnection?,
}

local dutos: { [Model]: EstadoDuto } = {}
local jogadoresNoDuto: { [Player]: EstadoJogador } = {}

local function criarPrompt(parte: BasePart, nome: string, acao: string): ProximityPrompt
    local existente = parte:FindFirstChild(nome)
    if existente ~= nil then
        assert(existente:IsA("ProximityPrompt"), `O objeto {nome} precisa ser um ProximityPrompt`)
        return existente
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = nome
    prompt.ActionText = acao
    prompt.ObjectText = "Duto de ventilação"
    prompt.RequiresLineOfSight = false
    prompt.Parent = parte
    return prompt
end

local function jogadorNoAlcance(jogador: Player, parte: BasePart, prompt: ProximityPrompt): boolean
    local personagem = jogador.Character
    if personagem == nil then
        return false
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if humanoide == nil or humanoide.Health <= 0 or raiz == nil or not raiz:IsA("BasePart") then
        return false
    end

    return (raiz.Position - parte.Position).Magnitude <= prompt.MaxActivationDistance
end

local function restaurar(jogador: Player, estado: EstadoJogador): ()
    if jogadoresNoDuto[jogador] ~= estado then
        return
    end
    if estado.ConexaoPersonagem ~= nil then
        estado.ConexaoPersonagem:Disconnect()
    end

    if estado.Humanoide.Parent ~= nil then
        estado.Humanoide.WalkSpeed = estado.WalkSpeed
        estado.Humanoide.HipHeight = estado.HipHeight
        estado.Humanoide.JumpPower = estado.JumpPower
        estado.Humanoide.JumpHeight = estado.JumpHeight
        estado.Humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, estado.JumpingEnabled)
        estado.Humanoide:SetAttribute("AgachadoNoDuto", false)
    end
    if estado.Personagem.Parent ~= nil then
        estado.Personagem:SetAttribute("DentroDoDuto", false)
    end
    jogador:SetAttribute("DentroDoDuto", false)
    jogadoresNoDuto[jogador] = nil
end

function Vent.entrar(jogador: Player, duto: Model): boolean
    local estadoDuto = dutos[duto]
    if estadoDuto == nil or jogadoresNoDuto[jogador] ~= nil or jogador.Parent ~= Players then
        return false
    end
    if not jogadorNoAlcance(jogador, estadoDuto.Entrada, estadoDuto.PromptEntrada) then
        return false
    end

    local personagem = jogador.Character
    local humanoide = if personagem ~= nil then personagem:FindFirstChildOfClass("Humanoid") else nil
    if personagem == nil or humanoide == nil or humanoide.Health <= 0 then
        return false
    end

    local estado: EstadoJogador = {
        Duto = duto,
        Personagem = personagem,
        Humanoide = humanoide,
        WalkSpeed = humanoide.WalkSpeed,
        HipHeight = humanoide.HipHeight,
        JumpPower = humanoide.JumpPower,
        JumpHeight = humanoide.JumpHeight,
        JumpingEnabled = humanoide:GetStateEnabled(Enum.HumanoidStateType.Jumping),
        ConexaoPersonagem = nil,
    }
    jogadoresNoDuto[jogador] = estado
    estado.ConexaoPersonagem = jogador.CharacterRemoving:Connect(function(personagemRemovido: Model)
        if personagemRemovido == personagem then
            restaurar(jogador, estado)
        end
    end)
    jogador:SetAttribute("DentroDoDuto", true)
    personagem:SetAttribute("DentroDoDuto", true)
    humanoide:SetAttribute("AgachadoNoDuto", true)
    humanoide.WalkSpeed = Config.Movement.VentWalkSpeed
    humanoide.HipHeight = math.max(0, estado.HipHeight - Config.Movement.VentHipHeightReduction)
    humanoide.JumpPower = 0
    humanoide.JumpHeight = 0
    humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    return true
end

function Vent.sair(jogador: Player, duto: Model): ()
    local estadoJogador = jogadoresNoDuto[jogador]
    local estadoDuto = dutos[duto]
    if
        estadoJogador == nil
        or estadoJogador.Duto ~= duto
        or estadoDuto == nil
        or not jogadorNoAlcance(jogador, estadoDuto.Saida, estadoDuto.PromptSaida)
    then
        return
    end

    restaurar(jogador, estadoJogador)
end

function Vent.configurar(duto: Model): ()
    assert(dutos[duto] == nil, "O duto já está configurado")
    duto:SetAttribute("TipoObstaculo", "Duto")

    local entrada = duto:FindFirstChild("Entrada", true)
    local saida = duto:FindFirstChild("Saida", true)
    assert(entrada ~= nil and entrada:IsA("BasePart"), "O duto precisa conter a peça Entrada")
    assert(saida ~= nil and saida:IsA("BasePart"), "O duto precisa conter a peça Saida")

    local estadoDuto: EstadoDuto = {
        Entrada = entrada,
        Saida = saida,
        PromptEntrada = criarPrompt(entrada, "PromptEntradaDuto", "Entrar agachado"),
        PromptSaida = criarPrompt(saida, "PromptSaidaDuto", "Sair do duto"),
    }
    dutos[duto] = estadoDuto
    estadoDuto.PromptEntrada.Triggered:Connect(function(jogador: Player)
        Vent.entrar(jogador, duto)
    end)
    estadoDuto.PromptSaida.Triggered:Connect(function(jogador: Player)
        Vent.sair(jogador, duto)
    end)

    duto.Destroying:Connect(function()
        for jogador, estadoJogador in jogadoresNoDuto do
            if estadoJogador.Duto == duto then
                restaurar(jogador, estadoJogador)
            end
        end
        dutos[duto] = nil
    end)
end

Players.PlayerRemoving:Connect(function(jogador: Player)
    local estado = jogadoresNoDuto[jogador]
    if estado ~= nil then
        restaurar(jogador, estado)
    end
end)

return Vent
