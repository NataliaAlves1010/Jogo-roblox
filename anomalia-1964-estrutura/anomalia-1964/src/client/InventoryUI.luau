--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotos")
local clueDataModule = sharedFolder:WaitForChild("ClueData") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local letterDataModule = sharedFolder:WaitForChild("LetterData") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local ClueData = require(clueDataModule)
local Config = require(configModule)
local LetterData = require(letterDataModule)
local Types = require(typesModule)

type Inventario = Types.Inventario
type TrechoCarta = Types.TrechoCarta
type Carta = LetterData.Carta

type TrechoReunido = {
    Carta: Carta,
    Trecho: TrechoCarta,
}

local InventoryUI = {}
local listaChaves: ScrollingFrame? = nil
local listaPistas: ScrollingFrame? = nil
local listaCartas: ScrollingFrame? = nil
local progressoCartas: TextLabel? = nil
local paginaItens: Frame? = nil
local paginaCartas: Frame? = nil
local botoesAbas: { TextButton } = {}
local inicializado = false
local trechosPorCarta: { [string]: TrechoCarta } = {}
local pistasPorId: { [string]: ClueData.Pista } = {}

for _, pista in ClueData.obterTodas() do
    pistasPorId[pista.Id] = pista
end

local function criarLista(painel: Frame, nome: string, titulo: string, posicaoY: number, altura: number): ScrollingFrame
    local configUI = Config.UI
    local cabecalho = Instance.new("TextLabel")
    cabecalho.Name = `Titulo{nome}`
    cabecalho.Position = UDim2.fromOffset(0, posicaoY)
    cabecalho.Size = UDim2.new(1, 0, 0, configUI.InventorySectionHeaderHeight)
    cabecalho.BackgroundTransparency = 1
    cabecalho.Font = Enum.Font.GothamBold
    cabecalho.Text = titulo
    cabecalho.TextColor3 = Color3.fromRGB(230, 219, 191)
    cabecalho.TextSize = configUI.InventoryTextSize + 2
    cabecalho.TextXAlignment = Enum.TextXAlignment.Left
    cabecalho.Parent = painel

    local lista = Instance.new("ScrollingFrame")
    lista.Name = `Lista{nome}`
    lista.Position = UDim2.fromOffset(0, posicaoY + configUI.InventorySectionHeaderHeight)
    lista.Size = UDim2.new(1, 0, 0, altura)
    lista.BackgroundColor3 = Color3.fromRGB(30, 31, 34)
    lista.BackgroundTransparency = 0.15
    lista.BorderSizePixel = 0
    lista.ScrollBarThickness = configUI.InventoryScrollBarThickness
    lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lista.CanvasSize = UDim2.new()
    lista.Parent = painel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, configUI.InventoryListGap)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = lista
    return lista
end

local function criarBotaoAba(painel: Frame, texto: string, ordem: number): TextButton
    local configUI = Config.UI
    local botao = Instance.new("TextButton")
    botao.Name = `Aba{texto}`
    botao.Position = UDim2.new((ordem - 1) * 0.5, configUI.InventoryPanelInset, 0, configUI.InventoryTabTop)
    botao.Size = UDim2.new(0.5, -configUI.InventoryPanelInset * 1.5, 0, configUI.InventoryTabHeight)
    botao.BackgroundColor3 = Color3.fromRGB(55, 51, 43)
    botao.BorderSizePixel = 0
    botao.Font = Enum.Font.GothamBold
    botao.Text = texto
    botao.TextColor3 = Color3.fromRGB(230, 219, 191)
    botao.TextSize = configUI.InventoryTabTextSize
    botao.Parent = painel
    return botao
end

local function selecionarAba(ordem: number): ()
    local itens = paginaItens
    local cartas = paginaCartas
    if itens == nil or cartas == nil then
        return
    end
    local mostrarCartas = ordem == 2
    itens.Visible = not mostrarCartas
    cartas.Visible = mostrarCartas
    for indice, botao in botoesAbas do
        botao.BackgroundColor3 = if indice == ordem then Color3.fromRGB(105, 83, 49) else Color3.fromRGB(55, 51, 43)
    end
end

local function criarInterface(): ()
    local jogador = Players.LocalPlayer
    if jogador == nil then
        return
    end

    local configUI = Config.UI
    local playerGui = jogador:WaitForChild("PlayerGui")
    local existente = playerGui:FindFirstChild("InventarioDoJogador")
    if existente ~= nil then
        existente:Destroy()
    end

    local novaGui = Instance.new("ScreenGui")
    novaGui.Name = "InventarioDoJogador"
    novaGui.ResetOnSpawn = false
    novaGui.Parent = playerGui
    local painel = Instance.new("Frame")
    painel.Name = "Painel"
    painel.AnchorPoint = Vector2.new(1, 1)
    painel.Position = UDim2.new(1, -configUI.InventoryPanelRightMargin, 1, -configUI.InventoryPanelBottomMargin)
    painel.Size = UDim2.fromOffset(configUI.InventoryPanelWidth, configUI.InventoryPanelHeight)
    painel.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
    painel.BackgroundTransparency = 0.08
    painel.BorderSizePixel = 0
    painel.Parent = novaGui

    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 8)
    canto.Parent = painel

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(configUI.InventoryPanelInset, configUI.InventoryTitleTop)
    titulo.Size = UDim2.new(1, -configUI.InventoryPanelInset * 2, 0, configUI.InventoryTitleHeight)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "ANOTAÇÕES"
    titulo.TextColor3 = Color3.fromRGB(244, 235, 214)
    titulo.TextSize = configUI.InventoryTitleTextSize
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = painel

    local abaItens = criarBotaoAba(painel, "Pistas", 1)
    local abaCartas = criarBotaoAba(painel, "Cartas", 2)
    table.insert(botoesAbas, abaItens)
    table.insert(botoesAbas, abaCartas)

    local alturaConteudo = configUI.InventoryPanelHeight - configUI.InventoryContentTop - configUI.InventoryPanelInset
    local itens = Instance.new("Frame")
    itens.Name = "PaginaPistas"
    itens.Position = UDim2.fromOffset(configUI.InventoryPanelInset, configUI.InventoryContentTop)
    itens.Size = UDim2.new(1, -configUI.InventoryPanelInset * 2, 0, alturaConteudo)
    itens.BackgroundTransparency = 1
    itens.Parent = painel
    paginaItens = itens
    listaChaves = criarLista(itens, "Chaves", "Chaves", 0, configUI.InventoryKeyListHeight)
    listaPistas = criarLista(
        itens,
        "Pistas",
        "Diário de pistas",
        configUI.InventoryClueSectionTop,
        configUI.InventoryClueListHeight
    )

    local cartas = Instance.new("Frame")
    cartas.Name = "PaginaCartas"
    cartas.Position = itens.Position
    cartas.Size = itens.Size
    cartas.BackgroundTransparency = 1
    cartas.Visible = false
    cartas.Parent = painel
    paginaCartas = cartas
    local progresso = Instance.new("TextLabel")
    progresso.Name = "ProgressoCartas"
    progresso.Size = UDim2.new(1, 0, 0, configUI.InventoryLetterProgressHeight)
    progresso.BackgroundTransparency = 1
    progresso.Font = Enum.Font.GothamBold
    progresso.TextColor3 = Color3.fromRGB(229, 194, 111)
    progresso.TextSize = configUI.InventoryTextSize
    progresso.TextXAlignment = Enum.TextXAlignment.Left
    progresso.Parent = cartas
    progressoCartas = progresso
    local lista = Instance.new("ScrollingFrame")
    lista.Name = "ListaCartas"
    lista.Position = UDim2.fromOffset(0, configUI.InventoryLetterListTop)
    lista.Size = UDim2.new(1, 0, 1, -configUI.InventoryLetterListTop)
    lista.BackgroundColor3 = Color3.fromRGB(30, 31, 34)
    lista.BackgroundTransparency = 0.15
    lista.BorderSizePixel = 0
    lista.ScrollBarThickness = configUI.InventoryScrollBarThickness
    lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lista.CanvasSize = UDim2.new()
    lista.Parent = cartas
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, configUI.InventoryListGap)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = lista
    listaCartas = lista

    abaItens.Activated:Connect(function()
        selecionarAba(1)
    end)
    abaCartas.Activated:Connect(function()
        selecionarAba(2)
    end)
    selecionarAba(1)
end

local function limparLista(lista: ScrollingFrame): ()
    for _, filho in lista:GetChildren() do
        if not filho:IsA("UIListLayout") then
            filho:Destroy()
        end
    end
end

local function criarLinha(lista: ScrollingFrame, texto: string, ordem: number, altura: number): ()
    local linha = Instance.new("TextLabel")
    linha.Name = `Item{ordem}`
    linha.LayoutOrder = ordem
    linha.Size = UDim2.new(1, -8, 0, altura)
    linha.BackgroundTransparency = 1
    linha.Font = Enum.Font.Gotham
    linha.Text = texto
    linha.TextColor3 = Color3.fromRGB(226, 226, 226)
    linha.TextSize = Config.UI.InventoryTextSize
    linha.TextWrapped = true
    linha.TextXAlignment = Enum.TextXAlignment.Left
    linha.Parent = lista
end

local function valorData(carta: Carta): number
    local diaTexto, mesTexto, anoTexto = string.match(carta.Data, "^(%d%d)/(%d%d)/(%d%d%d%d)$")
    local dia = tonumber(diaTexto)
    local mes = tonumber(mesTexto)
    local ano = tonumber(anoTexto)
    if dia == nil or mes == nil or ano == nil then
        return math.huge
    end
    return ano * 10000 + mes * 100 + dia
end

function InventoryUI.adicionarTrecho(trecho: TrechoCarta): ()
    local pista = pistasPorId[trecho.PistaId]
    local carta = LetterData.obterCarta(trecho.LetterId)
    if pista == nil or carta == nil or pista.LetterId ~= trecho.LetterId then
        return
    end

    trechosPorCarta[carta.Id] = {
        PistaId = trecho.PistaId,
        LetterId = carta.Id,
        Trecho = carta.Trecho,
    }
    InventoryUI.renderizarCartas()
end

function InventoryUI.renderizarCartas(): ()
    local lista = listaCartas
    local progresso = progressoCartas
    if lista == nil or progresso == nil then
        return
    end
    limparLista(lista)

    local reunidos: { TrechoReunido } = {}
    for letterId, trecho in trechosPorCarta do
        local carta = LetterData.obterCarta(letterId)
        if carta ~= nil then
            table.insert(reunidos, { Carta = carta, Trecho = trecho })
        end
    end
    table.sort(reunidos, function(a: TrechoReunido, b: TrechoReunido): boolean
        local dataA = valorData(a.Carta)
        local dataB = valorData(b.Carta)
        return if dataA == dataB then a.Carta.Id < b.Carta.Id else dataA < dataB
    end)

    local totalCartas = #LetterData.obterTodas()
    progresso.Text = `Trechos reunidos: {#reunidos}/{totalCartas}`
    if #reunidos == 0 then
        criarLinha(lista, "Nenhum trecho de carta encontrado.", 1, Config.UI.InventoryKeyRowHeight)
        return
    end

    for ordem, reunido in reunidos do
        local configUI = Config.UI
        local carta = reunido.Carta
        local card = Instance.new("Frame")
        card.Name = `Carta{carta.Id}`
        card.LayoutOrder = ordem
        card.Size = UDim2.new(1, -8, 0, configUI.InventoryLetterCardHeight)
        card.BackgroundColor3 = Color3.fromRGB(41, 40, 37)
        card.BorderSizePixel = 0
        card.Parent = lista
        local titulo = Instance.new("TextLabel")
        titulo.Position = UDim2.fromOffset(configUI.InventoryLetterCardInset, configUI.InventoryLetterCardInset)
        titulo.Size = UDim2.new(
            1,
            -configUI.InventoryLetterDateWidth - configUI.InventoryLetterCardInset * 3,
            0,
            configUI.InventoryLetterTitleHeight
        )
        titulo.BackgroundTransparency = 1
        titulo.Font = Enum.Font.GothamBold
        titulo.Text = carta.Titulo
        titulo.TextColor3 = Color3.fromRGB(244, 235, 214)
        titulo.TextSize = configUI.InventoryLetterTitleTextSize
        titulo.TextTruncate = Enum.TextTruncate.AtEnd
        titulo.TextXAlignment = Enum.TextXAlignment.Left
        titulo.Parent = card
        local data = Instance.new("TextLabel")
        data.AnchorPoint = Vector2.new(1, 0)
        data.Position = UDim2.new(1, -configUI.InventoryLetterCardInset, 0, configUI.InventoryLetterCardInset)
        data.Size = UDim2.fromOffset(configUI.InventoryLetterDateWidth, configUI.InventoryLetterDateHeight)
        data.BackgroundTransparency = 1
        data.Font = Enum.Font.Gotham
        data.Text = carta.Data
        data.TextColor3 = Color3.fromRGB(180, 172, 152)
        data.TextSize = configUI.InventoryLetterDateTextSize
        data.TextXAlignment = Enum.TextXAlignment.Right
        data.Parent = card
        local texto = Instance.new("TextLabel")
        texto.Position = UDim2.fromOffset(configUI.InventoryLetterCardInset, configUI.InventoryLetterExcerptTop)
        texto.Size = UDim2.new(1, -configUI.InventoryLetterCardInset * 2, 0, configUI.InventoryLetterExcerptHeight)
        texto.BackgroundTransparency = 1
        texto.Font = Enum.Font.Garamond
        texto.Text = reunido.Trecho.Trecho
        texto.TextColor3 = Color3.fromRGB(226, 221, 207)
        texto.TextSize = configUI.InventoryLetterExcerptTextSize
        texto.TextWrapped = true
        texto.TextXAlignment = Enum.TextXAlignment.Left
        texto.TextYAlignment = Enum.TextYAlignment.Top
        texto.Parent = card
    end
end

function InventoryUI.renderizar(inventario: Inventario): ()
    local chaves = listaChaves
    local pistas = listaPistas
    if chaves == nil or pistas == nil then
        return
    end

    limparLista(chaves)
    limparLista(pistas)
    local letrasEncontradas: { [string]: boolean } = {}
    for _, pistaId in inventario.Pistas do
        local pista = pistasPorId[pistaId]
        if pista ~= nil then
            letrasEncontradas[pista.LetterId] = true
            InventoryUI.adicionarTrecho({
                PistaId = pista.Id,
                LetterId = pista.LetterId,
                Trecho = pista.Trecho,
            })
        end
    end
    for letterId in trechosPorCarta do
        if letrasEncontradas[letterId] ~= true then
            trechosPorCarta[letterId] = nil
        end
    end
    InventoryUI.renderizarCartas()

    if #inventario.Chaves == 0 then
        criarLinha(chaves, "Nenhuma chave encontrada.", 1, Config.UI.InventoryKeyRowHeight)
    else
        for ordem, id in inventario.Chaves do
            criarLinha(chaves, string.gsub(id, "_", " "), ordem, Config.UI.InventoryKeyRowHeight)
        end
    end

    if #inventario.Pistas == 0 then
        criarLinha(pistas, "As pistas encontradas aparecerão aqui.", 1, Config.UI.InventoryClueRowHeight)
    else
        for ordem, id in inventario.Pistas do
            local pista = pistasPorId[id]
            local descricao = if pista ~= nil then pista.Texto else string.gsub(id, "_", " ")
            criarLinha(pistas, descricao, ordem, Config.UI.InventoryClueRowHeight)
        end
    end
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

function InventoryUI.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    criarInterface()

    local inventarioAtualizado = remotesFolder:WaitForChild("InventarioAtualizado")
    assert(inventarioAtualizado:IsA("RemoteEvent"), "InventarioAtualizado precisa ser um RemoteEvent")
    inventarioAtualizado.OnClientEvent:Connect(function(valor: unknown)
        if typeof(valor) ~= "table" then
            return
        end
        local dados = valor :: { [string]: unknown }
        local inventario: Inventario = {
            Chaves = {},
            Pistas = {},
        }
        if typeof(dados.Chaves) == "table" then
            for _, item in dados.Chaves do
                if typeof(item) == "string" then
                    table.insert(inventario.Chaves, item)
                end
            end
        end
        if typeof(dados.Pistas) == "table" then
            for _, item in dados.Pistas do
                if typeof(item) == "string" then
                    table.insert(inventario.Pistas, item)
                end
            end
        end
        InventoryUI.renderizar(inventario)
    end)

    local trechoRecebido = remotesFolder:WaitForChild("TrechoRecebido")
    assert(trechoRecebido:IsA("RemoteEvent"), "TrechoRecebido precisa ser um RemoteEvent")
    trechoRecebido.OnClientEvent:Connect(function(valor: unknown)
        local trecho = decodificarTrecho(valor)
        if trecho ~= nil then
            InventoryUI.adicionarTrecho(trecho)
        end
    end)

    InventoryUI.renderizar({ Chaves = {}, Pistas = {} })
end

return InventoryUI
