--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Remotes = require(remotesModule)
local Types = require(typesModule)

type Inventario = Types.Inventario

type EstadoInventario = {
    Publico: Inventario,
    Chaves: { [string]: boolean },
    Pistas: { [string]: boolean },
}

local Inventory = {}
local estadosPorJogador: { [number]: EstadoInventario } = {}
local remotoInventario: RemoteEvent? = nil
local inicializado = false

local function criarEstado(jogador: Player): EstadoInventario
    local existente = estadosPorJogador[jogador.UserId]
    if existente ~= nil then
        return existente
    end

    local estado: EstadoInventario = {
        Publico = {
            Chaves = {},
            Pistas = {},
        },
        Chaves = {},
        Pistas = {},
    }
    estadosPorJogador[jogador.UserId] = estado
    return estado
end

local function copiarInventario(inventario: Inventario): Inventario
    return {
        Chaves = table.clone(inventario.Chaves),
        Pistas = table.clone(inventario.Pistas),
    }
end

local function publicar(jogador: Player, estado: EstadoInventario): ()
    local remoto = remotoInventario
    if remoto ~= nil and jogador.Parent == Players then
        remoto:FireClient(jogador, copiarInventario(estado.Publico))
    end
end

local function conectarJogador(jogador: Player): ()
    publicar(jogador, criarEstado(jogador))
end

local function adicionar(jogador: Player, id: string, lista: { string }, ids: { [string]: boolean }): boolean
    if id == "" or jogador.Parent ~= Players then
        return false
    end

    local estado = criarEstado(jogador)
    if ids[id] == true then
        return false
    end

    ids[id] = true
    table.insert(lista, id)
    publicar(jogador, estado)
    return true
end

function Inventory.inicializar(): ()
    if inicializado then
        return
    end

    remotoInventario = Remotes.obter("InventarioAtualizado")
    inicializado = true
    Players.PlayerAdded:Connect(conectarJogador)
    Players.PlayerRemoving:Connect(function(jogador: Player)
        estadosPorJogador[jogador.UserId] = nil
    end)

    for _, jogador in Players:GetPlayers() do
        conectarJogador(jogador)
    end
end

function Inventory.obter(jogador: Player): Inventario
    return copiarInventario(criarEstado(jogador).Publico)
end

function Inventory.adicionarChave(jogador: Player, id: string): boolean
    local estado = criarEstado(jogador)
    return adicionar(jogador, id, estado.Publico.Chaves, estado.Chaves)
end

function Inventory.adicionarPista(jogador: Player, id: string): boolean
    local estado = criarEstado(jogador)
    return adicionar(jogador, id, estado.Publico.Pistas, estado.Pistas)
end

function Inventory.temChave(jogador: Player, id: string): boolean
    local estado = estadosPorJogador[jogador.UserId]
    return if estado == nil then false else estado.Chaves[id] == true
end

function Inventory.temPista(jogador: Player, id: string): boolean
    local estado = estadosPorJogador[jogador.UserId]
    return if estado == nil then false else estado.Pistas[id] == true
end

function Inventory.quantidadePistas(jogador: Player): number
    local estado = estadosPorJogador[jogador.UserId]
    return if estado == nil then 0 else #estado.Publico.Pistas
end

return Inventory
