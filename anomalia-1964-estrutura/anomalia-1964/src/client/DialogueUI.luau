--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local dialogueDataModule = sharedFolder:WaitForChild("DialogueData") :: ModuleScript
local Config = require(configModule)
local DialogueData = require(dialogueDataModule)

type Fala = DialogueData.Fala

local DialogueUI = {}
local painel: Frame? = nil
local nomeFaxineira: TextLabel? = nil
local textoFala: TextLabel? = nil
local escolhas: Frame? = nil
local contadorDigitacao = 0
local inicializado = false

local function criarInterface(): ()
    local jogador = Players.LocalPlayer
    if jogador == nil then
        return
    end

    local playerGui = jogador:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "DialogoDaFaxineira"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local caixa = Instance.new("Frame")
    caixa.Name = "Caixa"
    caixa.AnchorPoint = Vector2.new(0.5, 1)
    caixa.Position = UDim2.new(0.5, 0, 1, -24)
    caixa.Size = UDim2.fromOffset(Config.UI.DialoguePanelWidth, Config.UI.DialoguePanelHeight)
    caixa.BackgroundColor3 = Color3.fromRGB(28, 29, 32)
    caixa.BackgroundTransparency = 0.06
    caixa.BorderSizePixel = 0
    caixa.Visible = false
    caixa.Parent = gui
    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 10)
    canto.Parent = caixa

    local nome = Instance.new("TextLabel")
    nome.Name = "Nome"
    nome.Position = UDim2.fromOffset(18, 12)
    nome.Size = UDim2.new(1, -36, 0, 24)
    nome.BackgroundTransparency = 1
    nome.Font = Enum.Font.GothamBold
    nome.TextColor3 = Color3.fromRGB(232, 196, 130)
    nome.TextSize = 16
    nome.TextXAlignment = Enum.TextXAlignment.Left
    nome.Parent = caixa

    local texto = Instance.new("TextLabel")
    texto.Name = "Fala"
    texto.Position = UDim2.fromOffset(18, 42)
    texto.Size = UDim2.new(1, -36, 1, -Config.UI.DialogueChoiceHeight - 72)
    texto.BackgroundTransparency = 1
    texto.Font = Enum.Font.Gotham
    texto.TextColor3 = Color3.fromRGB(238, 238, 238)
    texto.TextSize = 15
    texto.TextWrapped = true
    texto.TextXAlignment = Enum.TextXAlignment.Left
    texto.TextYAlignment = Enum.TextYAlignment.Top
    texto.Parent = caixa

    local botoes = Instance.new("Frame")
    botoes.Name = "Escolhas"
    botoes.Position = UDim2.new(0, 18, 1, -Config.UI.DialogueChoiceHeight - 12)
    botoes.Size = UDim2.new(1, -36, 0, Config.UI.DialogueChoiceHeight)
    botoes.BackgroundTransparency = 1
    botoes.Parent = caixa
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 8)
    layout.Parent = botoes

    painel = caixa
    nomeFaxineira = nome
    textoFala = texto
    escolhas = botoes
end

function DialogueUI.fechar(): ()
    contadorDigitacao += 1
    local caixa = painel
    local botoes = escolhas
    if caixa ~= nil then
        caixa.Visible = false
    end
    if botoes ~= nil then
        for _, filho in botoes:GetChildren() do
            if filho:IsA("TextButton") then
                filho:Destroy()
            end
        end
    end
end

local function criarEscolhas(fala: Fala): ()
    local botoes = escolhas
    if botoes == nil then
        return
    end

    for _, filho in botoes:GetChildren() do
        if filho:IsA("TextButton") then
            filho:Destroy()
        end
    end

    local quantidade = math.max(#fala.Escolhas, 1)
    for ordem, escolha in fala.Escolhas do
        local botao = Instance.new("TextButton")
        botao.Name = `Escolha{ordem}`
        botao.LayoutOrder = ordem
        botao.Size = UDim2.new(1 / quantidade, -8, 1, 0)
        botao.BackgroundColor3 = Color3.fromRGB(74, 79, 83)
        botao.BorderSizePixel = 0
        botao.Font = Enum.Font.GothamMedium
        botao.Text = escolha
        botao.TextColor3 = Color3.fromRGB(255, 255, 255)
        botao.TextSize = 13
        botao.TextWrapped = true
        botao.Parent = botoes
        local canto = Instance.new("UICorner")
        canto.CornerRadius = UDim.new(0, 5)
        canto.Parent = botao
        botao.Activated:Connect(DialogueUI.fechar)
    end

    if #fala.Escolhas == 0 then
        local botaoFechar = Instance.new("TextButton")
        botaoFechar.Name = "Fechar"
        botaoFechar.Size = UDim2.new(0.5, -8, 1, 0)
        botaoFechar.BackgroundColor3 = Color3.fromRGB(74, 79, 83)
        botaoFechar.BorderSizePixel = 0
        botaoFechar.Font = Enum.Font.GothamMedium
        botaoFechar.Text = "Fechar"
        botaoFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
        botaoFechar.TextSize = 13
        botaoFechar.Parent = botoes
        botaoFechar.Activated:Connect(DialogueUI.fechar)
    end
end

function DialogueUI.exibir(fala: Fala): ()
    local caixa = painel
    local nome = nomeFaxineira
    local texto = textoFala
    if caixa == nil or nome == nil or texto == nil then
        return
    end

    contadorDigitacao += 1
    local token = contadorDigitacao
    caixa.Visible = true
    nome.Text = fala.Nome
    texto.Text = ""
    criarEscolhas(fala)

    task.spawn(function()
        for _, ultimoIndice in utf8.graphemes(fala.Texto) do
            if token ~= contadorDigitacao or not caixa.Visible then
                return
            end

            texto.Text = string.sub(fala.Texto, 1, ultimoIndice)
            task.wait(Config.UI.DialogueTypingDelay)
        end
    end)
end

function DialogueUI.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    criarInterface()

    local remotesFolder = ReplicatedStorage:WaitForChild("Remotos")
    local remoto = remotesFolder:WaitForChild("DialogoAtualizado")
    assert(remoto:IsA("RemoteEvent"), "DialogoAtualizado precisa ser um RemoteEvent")
    remoto.OnClientEvent:Connect(function(valor: unknown)
        if typeof(valor) ~= "table" then
            return
        end
        local dados = valor :: { [string]: unknown }
        if typeof(dados.Nome) ~= "string" or typeof(dados.Texto) ~= "string" or typeof(dados.Escolhas) ~= "table" then
            return
        end

        local fala: Fala = {
            Nome = dados.Nome,
            Texto = dados.Texto,
            Escolhas = {},
        }
        for _, escolha in dados.Escolhas do
            if typeof(escolha) == "string" then
                table.insert(fala.Escolhas, escolha)
            end
        end
        DialogueUI.exibir(fala)
    end)
end

return DialogueUI
