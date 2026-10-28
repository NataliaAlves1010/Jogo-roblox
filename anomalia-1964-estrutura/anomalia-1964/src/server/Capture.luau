--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local serverFolder = script.Parent
local guardFolder = serverFolder:WaitForChild("Guard")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local checkpointsModule = serverFolder:WaitForChild("Checkpoints") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local chaseModule = guardFolder:WaitForChild("Chase") :: ModuleScript
local patrolModule = guardFolder:WaitForChild("Patrol") :: ModuleScript
local Checkpoints = require(checkpointsModule)
local Config = require(configModule)
local Chase = require(chaseModule)
local Patrol = require(patrolModule)

local Capture = {}
local prisioneiros: { [Player]: number } = {}
local humanoidesOriginais: { [Humanoid]: { Velocidade: number, Pulo: number, AlturaPulo: number, Rotacao: boolean } } =
    {}

type Controle = {
    Conexoes: { RBXScriptConnection },
    ContatoValidado: { [Player]: boolean },
    EmCaptura: boolean,
}

local controles: { [Model]: Controle } = {}

local function criarPecaPrisao(
    nome: string,
    tamanho: Vector3,
    posicao: Vector3,
    cor: Color3,
    material: Enum.Material
): Part
    local parte = Instance.new("Part")
    parte.Name = nome
    parte.Anchored = true
    parte.CanCollide = true
    parte.CanTouch = false
    parte.Size = tamanho
    parte.Position = posicao
    parte.Color = cor
    parte.Material = material
    parte.TopSurface = Enum.SurfaceType.Smooth
    parte.BottomSurface = Enum.SurfaceType.Smooth
    return parte
end

local function obterCela(): (Folder, CFrame)
    local existente = Workspace:FindFirstChild("PrisaoGuarda")
    if existente ~= nil and existente:IsA("Folder") then
        local pisoExistente = existente:FindFirstChild("Piso")
        if pisoExistente ~= nil and pisoExistente:IsA("BasePart") then
            return existente, pisoExistente.CFrame + Vector3.new(0, 4, 0)
        end
    end

    local cela = Instance.new("Folder")
    cela.Name = "PrisaoGuarda"
    local configuracao = Config.Prison
    local meiaLargura = configuracao.CellWidth / 2
    local meiaProfundidade = configuracao.CellDepth / 2
    local altura = configuracao.WallHeight
    local espessura = configuracao.WallThickness
    local x = Config.Maze.Columns * Config.Maze.CellSize / 2 + configuracao.DistanceFromMaze
    local centro = Vector3.new(x, 0, 0)
    local concreto = Color3.fromRGB(54, 52, 49)
    local metal = Color3.fromRGB(99, 104, 108)
    local piso = criarPecaPrisao(
        "Piso",
        Vector3.new(configuracao.CellWidth, 1, configuracao.CellDepth),
        centro - Vector3.new(0, 0.5, 0),
        Color3.fromRGB(85, 81, 72),
        Enum.Material.Concrete
    )
    piso.Parent = cela

    for _, parede in
        {
            {
                "ParedeFundo",
                Vector3.new(configuracao.CellWidth, altura, espessura),
                centro + Vector3.new(0, altura / 2, -meiaProfundidade),
            },
            {
                "ParedeEsquerda",
                Vector3.new(espessura, altura, configuracao.CellDepth),
                centro + Vector3.new(-meiaLargura, altura / 2, 0),
            },
            {
                "ParedeDireita",
                Vector3.new(espessura, altura, configuracao.CellDepth),
                centro + Vector3.new(meiaLargura, altura / 2, 0),
            },
            {
                "Teto",
                Vector3.new(configuracao.CellWidth, espessura, configuracao.CellDepth),
                centro + Vector3.new(0, altura, 0),
            },
        }
    do
        local parte = criarPecaPrisao(parede[1], parede[2], parede[3], concreto, Enum.Material.Concrete)
        parte.Parent = cela
    end

    local larguraBarra = espessura * 0.45
    for indice = 0, configuracao.BarCount do
        local deslocamento = -meiaLargura + (configuracao.CellWidth * indice / configuracao.BarCount)
        local barra = criarPecaPrisao(
            string.format("Grade_%02d", indice + 1),
            Vector3.new(larguraBarra, altura, larguraBarra),
            centro + Vector3.new(deslocamento, altura / 2, meiaProfundidade),
            metal,
            Enum.Material.Metal
        )
        barra.Parent = cela
    end

    cela.Parent = Workspace
    return cela, piso.CFrame + Vector3.new(0, 4, 0)
end

local function confinar(personagem: Model, destino: CFrame): ()
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if humanoide == nil or raiz == nil or not raiz:IsA("BasePart") then
        return
    end

    if humanoidesOriginais[humanoide] == nil then
        humanoidesOriginais[humanoide] = {
            Velocidade = humanoide.WalkSpeed,
            Pulo = humanoide.JumpPower,
            AlturaPulo = humanoide.JumpHeight,
            Rotacao = humanoide.AutoRotate,
        }
    end
    humanoide.WalkSpeed = 0
    humanoide.JumpPower = 0
    humanoide.JumpHeight = 0
    humanoide.AutoRotate = false
    humanoide:ChangeState(Enum.HumanoidStateType.Physics)
    raiz.AssemblyLinearVelocity = Vector3.zero
    raiz.AssemblyAngularVelocity = Vector3.zero
    raiz.CFrame = destino
    raiz.Anchored = true
end

local function libertar(personagem: Model): ()
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if raiz ~= nil and raiz:IsA("BasePart") then
        raiz.Anchored = false
    end
    if humanoide ~= nil then
        local original = humanoidesOriginais[humanoide]
        humanoide.WalkSpeed = if original ~= nil then original.Velocidade else Config.Movement.PlayerWalkSpeed
        humanoide.JumpPower = if original ~= nil then original.Pulo else humanoide.JumpPower
        humanoide.JumpHeight = if original ~= nil then original.AlturaPulo else humanoide.JumpHeight
        humanoide.AutoRotate = if original ~= nil then original.Rotacao else true
        humanoide:ChangeState(Enum.HumanoidStateType.Running)
        humanoidesOriginais[humanoide] = nil
    end
end

local function obterPersonagem(jogador: Player): (Model?, Humanoid?, BasePart?)
    local personagem = jogador.Character
    if personagem == nil then
        return nil, nil, nil
    end

    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if humanoide == nil or raiz == nil or not raiz:IsA("BasePart") then
        return personagem, nil, nil
    end

    return personagem, humanoide, raiz
end

local function reiniciarPatrulha(guarda: Model)
    local zona = guarda.Parent
    local mapa = if zona ~= nil then zona.Parent else nil
    if mapa ~= nil and mapa:IsA("Folder") and guarda.Parent ~= nil then
        Patrol.iniciar(guarda, mapa)
    end
end

function Capture.capturar(guarda: Model, jogador: Player): ()
    local controle = controles[guarda]
    if
        controle == nil
        or controle.EmCaptura
        or prisioneiros[jogador] ~= nil
        or controle.ContatoValidado[jogador] ~= true
    then
        return
    end

    local personagem, humanoide, raiz = obterPersonagem(jogador)
    local humanoideGuarda = guarda:FindFirstChildOfClass("Humanoid")
    if
        jogador.Parent ~= Players
        or personagem == nil
        or humanoide == nil
        or humanoide.Health <= 0
        or raiz == nil
        or humanoideGuarda == nil
        or humanoideGuarda.Health <= 0
    then
        return
    end

    local checkpoint = Checkpoints.obter(jogador)
    if checkpoint == nil then
        warn("A captura foi ignorada porque o jogador ainda não tem checkpoint inicializado.")
        return
    end

    controle.EmCaptura = true
    local _, destinoPrisao = obterCela()
    local terminoPrisao = Workspace:GetServerTimeNow() + Config.Timing.PrisonDuration
    prisioneiros[jogador] = terminoPrisao
    jogador:SetAttribute("PresoAte", terminoPrisao)
    Chase.parar(guarda)
    Patrol.parar(guarda)
    confinar(personagem, destinoPrisao)

    local conexaoRenascimento = jogador.CharacterAdded:Connect(function(novoPersonagem)
        task.spawn(function()
            local humanoideNovo = novoPersonagem:WaitForChild("Humanoid", 10)
            local raizNova = novoPersonagem:WaitForChild("HumanoidRootPart", 10)
            if
                prisioneiros[jogador] == terminoPrisao
                and Workspace:GetServerTimeNow() < terminoPrisao
                and humanoideNovo ~= nil
                and raizNova ~= nil
                and humanoideNovo:IsA("Humanoid")
                and raizNova:IsA("BasePart")
            then
                confinar(novoPersonagem, destinoPrisao)
            end
        end)
    end)

    task.delay(Config.Timing.PrisonDuration, function()
        prisioneiros[jogador] = nil
        jogador:SetAttribute("PresoAte", nil)
        conexaoRenascimento:Disconnect()
        if jogador.Parent == Players then
            local personagemAtual, humanoideAtual, raizAtual = obterPersonagem(jogador)
            local checkpointAtual = Checkpoints.obter(jogador)
            if personagemAtual ~= nil and humanoideAtual ~= nil and raizAtual ~= nil and checkpointAtual ~= nil then
                raizAtual.Anchored = false
                personagemAtual:PivotTo(checkpointAtual)
                raizAtual.AssemblyLinearVelocity = Vector3.zero
                raizAtual.AssemblyAngularVelocity = Vector3.zero
                libertar(personagemAtual)
            end
        end

        if humanoideGuarda ~= nil and humanoideGuarda.Health > 0 and guarda.Parent ~= nil then
            guarda:SetAttribute("EstadoGuarda", "Patrulha")
            guarda:SetAttribute("UltimoPontoVisto", nil)
            reiniciarPatrulha(guarda)
        end
        controle.EmCaptura = false
    end)
end

function Capture.inicializar(guarda: Model): ()
    if controles[guarda] ~= nil then
        return
    end

    local controle: Controle = {
        Conexoes = {},
        ContatoValidado = {},
        EmCaptura = false,
    }
    controles[guarda] = controle

    for _, parte in guarda:GetDescendants() do
        if parte:IsA("BasePart") and parte.CanTouch then
            table.insert(
                controle.Conexoes,
                parte.Touched:Connect(function(parteTocada)
                    local personagem = parteTocada:FindFirstAncestorOfClass("Model")
                    if personagem == nil then
                        return
                    end

                    local jogador = Players:GetPlayerFromCharacter(personagem)
                    if jogador == nil then
                        return
                    end

                    controle.ContatoValidado[jogador] = true
                    Capture.capturar(guarda, jogador)
                    controle.ContatoValidado[jogador] = nil
                end)
            )
        end
    end

    table.insert(
        controle.Conexoes,
        guarda.Destroying:Connect(function()
            for _, conexao in controle.Conexoes do
                conexao:Disconnect()
            end
            controles[guarda] = nil
        end)
    )
end

return Capture
