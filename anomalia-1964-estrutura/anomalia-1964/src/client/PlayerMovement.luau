--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes") :: ModuleScript)
local jogador = Players.LocalPlayer
local remotoSprint = Remotes.obter("SolicitarSprint")
local PlayerMovement = {}

local lanternaLigada = false
local sprintAtivo = false
local conexaoPersonagem: RBXScriptConnection? = nil
local barraEstamina: Frame? = nil
local luz: SpotLight? = nil

local function atualizarLanterna(): ()
    if not lanternaLigada then
        if luz ~= nil then
            luz:Destroy()
            luz = nil
        end
        return
    end

    local personagem = jogador.Character
    local cabeca = if personagem ~= nil then personagem:FindFirstChild("Head") else nil
    if cabeca == nil or not cabeca:IsA("BasePart") then
        return
    end
    if luz ~= nil and luz.Parent == cabeca then
        return
    end
    if luz ~= nil then
        luz:Destroy()
    end

    local novaLuz = Instance.new("SpotLight")
    novaLuz.Name = "LanternaJogador"
    novaLuz.Angle = Config.Movement.FlashlightAngle
    novaLuz.Brightness = Config.Movement.FlashlightBrightness
    novaLuz.Range = Config.Movement.FlashlightRange
    novaLuz.Shadows = true
    novaLuz.Parent = cabeca
    luz = novaLuz
end

local function atualizarBarra(): ()
    if barraEstamina == nil then
        return
    end
    local estamina = jogador:GetAttribute("Estamina")
    local proporcao = if typeof(estamina) == "number"
        then math.clamp(estamina / Config.Movement.SprintMaxStamina, 0, 1)
        else 1
    barraEstamina.Size = UDim2.fromScale(proporcao, 1)
end

function PlayerMovement.alternarLanterna(): ()
    lanternaLigada = not lanternaLigada
    atualizarLanterna()
end

function PlayerMovement.sprintar(ativo: boolean): ()
    if sprintAtivo == ativo then
        return
    end
    sprintAtivo = ativo
    remotoSprint:FireServer(ativo)
end

local function criarInterface(): ()
    local playerGui = jogador:WaitForChild("PlayerGui")
    local existente = playerGui:FindFirstChild("EstaminaUI")
    if existente ~= nil and existente:IsA("ScreenGui") then
        barraEstamina = existente:FindFirstChild("Barra", true) :: Frame?
        return
    end

    local novaGui = Instance.new("ScreenGui")
    novaGui.Name = "EstaminaUI"
    novaGui.ResetOnSpawn = false
    local fundo = Instance.new("Frame")
    fundo.Name = "Fundo"
    fundo.AnchorPoint = Vector2.new(0.5, 1)
    fundo.Position = UDim2.new(0.5, 0, 1, -26)
    fundo.Size = UDim2.fromOffset(220, 14)
    fundo.BackgroundColor3 = Color3.fromRGB(27, 29, 31)
    fundo.BorderSizePixel = 0
    fundo.Parent = novaGui
    local barra = Instance.new("Frame")
    barra.Name = "Barra"
    barra.Size = UDim2.fromScale(1, 1)
    barra.BackgroundColor3 = Color3.fromRGB(202, 173, 86)
    barra.BorderSizePixel = 0
    barra.Parent = fundo
    novaGui.Parent = playerGui
    barraEstamina = barra
end

function PlayerMovement.inicializar(): ()
    criarInterface()
    if conexaoPersonagem ~= nil then
        conexaoPersonagem:Disconnect()
    end
    conexaoPersonagem = jogador.CharacterAdded:Connect(function()
        task.wait()
        atualizarLanterna()
        PlayerMovement.sprintar(false)
    end)
    UserInputService.InputBegan:Connect(function(entrada, processado)
        if processado then
            return
        end
        if entrada.KeyCode == Config.Movement.FlashlightKey then
            PlayerMovement.alternarLanterna()
        elseif entrada.KeyCode == Config.Movement.SprintKey then
            PlayerMovement.sprintar(true)
        end
    end)
    UserInputService.InputEnded:Connect(function(entrada)
        if entrada.KeyCode == Config.Movement.SprintKey then
            PlayerMovement.sprintar(false)
        end
    end)
    jogador:GetAttributeChangedSignal("Estamina"):Connect(atualizarBarra)
    atualizarBarra()
    if jogador.Character ~= nil then
        atualizarLanterna()
    end
end

return PlayerMovement
