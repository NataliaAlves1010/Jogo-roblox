--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local clueDataModule = sharedFolder:WaitForChild("ClueData") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local letterDataModule = sharedFolder:WaitForChild("LetterData") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local inventoryModule = script.Parent:WaitForChild("Inventory") :: ModuleScript
local ClueData = require(clueDataModule)
local Config = require(configModule)
local LetterData = require(letterDataModule)
local Remotes = require(remotesModule)
local Types = require(typesModule)
local Inventory = require(inventoryModule)

type CartaHistorica = Types.CartaHistorica
type ItemCartaHistorica = Types.ItemCartaHistorica

local HelpRequest = {}
local inicializado = false
local remotoCartaCompleta: RemoteEvent? = nil

local function jogadorNaSala(jogador: Player): boolean
    local personagem = jogador.Character
    local raiz = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
    local mapa = workspace:FindFirstChild("Labirinto")
    local sala = if mapa ~= nil then mapa:FindFirstChild("Sala 214") else nil
    local porta = if sala ~= nil and sala:IsA("Model") then sala.PrimaryPart else nil
    local piso = if sala ~= nil then sala:FindFirstChild("Piso") else nil
    if
        jogador.Parent ~= Players
        or raiz == nil
        or not raiz:IsA("BasePart")
        or porta == nil
        or porta:GetAttribute("PortaFinal") ~= true
        or porta:GetAttribute("Aberta") ~= true
        or piso == nil
        or not piso:IsA("BasePart")
    then
        return false
    end

    local localizacao = piso.CFrame:PointToObjectSpace(raiz.Position)
    local meiaCelula = Config.Maze.CellSize / 2
    return math.abs(localizacao.X) <= meiaCelula
        and math.abs(localizacao.Z) <= meiaCelula
        and localizacao.Y >= 0
        and localizacao.Y <= Config.Maze.WallHeight
end

local function valorData(data: string): number
    local diaTexto, mesTexto, anoTexto = string.match(data, "^(%d%d)/(%d%d)/(%d%d%d%d)$")
    local dia = tonumber(diaTexto)
    local mes = tonumber(mesTexto)
    local ano = tonumber(anoTexto)
    if dia == nil or mes == nil or ano == nil then
        return math.huge
    end
    return ano * 10000 + mes * 100 + dia
end

function HelpRequest.inicializar(): ()
    if inicializado then
        return
    end
    remotoCartaCompleta = Remotes.obter("CartaCompletaAtualizada")
    inicializado = true
end

function HelpRequest.compilar(jogador: Player): CartaHistorica?
    local remoto = remotoCartaCompleta
    if not inicializado or remoto == nil or not jogadorNaSala(jogador) then
        return nil
    end

    local inventario = Inventory.obter(jogador)
    local pistasPossuidas: { [string]: boolean } = {}
    for _, pistaId in inventario.Pistas do
        pistasPossuidas[pistaId] = true
    end

    local itens: { ItemCartaHistorica } = {}
    for _, pista in ClueData.obterTodas() do
        if pistasPossuidas[pista.Id] ~= true then
            return nil
        end

        local carta = LetterData.obterCarta(pista.LetterId)
        if carta == nil or carta.Trecho ~= pista.Trecho then
            return nil
        end

        table.insert(itens, {
            Id = carta.Id,
            Zona = carta.Zona,
            Data = carta.Data,
            Titulo = carta.Titulo,
            Trecho = carta.Trecho,
            Texto = carta.Texto,
            Fonte = carta.Fonte,
        })
    end

    if #itens ~= #LetterData.obterTodas() then
        return nil
    end

    table.sort(itens, function(a: ItemCartaHistorica, b: ItemCartaHistorica): boolean
        local dataA = valorData(a.Data)
        local dataB = valorData(b.Data)
        return if dataA == dataB then a.Id < b.Id else dataA < dataB
    end)

    local compilada: CartaHistorica = {
        Trechos = itens,
        Total = #itens,
    }
    remoto:FireClient(jogador, compilada)
    return compilada
end

return HelpRequest
