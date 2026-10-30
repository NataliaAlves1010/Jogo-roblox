--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local Config = require(configModule)
local Remotes = require(remotesModule)

local EndingUI = {}
local guiAtual: ScreenGui? = nil

local function formatarTempo(tempoSegundos: number): string
    local minutos = math.floor(tempoSegundos / 60)
    local segundos = tempoSegundos % 60
    return string.format("Tempo: %02d:%02d", minutos, segundos)
end

function EndingUI.exibir(tempoSegundos: number): ()
    local gui = guiAtual
    if gui == nil then
        return
    end

    local painel = gui:FindFirstChild("Painel")
    local titulo = if painel ~= nil then painel:FindFirstChild("Titulo") else nil
    local tempo = if painel ~= nil then painel:FindFirstChild("Tempo") else nil
    local reiniciar = if painel ~= nil then painel:FindFirstChild("Reiniciar") else nil
    local sair = if painel ~= nil then painel:FindFirstChild("Sair") else nil
    if tempo ~= nil and tempo:IsA("TextLabel") then
        tempo.Text = formatarTempo(tempoSegundos)
    end
    if titulo ~= nil and titulo:IsA("TextLabel") then
        titulo.Text = "Investigação concluída"
    end
    if reiniciar ~= nil and reiniciar:IsA("TextButton") then
        reiniciar.Active = true
        reiniciar.Text = "Jogar novamente"
    end
    if sair ~= nil and sair:IsA("TextButton") then
        sair.Active = true
        sair.Text = "Sair do jogo"
    end
    gui.Enabled = true
end

function EndingUI.inicializar(): ()
    local jogador = Players.LocalPlayer
    local playerGui = jogador:WaitForChild("PlayerGui")
    local guiExistente = playerGui:FindFirstChild("TelaVitoria")
    if guiExistente ~= nil and guiExistente:IsA("ScreenGui") then
        guiAtual = guiExistente
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TelaVitoria"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    guiAtual = gui

    local painel = Instance.new("Frame")
    painel.Name = "Painel"
    painel.AnchorPoint = Vector2.new(0.5, 0.5)
    painel.Position = UDim2.fromScale(0.5, 0.5)
    painel.Size = UDim2.fromOffset(Config.UI.EndingPanelWidth, Config.UI.EndingPanelHeight)
    painel.BackgroundColor3 = Color3.fromRGB(32, 29, 26)
    painel.BorderSizePixel = 0
    painel.Parent = gui

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(20, 20)
    titulo.Size = UDim2.new(1, -40, 0, 56)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.Garamond
    titulo.Text = "Investigação concluída"
    titulo.TextColor3 = Color3.fromRGB(230, 218, 190)
    titulo.TextScaled = true
    titulo.Parent = painel

    local tempo = Instance.new("TextLabel")
    tempo.Name = "Tempo"
    tempo.Position = UDim2.fromOffset(20, 88)
    tempo.Size = UDim2.new(1, -40, 0, 40)
    tempo.BackgroundTransparency = 1
    tempo.Font = Enum.Font.Code
    tempo.Text = "Tempo: 00:00"
    tempo.TextColor3 = Color3.fromRGB(230, 218, 190)
    tempo.TextScaled = true
    tempo.Parent = painel

    local mensagemFinal = Instance.new("TextLabel")
    mensagemFinal.Name = "MensagemFinal"
    mensagemFinal.Position = UDim2.fromOffset(20, Config.UI.EndingMessageTop)
    mensagemFinal.Size = UDim2.new(1, -40, 0, Config.UI.EndingMessageHeight)
    mensagemFinal.BackgroundTransparency = 1
    mensagemFinal.Font = Enum.Font.Garamond
    mensagemFinal.Text = "Os documentos foram reunidos. A memória continua."
    mensagemFinal.TextColor3 = Color3.fromRGB(219, 205, 174)
    mensagemFinal.TextSize = Config.UI.EndingMessageTextSize
    mensagemFinal.TextWrapped = true
    mensagemFinal.Parent = painel

    local reiniciar = Instance.new("TextButton")
    reiniciar.Name = "Reiniciar"
    reiniciar.AnchorPoint = Vector2.new(1, 1)
    reiniciar.Position = UDim2.new(0.5, -Config.UI.EndingButtonGap / 2, 1, -18)
    reiniciar.Size = UDim2.new(
        0.5,
        -(Config.UI.EndingButtonSideInset + Config.UI.EndingButtonGap / 2),
        0,
        Config.UI.EndingButtonHeight
    )
    reiniciar.BackgroundColor3 = Color3.fromRGB(112, 82, 52)
    reiniciar.BorderSizePixel = 0
    reiniciar.Font = Enum.Font.Garamond
    reiniciar.Text = "Jogar novamente"
    reiniciar.TextColor3 = Color3.fromRGB(255, 245, 225)
    reiniciar.TextScaled = true
    reiniciar.Parent = painel
    reiniciar.Activated:Connect(function()
        reiniciar.Active = false
        reiniciar.Text = "Preparando nova partida..."
        gui.Enabled = false
        Remotes.obter("SolicitarReinicio"):FireServer()
    end)

    local sair = Instance.new("TextButton")
    sair.Name = "Sair"
    sair.AnchorPoint = Vector2.new(0, 1)
    sair.Position = UDim2.new(0.5, Config.UI.EndingButtonGap / 2, 1, -18)
    sair.Size = UDim2.new(
        0.5,
        -(Config.UI.EndingButtonSideInset + Config.UI.EndingButtonGap / 2),
        0,
        Config.UI.EndingButtonHeight
    )
    sair.BackgroundColor3 = Color3.fromRGB(82, 55, 50)
    sair.BorderSizePixel = 0
    sair.Font = Enum.Font.Garamond
    sair.Text = "Sair do jogo"
    sair.TextColor3 = Color3.fromRGB(255, 245, 225)
    sair.TextScaled = true
    sair.Parent = painel
    sair.Activated:Connect(function()
        sair.Active = false
        sair.Text = "Saindo do jogo..."
        jogador:Kick("Você encerrou a partida. Obrigado por jogar!")
    end)

    painel.Parent = gui
    gui.Parent = playerGui

    Remotes.obter("VitoriaAtualizada").OnClientEvent:Connect(function(tempoSegundos: number)
        EndingUI.exibir(tempoSegundos)
    end)
end

return EndingUI
