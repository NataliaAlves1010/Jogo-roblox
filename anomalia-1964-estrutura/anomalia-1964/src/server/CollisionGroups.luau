--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local CollisionGroups = {}

local GRUPO_JOGADOR = "AnomaliaJogador"
local GRUPO_PAREDE = "AnomaliaParede"
local inicializado = false

local function configurarPartePersonagem(objeto: Instance): ()
    if objeto:IsA("BasePart") then
        objeto.CollisionGroup = GRUPO_JOGADOR
    end
end

local function configurarPersonagem(personagem: Model): ()
    for _, objeto in personagem:GetDescendants() do
        configurarPartePersonagem(objeto)
    end
    personagem.DescendantAdded:Connect(configurarPartePersonagem)
end

local function configurarJogador(jogador: Player): ()
    jogador.CharacterAdded:Connect(configurarPersonagem)
    local personagem = jogador.Character
    if personagem ~= nil then
        configurarPersonagem(personagem)
    end
end

local function registrarGrupo(nome: string): ()
    if not PhysicsService:IsCollisionGroupRegistered(nome) then
        PhysicsService:RegisterCollisionGroup(nome)
    end
end

function CollisionGroups.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    registrarGrupo(GRUPO_JOGADOR)
    registrarGrupo(GRUPO_PAREDE)
    PhysicsService:CollisionGroupSetCollidable(GRUPO_JOGADOR, GRUPO_PAREDE, false)
    Players.PlayerAdded:Connect(configurarJogador)
    for _, jogador in Players:GetPlayers() do
        configurarJogador(jogador)
    end
end

function CollisionGroups.configurarParede(parte: BasePart): ()
    parte.CollisionGroup = GRUPO_PAREDE
end

return CollisionGroups
