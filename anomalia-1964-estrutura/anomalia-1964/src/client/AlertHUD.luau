--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local AlertHUD = {}

type EstadoAlerta = "calmo" | "suspeito" | "perseguição"

local player = Players.LocalPlayer
local estadoAtual: EstadoAlerta = "calmo"
local barra: Frame? = nil
local textoEstado: TextLabel? = nil
local guardaAtivo: Model? = nil
local conexoesGuardas: { [Model]: RBXScriptConnection } = {}
local inicializado = false

local function atualizarInterface(): ()
    local preenchimento = barra
    local estadoLabel = textoEstado
    if preenchimento == nil or estadoLabel == nil then
        return
    end

    if estadoAtual == "calmo" then
        preenchimento.Size = UDim2.fromScale(0.2, 1)
        preenchimento.BackgroundColor3 = Color3.fromRGB(76, 175, 105)
        estadoLabel.Text = "CALMO"
        estadoLabel.TextColor3 = preenchimento.BackgroundColor3
    elseif estadoAtual == "suspeito" then
        preenchimento.Size = UDim2.fromScale(0.55, 1)
        preenchimento.BackgroundColor3 = Color3.fromRGB(238, 177, 55)
        estadoLabel.Text = "SUSPEITO"
        estadoLabel.TextColor3 = preenchimento.BackgroundColor3
    else
        preenchimento.Size = UDim2.fromScale(1, 1)
        preenchimento.BackgroundColor3 = Color3.fromRGB(207, 61, 56)
        estadoLabel.Text = "PERSEGUIÇÃO"
        estadoLabel.TextColor3 = preenchimento.BackgroundColor3
    end
end

function AlertHUD.definirEstado(estado: "calmo" | "suspeito" | "perseguição"): ()
    estadoAtual = estado
    atualizarInterface()
end

local function converterEstado(estadoServidor: any): EstadoAlerta
    if estadoServidor == "Perseguição" then
        return "perseguição"
    elseif estadoServidor == "Suspeito" or estadoServidor == "Busca" then
        return "suspeito"
    end

    return "calmo"
end

local function conectarGuarda(modelo: Instance): ()
    if not modelo:IsA("Model") or modelo.Name ~= "Guarda" or modelo:FindFirstChildOfClass("Humanoid") == nil then
        return
    end

    if conexoesGuardas[modelo] ~= nil then
        return
    end

    local guarda = modelo
    conexoesGuardas[guarda] = guarda:GetAttributeChangedSignal("EstadoGuarda"):Connect(function()
        if guardaAtivo == guarda then
            AlertHUD.definirEstado(converterEstado(guarda:GetAttribute("EstadoGuarda")))
        end
    end)

    if guardaAtivo == nil then
        guardaAtivo = guarda
        AlertHUD.definirEstado(converterEstado(guarda:GetAttribute("EstadoGuarda")))
    end
end

local function desconectarGuarda(modelo: Instance): ()
    if not modelo:IsA("Model") then
        return
    end

    local conexao = conexoesGuardas[modelo]
    if conexao == nil then
        return
    end

    conexao:Disconnect()
    conexoesGuardas[modelo] = nil
    if guardaAtivo ~= modelo then
        return
    end

    guardaAtivo = nil
    AlertHUD.definirEstado("calmo")
    for outroGuarda in conexoesGuardas do
        if outroGuarda.Parent ~= nil then
            guardaAtivo = outroGuarda
            AlertHUD.definirEstado(converterEstado(outroGuarda:GetAttribute("EstadoGuarda")))
            break
        end
    end
end

local function criarInterface(): ()
    local jogador = player
    if jogador == nil then
        return
    end

    local playerGui = jogador:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "AlertaDoGuarda"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = playerGui

    local painel = Instance.new("Frame")
    painel.Name = "Painel"
    painel.AnchorPoint = Vector2.new(0.5, 0)
    painel.Position = UDim2.new(0.5, 0, 0, 18)
    painel.Size = UDim2.fromOffset(300, 66)
    painel.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
    painel.BackgroundTransparency = 0.12
    painel.BorderSizePixel = 0
    painel.Parent = gui

    local cantoPainel = Instance.new("UICorner")
    cantoPainel.CornerRadius = UDim.new(0, 8)
    cantoPainel.Parent = painel

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(14, 7)
    titulo.Size = UDim2.new(1, -28, 0, 18)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamMedium
    titulo.Text = "ALERTA DO GUARDA"
    titulo.TextColor3 = Color3.fromRGB(235, 235, 235)
    titulo.TextSize = 12
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = painel

    local fundoBarra = Instance.new("Frame")
    fundoBarra.Name = "FundoBarra"
    fundoBarra.Position = UDim2.fromOffset(14, 31)
    fundoBarra.Size = UDim2.new(1, -112, 0, 18)
    fundoBarra.BackgroundColor3 = Color3.fromRGB(57, 59, 65)
    fundoBarra.BorderSizePixel = 0
    fundoBarra.ClipsDescendants = true
    fundoBarra.Parent = painel

    local cantoFundo = Instance.new("UICorner")
    cantoFundo.CornerRadius = UDim.new(0, 5)
    cantoFundo.Parent = fundoBarra

    local preenchimento = Instance.new("Frame")
    preenchimento.Name = "Preenchimento"
    preenchimento.Size = UDim2.fromScale(0.2, 1)
    preenchimento.BackgroundColor3 = Color3.fromRGB(76, 175, 105)
    preenchimento.BorderSizePixel = 0
    preenchimento.Parent = fundoBarra
    barra = preenchimento

    local texto = Instance.new("TextLabel")
    texto.Name = "Estado"
    texto.Position = UDim2.new(1, -91, 0, 30)
    texto.Size = UDim2.fromOffset(77, 20)
    texto.BackgroundTransparency = 1
    texto.Font = Enum.Font.GothamBold
    texto.Text = "CALMO"
    texto.TextColor3 = Color3.fromRGB(76, 175, 105)
    texto.TextSize = 11
    texto.TextXAlignment = Enum.TextXAlignment.Right
    texto.Parent = painel
    textoEstado = texto

    atualizarInterface()
end

function AlertHUD.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    criarInterface()

    for _, objeto in Workspace:GetDescendants() do
        conectarGuarda(objeto)
    end
    Workspace.DescendantAdded:Connect(conectarGuarda)
    Workspace.DescendantRemoving:Connect(desconectarGuarda)
end

return AlertHUD
