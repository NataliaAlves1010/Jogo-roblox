--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotos")
local clueDataModule = sharedFolder:WaitForChild("ClueData") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local ClueData = require(clueDataModule)
local Types = require(typesModule)

type Inventario = Types.Inventario

local InventoryUI = {}
local listaChaves: ScrollingFrame? = nil
local listaPistas: ScrollingFrame? = nil
local inicializado = false

local textosPistas: { [string]: string } = {}
for _, pista in ClueData.obterTodas() do
    textosPistas[pista.Id] = pista.Texto
end

local function criarSecao(painel: Frame, nome: string, titulo: string, posicaoY: number, altura: number): ScrollingFrame
    local cabecalho = Instance.new("TextLabel")
    cabecalho.Name = `Titulo{nome}`
    cabecalho.Position = UDim2.fromOffset(14, posicaoY)
    cabecalho.Size = UDim2.new(1, -28, 0, 22)
    cabecalho.BackgroundTransparency = 1
    cabecalho.Font = Enum.Font.GothamBold
    cabecalho.Text = titulo
    cabecalho.TextColor3 = Color3.fromRGB(230, 219, 191)
    cabecalho.TextSize = 14
    cabecalho.TextXAlignment = Enum.TextXAlignment.Left
    cabecalho.Parent = painel

    local lista = Instance.new("ScrollingFrame")
    lista.Name = `Lista{nome}`
    lista.Position = UDim2.fromOffset(14, posicaoY + 24)
    lista.Size = UDim2.new(1, -28, 0, altura)
    lista.BackgroundColor3 = Color3.fromRGB(30, 31, 34)
    lista.BackgroundTransparency = 0.15
    lista.BorderSizePixel = 0
    lista.ScrollBarThickness = 5
    lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lista.CanvasSize = UDim2.new()
    lista.Parent = painel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = lista

    return lista
end

local function criarInterface(): ()
    local jogador = Players.LocalPlayer
    if jogador == nil then
        return
    end

    local playerGui = jogador:WaitForChild("PlayerGui")
    local novaGui = Instance.new("ScreenGui")
    novaGui.Name = "InventarioDoJogador"
    novaGui.ResetOnSpawn = false
    novaGui.Parent = playerGui
    local painel = Instance.new("Frame")
    painel.Name = "Painel"
    painel.AnchorPoint = Vector2.new(1, 1)
    painel.Position = UDim2.new(1, -18, 1, -18)
    painel.Size = UDim2.fromOffset(310, 350)
    painel.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
    painel.BackgroundTransparency = 0.08
    painel.BorderSizePixel = 0
    painel.Parent = novaGui

    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 8)
    canto.Parent = painel

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(14, 10)
    titulo.Size = UDim2.new(1, -28, 0, 24)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = "ANOTAÇÕES"
    titulo.TextColor3 = Color3.fromRGB(244, 235, 214)
    titulo.TextSize = 16
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = painel

    listaChaves = criarSecao(painel, "Chaves", "Chaves", 42, 72)
    listaPistas = criarSecao(painel, "Pistas", "Diário de pistas", 145, 190)
end

local function limparLista(lista: ScrollingFrame): ()
    for _, filho in lista:GetChildren() do
        if filho:IsA("TextLabel") then
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
    linha.TextSize = 12
    linha.TextWrapped = true
    linha.TextXAlignment = Enum.TextXAlignment.Left
    linha.Parent = lista
end

local function clonarListaDeStrings(valor: unknown): { string }
    local resultado: { string } = {}
    if typeof(valor) ~= "table" then
        return resultado
    end

    for _, item in valor do
        if typeof(item) == "string" then
            table.insert(resultado, item)
        end
    end

    return resultado
end

function InventoryUI.renderizar(inventario: Inventario): ()
    local chaves = listaChaves
    local pistas = listaPistas
    if chaves == nil or pistas == nil then
        return
    end

    limparLista(chaves)
    limparLista(pistas)

    if #inventario.Chaves == 0 then
        criarLinha(chaves, "Nenhuma chave encontrada.", 1, 30)
    else
        for ordem, id in inventario.Chaves do
            criarLinha(chaves, string.gsub(id, "_", " "), ordem, 30)
        end
    end

    if #inventario.Pistas == 0 then
        criarLinha(pistas, "As pistas encontradas aparecerão aqui.", 1, 40)
    else
        for ordem, id in inventario.Pistas do
            local descricao = textosPistas[id]
            local texto = if descricao ~= nil then descricao else string.gsub(id, "_", " ")
            criarLinha(pistas, texto, ordem, 54)
        end
    end
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
            Chaves = clonarListaDeStrings(dados.Chaves),
            Pistas = clonarListaDeStrings(dados.Pistas),
        }
        InventoryUI.renderizar(inventario)
    end)

    InventoryUI.renderizar({ Chaves = {}, Pistas = {} })
end

return InventoryUI
