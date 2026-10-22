--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local zonesModule = script.Parent:WaitForChild("Zones") :: ModuleScript
local configModule = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript
local Zones = require(zonesModule)
local Config = require(configModule)

local HideSpots = {}

type Zona = Zones.Zona
type Esconderijo = {
    Modelo: Model,
    PosicaoInterior: CFrame,
    PosicaoSaida: CFrame,
    Ocupante: Player?,
}
type EstadoJogador = {
    Esconderijo: Esconderijo,
    Personagem: Model,
    ColisoesOriginais: { [BasePart]: boolean },
    ConexaoRemocao: RBXScriptConnection,
}

local estadoPorJogador: { [Player]: EstadoJogador } = {}
local inicializado = false

local function criarPeca(parent: Instance, nome: string, tamanho: Vector3, cframe: CFrame, visivel: boolean): BasePart
    local parte = Instance.new("Part")
    parte.Name = nome
    parte.Anchored = true
    parte.CanCollide = true
    parte.CanQuery = true
    parte.Size = tamanho
    parte.CFrame = cframe
    parte.Material = Enum.Material.Wood
    parte.Color = Color3.fromRGB(92, 63, 43)
    parte.Transparency = if visivel then 0 else 1
    parte.Parent = parent
    return parte
end

local function criarEsconderijo(zona: Zona): Esconderijo?
    local linha = math.floor((zona.LinhaInicial + zona.LinhaFinal) / 2)
    local coluna = math.floor((zona.ColunaInicial + zona.ColunaFinal) / 2)
    local nomePiso = string.format("Piso_%d_%d", linha, coluna)
    local piso = zona.Pasta:FindFirstChild(nomePiso)
    if piso == nil or not piso:IsA("BasePart") then
        warn(`Não foi possível criar esconderijo na zona {zona.Nome}: piso central ausente.`)
        return nil
    end

    local celula = Config.Maze.CellSize
    local largura = celula * 0.3
    local profundidade = celula * 0.34
    local altura = math.min(Config.Maze.WallHeight * 0.65, celula * 0.55)
    local centro = piso.Position + Vector3.new(celula * 0.34, altura / 2, 0)
    local modelo = Instance.new("Model")
    modelo.Name = `Esconderijo_{zona.Nome}`
    modelo:SetAttribute("TipoEsconderijo", "Armario")
    modelo.Parent = zona.Pasta

    local meio = CFrame.new(centro)
    criarPeca(
        modelo,
        "ParedeEsquerda",
        Vector3.new(1, altura, profundidade),
        meio * CFrame.new(-largura / 2, 0, 0),
        true
    )
    criarPeca(modelo, "ParedeDireita", Vector3.new(1, altura, profundidade), meio * CFrame.new(largura / 2, 0, 0), true)
    criarPeca(modelo, "Fundo", Vector3.new(largura, altura, 1), meio * CFrame.new(0, 0, -profundidade / 2), true)
    criarPeca(modelo, "Porta", Vector3.new(largura, altura, 1), meio * CFrame.new(0, 0, profundidade / 2), true)
    criarPeca(modelo, "Teto", Vector3.new(largura, 1, profundidade), meio * CFrame.new(0, altura / 2, 0), true)

    local ancoraEntrada = criarPeca(
        modelo,
        "AncoraEntrada",
        Vector3.one,
        CFrame.new(centro + Vector3.new(0, 0, profundidade / 2 + 1)),
        false
    )
    ancoraEntrada.CanCollide = false
    ancoraEntrada.CanQuery = false
    ancoraEntrada.CanTouch = false

    local promptEntrada = Instance.new("ProximityPrompt")
    promptEntrada.Name = "Entrar"
    promptEntrada.ActionText = "Esconder-se"
    promptEntrada.ObjectText = "Armário"
    promptEntrada.RequiresLineOfSight = false
    promptEntrada.Parent = ancoraEntrada

    local ancoraSaida = criarPeca(modelo, "AncoraSaida", Vector3.one, meio, false)
    ancoraSaida.CanCollide = false
    ancoraSaida.CanQuery = false
    ancoraSaida.CanTouch = false
    local promptSaida = Instance.new("ProximityPrompt")
    promptSaida.Name = "Sair"
    promptSaida.ActionText = "Sair do esconderijo"
    promptSaida.ObjectText = "Armário"
    promptSaida.RequiresLineOfSight = false
    promptSaida.Parent = ancoraSaida

    return {
        Modelo = modelo,
        PosicaoInterior = CFrame.new(centro + Vector3.new(0, -altura / 2 + 2, 0)),
        PosicaoSaida = CFrame.new(centro + Vector3.new(0, -altura / 2 + 3, profundidade / 2 + 3)),
        Ocupante = nil,
    }
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

local function sair(jogador: Player, teleportar: boolean): ()
    local estado = estadoPorJogador[jogador]
    if estado == nil then
        return
    end

    estadoPorJogador[jogador] = nil
    estado.Esconderijo.Ocupante = nil
    if estado.ConexaoRemocao.Connected then
        estado.ConexaoRemocao:Disconnect()
    end
    for parte, podeColidir in estado.ColisoesOriginais do
        if parte.Parent ~= nil then
            parte.CanCollide = podeColidir
        end
    end
    estado.Personagem:SetAttribute("Escondido", false)
    jogador:SetAttribute("Escondido", false)
    if teleportar and estado.Personagem.Parent ~= nil then
        estado.Personagem:PivotTo(estado.Esconderijo.PosicaoSaida)
    end
end

local function entrar(esconderijo: Esconderijo, jogador: Player, ancora: BasePart, prompt: ProximityPrompt): ()
    local personagem, humanoide, raiz = obterPersonagem(jogador)
    if
        jogador.Parent ~= Players
        or personagem == nil
        or humanoide == nil
        or humanoide.Health <= 0
        or raiz == nil
        or esconderijo.Ocupante ~= nil
        or estadoPorJogador[jogador] ~= nil
        or (raiz.Position - ancora.Position).Magnitude > prompt.MaxActivationDistance + 2
    then
        return
    end

    local colisoesOriginais: { [BasePart]: boolean } = {}
    for _, objeto in personagem:GetDescendants() do
        if objeto:IsA("BasePart") then
            colisoesOriginais[objeto] = objeto.CanCollide
            objeto.CanCollide = false
        end
    end

    esconderijo.Ocupante = jogador
    local estado: EstadoJogador = {
        Esconderijo = esconderijo,
        Personagem = personagem,
        ColisoesOriginais = colisoesOriginais,
        ConexaoRemocao = personagem.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                sair(jogador, false)
            end
        end),
    }
    estadoPorJogador[jogador] = estado
    personagem:SetAttribute("Escondido", true)
    jogador:SetAttribute("Escondido", true)
    personagem:PivotTo(esconderijo.PosicaoInterior)
end

local function conectarPrompts(esconderijo: Esconderijo): ()
    local entrada = esconderijo.Modelo:FindFirstChild("Entrar", true)
    local saida = esconderijo.Modelo:FindFirstChild("Sair", true)
    local ancoraEntrada = esconderijo.Modelo:FindFirstChild("AncoraEntrada")
    local ancoraSaida = esconderijo.Modelo:FindFirstChild("AncoraSaida")
    assert(entrada ~= nil and entrada:IsA("ProximityPrompt"), "Prompt de entrada ausente")
    assert(saida ~= nil and saida:IsA("ProximityPrompt"), "Prompt de saída ausente")
    assert(ancoraEntrada ~= nil and ancoraEntrada:IsA("BasePart"), "Âncora de entrada ausente")
    assert(ancoraSaida ~= nil and ancoraSaida:IsA("BasePart"), "Âncora de saída ausente")

    entrada.Triggered:Connect(function(jogador)
        entrar(esconderijo, jogador, ancoraEntrada, entrada)
    end)
    saida.Triggered:Connect(function(jogador)
        local estado = estadoPorJogador[jogador]
        local _, humanoide, raiz = obterPersonagem(jogador)
        if
            estado ~= nil
            and estado.Esconderijo == esconderijo
            and humanoide ~= nil
            and humanoide.Health > 0
            and raiz ~= nil
            and (raiz.Position - ancoraSaida.Position).Magnitude <= saida.MaxActivationDistance + 2
        then
            sair(jogador, true)
        end
    end)
end

function HideSpots.reiniciar(zonas: { Zona }): ()
    assert(#zonas > 0, "É necessário fornecer ao menos uma zona para criar esconderijos")
    for jogador in estadoPorJogador do
        sair(jogador, false)
    end

    for _, zona in zonas do
        local esconderijo = criarEsconderijo(zona)
        if esconderijo ~= nil then
            conectarPrompts(esconderijo)
        end
    end
end

function HideSpots.inicializar(zonas: { Zona }): ()
    if inicializado then
        return
    end
    HideSpots.reiniciar(zonas)
    inicializado = true
    Players.PlayerRemoving:Connect(function(jogador)
        sair(jogador, false)
    end)
end

function HideSpots.estaEscondido(jogador: Player): boolean
    return estadoPorJogador[jogador] ~= nil
end

return HideSpots
