--!strict

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverFolder = script.Parent
local guardFolder = serverFolder:WaitForChild("Guard")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local remotesModule = sharedFolder:WaitForChild("Remotes") :: ModuleScript
local mazeGeneratorModule = serverFolder:WaitForChild("MazeGenerator") :: ModuleScript
local mazeBuilderModule = serverFolder:WaitForChild("MazeBuilder") :: ModuleScript
local zonesModule = serverFolder:WaitForChild("Zones") :: ModuleScript
local checkpointsModule = serverFolder:WaitForChild("Checkpoints") :: ModuleScript
local goalRoomModule = serverFolder:WaitForChild("GoalRoom") :: ModuleScript
local hideSpotsModule = serverFolder:WaitForChild("HideSpots") :: ModuleScript
local captureModule = serverFolder:WaitForChild("Capture") :: ModuleScript
local inventoryModule = serverFolder:WaitForChild("Inventory") :: ModuleScript
local cluesModule = serverFolder:WaitForChild("Clues") :: ModuleScript
local janitorModule = serverFolder:WaitForChild("Janitor") :: ModuleScript
local progressModule = serverFolder:WaitForChild("Progress") :: ModuleScript
local spawnModule = guardFolder:WaitForChild("Spawn") :: ModuleScript
local patrolModule = guardFolder:WaitForChild("Patrol") :: ModuleScript
local visionModule = guardFolder:WaitForChild("Vision") :: ModuleScript
local chaseModule = guardFolder:WaitForChild("Chase") :: ModuleScript
local stateMachineModule = guardFolder:WaitForChild("StateMachine") :: ModuleScript

local Config = require(configModule)
local Remotes = require(remotesModule)
local MazeGenerator = require(mazeGeneratorModule)
local MazeBuilder = require(mazeBuilderModule)
local Zones = require(zonesModule)
local Checkpoints = require(checkpointsModule)
local GoalRoom = require(goalRoomModule)
local HideSpots = require(hideSpotsModule)
local Capture = require(captureModule)
local Inventory = require(inventoryModule)
local Clues = require(cluesModule)
local Janitor = require(janitorModule)
local Progress = require(progressModule)
local GuardSpawn = require(spawnModule)
local Patrol = require(patrolModule)
local Vision = require(visionModule)
local Chase = require(chaseModule)
local StateMachine = require(stateMachineModule)

local function montarMapa(seed: number): (Folder, { Zones.Zona }, Model)
    local labirintoExistente = workspace:FindFirstChild("Labirinto")
    if labirintoExistente ~= nil then
        labirintoExistente:Destroy()
    end

    local baseplate = workspace:FindFirstChild("Baseplate")
    if baseplate ~= nil then
        baseplate:Destroy()
    end
    local spawnPadrao = workspace:FindFirstChild("SpawnLocation")
    if spawnPadrao ~= nil then
        spawnPadrao:Destroy()
    end

    local grade = MazeGenerator.gerar(Config.Maze.Rows, Config.Maze.Columns, seed)
    local mapa = MazeBuilder.construir(grade, workspace)
    local zonas = Zones.criar(mapa, grade)
    local sala = GoalRoom.criar(mapa, grade)

    return mapa, zonas, sala
end

local function obterJogadorVisivel(guarda: Model): Player?
    local raizGuarda = guarda:FindFirstChild("HumanoidRootPart")
    if raizGuarda == nil or not raizGuarda:IsA("BasePart") then
        return nil
    end

    local maisProximo: Player? = nil
    local menorDistancia = math.huge
    for _, jogador in Players:GetPlayers() do
        if Vision.detectar(guarda, jogador) then
            local personagem = jogador.Character
            local raizJogador = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
            if raizJogador ~= nil and raizJogador:IsA("BasePart") then
                local distancia = (raizJogador.Position - raizGuarda.Position).Magnitude
                if distancia < menorDistancia then
                    menorDistancia = distancia
                    maisProximo = jogador
                end
            end
        end
    end

    return maisProximo
end

local function procurarUltimoPonto(guarda: Model, token: number, obterToken: () -> number): ()
    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raiz = guarda:FindFirstChild("HumanoidRootPart")
    local destino = guarda:GetAttribute("UltimoPontoVisto")
    if humanoide == nil or raiz == nil or not raiz:IsA("BasePart") or typeof(destino) ~= "Vector3" then
        return
    end

    local caminho = PathfindingService:CreatePath()
    local calculado = pcall(function()
        caminho:ComputeAsync(raiz.Position, destino)
    end)
    if not calculado or caminho.Status ~= Enum.PathStatus.Success then
        caminho:Destroy()
        return
    end

    for _, waypoint in caminho:GetWaypoints() do
        if obterToken() ~= token or guarda.Parent == nil or guarda:GetAttribute("EstadoGuarda") ~= "Busca" then
            break
        end
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoide.Jump = true
        end
        humanoide:MoveTo(waypoint.Position)
        if not humanoide.MoveToFinished:Wait() then
            break
        end
    end

    caminho:Destroy()
end

local function iniciarControleDoGuarda(guarda: Model, mapa: Folder): ()
    Capture.inicializar(guarda)
    Patrol.iniciar(guarda, mapa)
    StateMachine.inicializar(guarda)

    local estadoAnterior = "Patrulha"
    local alvoAtual: Player? = nil
    local tokenBusca = 0

    task.spawn(function()
        while guarda.Parent ~= nil do
            local estado = guarda:GetAttribute("EstadoGuarda")
            if typeof(estado) ~= "string" then
                estado = "Patrulha"
            end

            if estado == "Patrulha" then
                Chase.parar(guarda)
                alvoAtual = nil
                if estadoAnterior ~= "Patrulha" then
                    Patrol.iniciar(guarda, mapa)
                end
            elseif estado == "Suspeito" then
                Patrol.parar(guarda)
                Chase.parar(guarda)
                alvoAtual = nil
            elseif estado == "Perseguição" then
                Patrol.parar(guarda)
                local alvo = obterJogadorVisivel(guarda)
                if alvo ~= nil and alvo ~= alvoAtual then
                    Chase.iniciar(guarda, alvo)
                    alvoAtual = alvo
                elseif alvo == nil then
                    Chase.parar(guarda)
                    alvoAtual = nil
                end
            elseif estado == "Busca" then
                Chase.parar(guarda)
                alvoAtual = nil
                if estadoAnterior ~= "Busca" then
                    tokenBusca += 1
                    local token = tokenBusca
                    task.spawn(function()
                        procurarUltimoPonto(guarda, token, function()
                            return tokenBusca
                        end)
                    end)
                end
            end

            if estadoAnterior == "Busca" and estado ~= "Busca" then
                tokenBusca += 1
            end
            estadoAnterior = estado
            task.wait(Config.Timing.GuardRepathInterval)
        end

        Chase.parar(guarda)
        Patrol.parar(guarda)
        tokenBusca += 1
    end)
end

local function afastarGuardaDoCheckpoint(guarda: Model, zona: Zones.Zona): ()
    local checkpoint: BasePart? = nil
    for _, objeto in zona.Pasta:GetDescendants() do
        if objeto:IsA("BasePart") and objeto:GetAttribute("PontoCheckpoint") == true then
            checkpoint = objeto
            break
        end
    end

    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raiz = guarda:FindFirstChild("HumanoidRootPart")
    if checkpoint == nil or humanoide == nil or raiz == nil or not raiz:IsA("BasePart") then
        return
    end

    local melhorPiso: BasePart? = nil
    local maiorDistancia = Config.Maze.CellSize * 4
    for _, objeto in zona.Pasta:GetDescendants() do
        if objeto:IsA("BasePart") and string.match(objeto.Name, "^Piso_%d+_%d+$") then
            local distancia = (objeto.Position - checkpoint.Position).Magnitude
            if distancia > maiorDistancia then
                maiorDistancia = distancia
                melhorPiso = objeto
            end
        end
    end

    if melhorPiso ~= nil then
        local alturaRaiz = humanoide.HipHeight + raiz.Size.Y / 2
        local posicao = melhorPiso.Position + Vector3.new(0, melhorPiso.Size.Y / 2 + alturaRaiz, 0)
        guarda:PivotTo(CFrame.new(posicao))
    end
end

local function aoColetarPista(jogador: Player, pistaId: string): ()
    Inventory.adicionarPista(jogador, pistaId)
end

local function iniciarPartida(seed: number, primeiroInicio: boolean): ()
    local mapa, zonas, sala = montarMapa(seed)
    if primeiroInicio then
        Inventory.inicializar()
        Checkpoints.inicializar(zonas)
        HideSpots.inicializar(zonas)
        Clues.inicializar(zonas, aoColetarPista)
        Janitor.inicializar(zonas)
    else
        Inventory.resetarTodos()
        Checkpoints.reiniciar(zonas)
        HideSpots.reiniciar(zonas)
        Clues.reiniciar(zonas, aoColetarPista)
        Janitor.reiniciar(zonas)
    end
    Progress.inicializar(sala)

    local zonaInicial = zonas[1]
    assert(zonaInicial ~= nil, "A primeira zona do labirinto precisa existir")
    local guarda = GuardSpawn.criar(zonaInicial)
    afastarGuardaDoCheckpoint(guarda, zonaInicial)
    iniciarControleDoGuarda(guarda, mapa)

    if not primeiroInicio then
        for _, jogador in Players:GetPlayers() do
            local checkpoint = Checkpoints.obter(jogador)
            local personagem = jogador.Character
            if checkpoint ~= nil and personagem ~= nil then
                personagem:PivotTo(checkpoint)
                jogador:SetAttribute("UltimoCheckpoint", zonaInicial.Nome)
            end
        end
    end
end

local eventoReinicio = Instance.new("BindableEvent")
eventoReinicio.Name = "ReinicioSolicitado"
eventoReinicio.Parent = serverFolder
eventoReinicio.Event:Connect(function(_jogador: Player, novaSeed: number)
    iniciarPartida(novaSeed, false)
end)

Remotes.inicializar()
iniciarPartida(Config.Maze.Seed, true)
