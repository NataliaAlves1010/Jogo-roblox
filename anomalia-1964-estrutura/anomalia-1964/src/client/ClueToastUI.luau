--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Config = require(configModule)
local Remotes = require(remotesModule)
local Types = require(typesModule)

type TrechoCarta = Types.TrechoCarta

local ClueToastUI = {}
local inicializado = false
local painel: Frame? = nil
local textoTitulo: TextLabel? = nil
local textoTrecho: TextLabel? = nil
local tweenAtual: Tween? = nil
local geracao = 0

local function criarInterface(): ()
    local jogador = Players.LocalPlayer
    if jogador == nil then
        return
    end

    local playerGui = jogador:WaitForChild("PlayerGui")
    local existente = playerGui:FindFirstChild("NotificacaoTrecho")
    if existente ~= nil and existente:IsA("ScreenGui") then
        local painelExistente = existente:FindFirstChild("Painel")
        if painelExistente ~= nil and painelExistente:IsA("Frame") then
            painel = painelExistente
            textoTitulo = painelExistente:FindFirstChild("Titulo") :: TextLabel?
            textoTrecho = painelExistente:FindFirstChild("Trecho") :: TextLabel?
            return
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NotificacaoTrecho"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    local frame = Instance.new("Frame")
    frame.Name = "Painel"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, -Config.UI.ClueToastHeight)
    frame.Size = UDim2.fromOffset(Config.UI.ClueToastWidth, Config.UI.ClueToastHeight)
    frame.BackgroundColor3 = Color3.fromRGB(27, 26, 24)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 8)
    canto.Parent = frame
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(16, 10)
    titulo.Size = UDim2.new(1, -32, 0, 22)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "TRECHO DE CARTA DESCOBERTO"
    titulo.TextColor3 = Color3.fromRGB(229, 194, 111)
    titulo.TextSize = 14
    titulo.TextTransparency = 1
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = frame
    local trecho = Instance.new("TextLabel")
    trecho.Name = "Trecho"
    trecho.Position = UDim2.fromOffset(16, 35)
    trecho.Size = UDim2.new(1, -32, 1, -45)
    trecho.BackgroundTransparency = 1
    trecho.Font = Enum.Font.Garamond
    trecho.TextColor3 = Color3.fromRGB(244, 238, 220)
    trecho.TextSize = 17
    trecho.TextWrapped = true
    trecho.TextTransparency = 1
    trecho.TextXAlignment = Enum.TextXAlignment.Left
    trecho.TextYAlignment = Enum.TextYAlignment.Top
    trecho.Parent = frame
    gui.Parent = playerGui

    painel = frame
    textoTitulo = titulo
    textoTrecho = trecho
end

local function decodificarTrecho(valor: unknown): TrechoCarta?
    if typeof(valor) ~= "table" then
        return nil
    end

    local dados = valor :: { [string]: unknown }
    if typeof(dados.PistaId) ~= "string" or typeof(dados.LetterId) ~= "string" or typeof(dados.Trecho) ~= "string" then
        return nil
    end

    return {
        PistaId = dados.PistaId,
        LetterId = dados.LetterId,
        Trecho = dados.Trecho,
    }
end

function ClueToastUI.exibir(trecho: TrechoCarta): ()
    local frame = painel
    local titulo = textoTitulo
    local texto = textoTrecho
    if frame == nil or titulo == nil or texto == nil then
        return
    end

    geracao += 1
    local minhaGeracao = geracao
    if tweenAtual ~= nil then
        tweenAtual:Cancel()
    end

    titulo.Text = `TRECHO DE CARTA DESCOBERTO • {trecho.LetterId}`
    texto.Text = trecho.Trecho
    frame.Visible = true
    frame.Position = UDim2.new(0.5, 0, 0, -Config.UI.ClueToastHeight)
    frame.BackgroundTransparency = 1
    titulo.TextTransparency = 1
    texto.TextTransparency = 1
    tweenAtual = TweenService:Create(
        frame,
        TweenInfo.new(Config.UI.ClueToastFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0.5, 0, 0, Config.UI.ClueToastTopOffset),
            BackgroundTransparency = 0.1,
        }
    )
    tweenAtual:Play()
    TweenService:Create(titulo, TweenInfo.new(Config.UI.ClueToastFadeDuration), { TextTransparency = 0 }):Play()
    TweenService:Create(texto, TweenInfo.new(Config.UI.ClueToastFadeDuration), { TextTransparency = 0 }):Play()

    task.delay(Config.UI.ClueToastDuration, function()
        if geracao ~= minhaGeracao or frame.Parent == nil then
            return
        end

        tweenAtual = TweenService:Create(
            frame,
            TweenInfo.new(Config.UI.ClueToastFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, 0, 0, -Config.UI.ClueToastHeight),
                BackgroundTransparency = 1,
            }
        )
        tweenAtual:Play()
        TweenService:Create(titulo, TweenInfo.new(Config.UI.ClueToastFadeDuration), { TextTransparency = 1 }):Play()
        TweenService:Create(texto, TweenInfo.new(Config.UI.ClueToastFadeDuration), { TextTransparency = 1 }):Play()
        tweenAtual.Completed:Once(function()
            if geracao == minhaGeracao then
                frame.Visible = false
            end
        end)
    end)
end

function ClueToastUI.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    criarInterface()
    Remotes.obter("TrechoRecebido").OnClientEvent:Connect(function(valor: unknown)
        local trecho = decodificarTrecho(valor)
        if trecho ~= nil then
            ClueToastUI.exibir(trecho)
        end
    end)
end

return ClueToastUI
