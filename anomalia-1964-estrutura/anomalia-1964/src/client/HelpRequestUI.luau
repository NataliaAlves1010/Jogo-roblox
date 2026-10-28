--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Config = require(configModule)
local Remotes = require(remotesModule)
local Types = require(typesModule)

type CartaHistorica = Types.CartaHistorica
type ItemCartaHistorica = Types.ItemCartaHistorica

local HelpRequestUI = {}
local guiAtual: ScreenGui? = nil
local listaTrechos: ScrollingFrame? = nil

local function decodificarCarta(valor: unknown): CartaHistorica?
    if typeof(valor) ~= "table" then
        return nil
    end

    local dados = valor :: { [string]: unknown }
    if
        typeof(dados.Total) ~= "number"
        or dados.Total < 0
        or dados.Total > Config.UI.FinalLetterEntryMaxCount
        or dados.Total % 1 ~= 0
    then
        return nil
    end
    if typeof(dados.Trechos) ~= "table" then
        return nil
    end

    local itens: { ItemCartaHistorica } = {}
    for _, valorItem in dados.Trechos do
        if typeof(valorItem) ~= "table" then
            return nil
        end

        local item = valorItem :: { [string]: unknown }
        if
            typeof(item.Id) ~= "string"
            or typeof(item.Zona) ~= "string"
            or typeof(item.Data) ~= "string"
            or typeof(item.Titulo) ~= "string"
            or typeof(item.Trecho) ~= "string"
            or typeof(item.Texto) ~= "string"
            or typeof(item.Fonte) ~= "string"
        then
            return nil
        end

        table.insert(itens, {
            Id = item.Id,
            Zona = item.Zona,
            Data = item.Data,
            Titulo = item.Titulo,
            Trecho = item.Trecho,
            Texto = item.Texto,
            Fonte = item.Fonte,
        })
    end

    if #itens ~= dados.Total then
        return nil
    end

    return { Trechos = itens, Total = dados.Total }
end

local function criarTexto(nome: string, tamanho: number, cor: Color3, fonte: Enum.Font): TextLabel
    local texto = Instance.new("TextLabel")
    texto.Name = nome
    texto.Size = UDim2.fromScale(1, 0)
    texto.AutomaticSize = Enum.AutomaticSize.Y
    texto.BackgroundTransparency = 1
    texto.Font = fonte
    texto.TextColor3 = cor
    texto.TextSize = tamanho
    texto.TextWrapped = true
    texto.TextXAlignment = Enum.TextXAlignment.Left
    texto.TextYAlignment = Enum.TextYAlignment.Top
    return texto
end

local function criarEntrada(item: ItemCartaHistorica): Frame
    local ui = Config.UI
    local entrada = Instance.new("Frame")
    entrada.Name = item.Id
    entrada.Size = UDim2.new(1, -ui.FinalLetterScrollBarThickness - ui.FinalLetterEntryWidthInset, 0, 0)
    entrada.AutomaticSize = Enum.AutomaticSize.Y
    entrada.BackgroundColor3 = Color3.fromRGB(44, 40, 34)
    entrada.BorderSizePixel = 0

    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, ui.FinalLetterCornerRadius)
    canto.Parent = entrada

    local preenchimento = Instance.new("UIPadding")
    preenchimento.PaddingTop = UDim.new(0, ui.FinalLetterEntryPadding)
    preenchimento.PaddingBottom = UDim.new(0, ui.FinalLetterEntryPadding)
    preenchimento.PaddingLeft = UDim.new(0, ui.FinalLetterEntryPadding)
    preenchimento.PaddingRight = UDim.new(0, ui.FinalLetterEntryPadding)
    preenchimento.Parent = entrada

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ui.FinalLetterEntryContentGap)
    layout.Parent = entrada

    local titulo =
        criarTexto("Titulo", ui.FinalLetterEntryTitleTextSize, Color3.fromRGB(229, 194, 111), Enum.Font.Garamond)
    titulo.LayoutOrder = 1
    titulo.Text = item.Titulo
    titulo.Parent = entrada

    local metadados =
        criarTexto("Metadados", ui.FinalLetterMetadataTextSize, Color3.fromRGB(183, 174, 152), Enum.Font.Gotham)
    metadados.LayoutOrder = 2
    metadados.Text = `{item.Data}  •  {item.Zona}`
    metadados.Parent = entrada

    local trecho =
        criarTexto("Trecho", ui.FinalLetterExcerptTextSize, Color3.fromRGB(219, 205, 174), Enum.Font.Garamond)
    trecho.LayoutOrder = 3
    trecho.Text = `“{item.Trecho}”`
    trecho.Parent = entrada

    local corpo = criarTexto("Texto", ui.FinalLetterBodyTextSize, Color3.fromRGB(244, 238, 220), Enum.Font.Garamond)
    corpo.LayoutOrder = 4
    corpo.Text = item.Texto
    corpo.Parent = entrada

    local fonte = criarTexto("Fonte", ui.FinalLetterMetadataTextSize, Color3.fromRGB(202, 192, 169), Enum.Font.Gotham)
    fonte.LayoutOrder = 5
    fonte.Text = `Fonte: {item.Fonte}`
    fonte.Parent = entrada

    return entrada
end

function HelpRequestUI.exibir(carta: CartaHistorica): ()
    local gui = guiAtual
    local lista = listaTrechos
    if gui == nil or lista == nil then
        return
    end

    for _, filho in lista:GetChildren() do
        if filho:IsA("Frame") then
            filho:Destroy()
        end
    end

    for indice, item in carta.Trechos do
        local entrada = criarEntrada(item)
        entrada.LayoutOrder = indice
        entrada.Parent = lista
    end

    local subtitulo = gui:FindFirstChild("Painel")
    if subtitulo ~= nil then
        local cabecalho = subtitulo:FindFirstChild("Subtitulo")
        if cabecalho ~= nil and cabecalho:IsA("TextLabel") then
            cabecalho.Text = `Documento reunido: {carta.Total}/{carta.Total} trechos • conclusão da investigação`
        end
    end

    gui.Enabled = true
end

function HelpRequestUI.inicializar(): ()
    if guiAtual ~= nil then
        return
    end

    local jogador = Players.LocalPlayer
    local playerGui = jogador:WaitForChild("PlayerGui")
    local ui = Config.UI

    local gui = Instance.new("ScreenGui")
    gui.Name = "LeituraCartaFinal"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = ui.FinalLetterDisplayOrder
    gui.Enabled = false

    local painel = Instance.new("Frame")
    painel.Name = "Painel"
    painel.AnchorPoint = Vector2.new(0.5, 0.5)
    painel.Position = UDim2.fromScale(0.5, 0.5)
    painel.Size = UDim2.new(1, -ui.FinalLetterScreenMargin * 2, 1, -ui.FinalLetterScreenMargin * 2)
    painel.BackgroundColor3 = Color3.fromRGB(32, 29, 26)
    painel.BorderSizePixel = 0
    painel.Parent = gui

    local limite = Instance.new("UISizeConstraint")
    limite.MaxSize = Vector2.new(ui.FinalLetterPanelWidth, ui.FinalLetterPanelHeight)
    limite.Parent = painel

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(ui.FinalLetterContentInset, ui.FinalLetterHeaderTitleTop)
    titulo.Size = UDim2.new(
        1,
        -ui.FinalLetterContentInset * 2 - ui.FinalLetterCloseButtonSize,
        0,
        ui.FinalLetterHeaderTitleHeight
    )
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.Garamond
    titulo.Text = "Sala 214 — Carta histórica completa"
    titulo.TextColor3 = Color3.fromRGB(230, 218, 190)
    titulo.TextSize = ui.FinalLetterTitleTextSize
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = painel

    local subtitulo = Instance.new("TextLabel")
    subtitulo.Name = "Subtitulo"
    subtitulo.Position = UDim2.fromOffset(ui.FinalLetterContentInset, ui.FinalLetterHeaderSubtitleTop)
    subtitulo.Size = UDim2.new(1, -ui.FinalLetterContentInset * 2, 0, ui.FinalLetterHeaderSubtitleHeight)
    subtitulo.BackgroundTransparency = 1
    subtitulo.Font = Enum.Font.Gotham
    subtitulo.Text = "A carta foi recomposta a partir das pistas encontradas."
    subtitulo.TextColor3 = Color3.fromRGB(183, 174, 152)
    subtitulo.TextSize = ui.FinalLetterSubtitleTextSize
    subtitulo.TextXAlignment = Enum.TextXAlignment.Left
    subtitulo.Parent = painel

    local fechar = Instance.new("TextButton")
    fechar.Name = "Fechar"
    fechar.AnchorPoint = Vector2.new(1, 0)
    fechar.Position = UDim2.new(1, -ui.FinalLetterContentInset, 0, 12)
    fechar.Size = UDim2.fromOffset(ui.FinalLetterCloseButtonSize, ui.FinalLetterCloseButtonSize)
    fechar.BackgroundColor3 = Color3.fromRGB(112, 82, 52)
    fechar.BorderSizePixel = 0
    fechar.Font = Enum.Font.GothamBold
    fechar.Text = "×"
    fechar.TextColor3 = Color3.fromRGB(255, 245, 225)
    fechar.TextSize = ui.FinalLetterCloseTextSize
    fechar.Parent = painel
    fechar.Activated:Connect(function()
        gui.Enabled = false
    end)

    local lista = Instance.new("ScrollingFrame")
    lista.Name = "Trechos"
    lista.Position = UDim2.fromOffset(ui.FinalLetterContentInset, ui.FinalLetterHeaderHeight)
    lista.Size =
        UDim2.new(1, -ui.FinalLetterContentInset * 2, 1, -ui.FinalLetterHeaderHeight - ui.FinalLetterContentInset)
    lista.BackgroundTransparency = 1
    lista.BorderSizePixel = 0
    lista.CanvasSize = UDim2.new()
    lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lista.ScrollBarThickness = ui.FinalLetterScrollBarThickness
    lista.ScrollingDirection = Enum.ScrollingDirection.Y
    lista.Parent = painel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ui.FinalLetterEntryGap)
    layout.Parent = lista

    gui.Parent = playerGui
    guiAtual = gui
    listaTrechos = lista

    Remotes.obter("CartaCompletaAtualizada").OnClientEvent:Connect(function(valor: unknown)
        local carta = decodificarCarta(valor)
        if carta ~= nil then
            HelpRequestUI.exibir(carta)
        end
    end)
end

return HelpRequestUI
