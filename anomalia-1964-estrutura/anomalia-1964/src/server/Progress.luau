--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local inventoryModule = script.Parent:WaitForChild("Inventory") :: ModuleScript
local interactModule = script.Parent:WaitForChild("Interact") :: ModuleScript
local obstaclesFolder = script.Parent:WaitForChild("Obstacles")
local lockedDoorModule = obstaclesFolder:WaitForChild("LockedDoor") :: ModuleScript
local helpRequestModule = script.Parent:WaitForChild("HelpRequest") :: ModuleScript

local Config = require(configModule)
local Remotes = require(remotesModule)
local Inventory = require(inventoryModule)
local Interact = require(interactModule)
local LockedDoor = require(lockedDoorModule)
local HelpRequest = require(helpRequestModule)

local Progress = {}
local portaAtual: BasePart? = nil
local pisoSalaAtual: BasePart? = nil
local inicioPartida = 0
local conclusoes: { [number]: boolean } = {}
local reinicioPendente = false
local remotesConectados = false

local function jogadorNaSala(jogador: Player): boolean
    local personagem = jogador.Character
    local raiz = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
    local piso = pisoSalaAtual
    if raiz == nil or not raiz:IsA("BasePart") or piso == nil then
        return false
    end

    local localizacao = piso.CFrame:PointToObjectSpace(raiz.Position)
    local meiaCelula = Config.Maze.CellSize / 2
    return math.abs(localizacao.X) <= meiaCelula
        and math.abs(localizacao.Z) <= meiaCelula
        and localizacao.Y >= 0
        and localizacao.Y <= Config.Maze.WallHeight
end

function Progress.validarEntrada(jogador: Player): boolean
    if jogador.Parent ~= Players then
        return false
    end

    local configProgresso = Config.Progress
    for _, chave in configProgresso.RequiredKeys do
        if not Inventory.temChave(jogador, chave) then
            return false
        end
    end

    return Inventory.quantidadePistas(jogador) >= configProgresso.MinimumClues
end

function Progress.concluir(jogador: Player): ()
    local porta = portaAtual
    if
        jogador.Parent ~= Players
        or porta == nil
        or porta:GetAttribute("Aberta") ~= true
        or conclusoes[jogador.UserId] == true
        or not jogadorNaSala(jogador)
    then
        return
    end

    if HelpRequest.compilar(jogador) == nil then
        return
    end

    conclusoes[jogador.UserId] = true
    local tempoSegundos = math.max(0, math.floor(os.clock() - inicioPartida))
    Remotes.obter("VitoriaAtualizada"):FireClient(jogador, tempoSegundos)
end

function Progress.reiniciarMapa(jogador: Player): boolean
    if jogador.Parent ~= Players or conclusoes[jogador.UserId] ~= true or reinicioPendente then
        return false
    end

    local evento = script.Parent:FindFirstChild("ReinicioSolicitado")
    if evento == nil or not evento:IsA("BindableEvent") then
        warn("O reinício foi recusado porque o inicializador da partida não está conectado.")
        return false
    end

    reinicioPendente = true
    Config.Maze.Seed += 1
    evento:Fire(jogador, Config.Maze.Seed)
    return true
end

function Progress.inicializar(sala: Model): ()
    local porta = sala.PrimaryPart
    assert(porta ~= nil, "A Sala 214 precisa ter a porta final como peça principal")
    assert(porta:GetAttribute("PortaFinal") == true, "A peça principal precisa ser a porta final")
    local piso = sala:FindFirstChild("Piso")
    assert(piso ~= nil and piso:IsA("BasePart"), "A Sala 214 precisa ter um piso de chegada")

    portaAtual = porta
    pisoSalaAtual = piso
    inicioPartida = os.clock()
    table.clear(conclusoes)
    reinicioPendente = false

    local prompt = Interact.criar(porta, "Abrir", function(jogador: Player)
        if not Progress.validarEntrada(jogador) then
            return
        end

        LockedDoor.abrir(porta)
    end)
    prompt.ObjectText = "Sala 214"
    prompt.MaxActivationDistance = Config.Progress.InteractionDistance
    porta:SetAttribute("ProgressaoValidadaPeloServidor", true)

    piso.Touched:Connect(function(parte)
        local personagem = parte:FindFirstAncestorOfClass("Model")
        local jogador = if personagem ~= nil then Players:GetPlayerFromCharacter(personagem) else nil
        if jogador ~= nil then
            Progress.concluir(jogador)
        end
    end)

    if remotesConectados then
        return
    end
    remotesConectados = true
    Remotes.obter("SolicitarReinicio").OnServerEvent:Connect(function(jogador: Player)
        Progress.reiniciarMapa(jogador)
    end)
    Players.PlayerRemoving:Connect(function(jogador: Player)
        conclusoes[jogador.UserId] = nil
    end)
end

return Progress
