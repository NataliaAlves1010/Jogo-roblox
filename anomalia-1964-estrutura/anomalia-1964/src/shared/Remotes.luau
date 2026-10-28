--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)
type NomeRemoto = Types.NomeRemoto

local NOME_PASTA_REMOTOS = "Remotos"
local NOMES_REMOTOS: { NomeRemoto } = {
    "SolicitarInteracao",
    "SolicitarConversa",
    "AlertaAtualizado",
    "InventarioAtualizado",
    "DialogoAtualizado",
    "SolicitarReinicio",
    "VitoriaAtualizada",
    "SolicitarSprint",
    -- Dinâmica de pistas, ruído e cartas (T43)
    "PistaColetadaCliente",
    "RuidoEmitido",
    "TrechoRecebido",
    "CartaCompletaAtualizada",
}

local REMOTOS_PERMITIDOS: { [string]: boolean } = {}
for _, nome in NOMES_REMOTOS do
    REMOTOS_PERMITIDOS[nome] = true
end

local Remotes = {}

function Remotes.inicializar(): Folder
    if not RunService:IsServer() then
        error("Somente o servidor pode inicializar os remotos.", 2)
    end

    local pasta = ReplicatedStorage:FindFirstChild(NOME_PASTA_REMOTOS)
    if pasta ~= nil and not pasta:IsA("Folder") then
        error("O objeto Remotos precisa ser uma pasta.", 2)
    end

    if pasta == nil then
        local novaPasta = Instance.new("Folder")
        novaPasta.Name = NOME_PASTA_REMOTOS
        novaPasta.Parent = ReplicatedStorage
        pasta = novaPasta
    end

    for _, nome in NOMES_REMOTOS do
        local remoto = pasta:FindFirstChild(nome)
        if remoto == nil then
            local novoRemoto = Instance.new("RemoteEvent")
            novoRemoto.Name = nome
            novoRemoto.Parent = pasta
        elseif not remoto:IsA("RemoteEvent") then
            error(`O objeto {nome} precisa ser um RemoteEvent.`, 2)
        end
    end

    return pasta :: Folder
end

function Remotes.obter(nome: string): RemoteEvent
    if REMOTOS_PERMITIDOS[nome] ~= true then
        error(`Nome de remoto desconhecido: {nome}`, 2)
    end

    local pasta = ReplicatedStorage:WaitForChild(NOME_PASTA_REMOTOS)
    if not pasta:IsA("Folder") then
        error("O objeto Remotos precisa ser uma pasta.", 2)
    end

    local remoto = pasta:WaitForChild(nome)
    if not remoto:IsA("RemoteEvent") then
        error(`O objeto {nome} precisa ser um RemoteEvent.`, 2)
    end

    return remoto
end

return Remotes
