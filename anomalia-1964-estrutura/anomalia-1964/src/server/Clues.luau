--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local clueDataModule = sharedFolder:WaitForChild("ClueData") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local ClueData = require(clueDataModule)
local Config = require(configModule)

local interactModule = script.Parent:WaitForChild("Interact") :: ModuleScript
local zonesModule = script.Parent:WaitForChild("Zones") :: ModuleScript
local Interact = require(interactModule)
local Zones = require(zonesModule)

type Pista = ClueData.Pista
type Zona = Zones.Zona

local Clues = {}
local coletadasPorJogador: { [number]: { [string]: boolean } } = {}
local inicializado = false

local function encontrarZona(zonas: { Zona }, nome: string): Zona?
    for _, zona in zonas do
        if zona.Nome == nome then
            return zona
        end
    end

    return nil
end

local function criarPista(zona: Zona, pista: Pista, aoColetar: (Player, string) -> ()): ()
    local linha = pista.Celula.X
    local coluna = pista.Celula.Y
    if
        linha < zona.LinhaInicial
        or linha > zona.LinhaFinal
        or coluna < zona.ColunaInicial
        or coluna > zona.ColunaFinal
    then
        warn(`A pista {pista.Id} está fora dos limites da zona {zona.Nome}.`)
        return
    end

    local nomePiso = string.format("Piso_%d_%d", linha, coluna)
    local piso = zona.Pasta:FindFirstChild(nomePiso)
    if piso == nil or not piso:IsA("BasePart") then
        warn(`Não foi encontrado piso para a pista {pista.Id}.`)
        return
    end

    local tamanho = Config.Maze.WallThickness
    local objeto = Instance.new("Part")
    objeto.Name = `Pista_{pista.Id}`
    objeto.Shape = Enum.PartType.Ball
    objeto.Size = Vector3.one * tamanho
    objeto.Position = piso.Position + Vector3.new(0, piso.Size.Y / 2 + tamanho / 2, 0)
    objeto.Anchored = true
    objeto.CanCollide = false
    objeto.Color = Color3.fromRGB(225, 190, 96)
    objeto.Material = Enum.Material.Neon
    objeto:SetAttribute("PistaId", pista.Id)
    objeto:SetAttribute("TextoPista", pista.Texto)
    objeto.Parent = zona.Pasta

    Interact.criar(objeto, "Investigar", function(jogador: Player)
        local idJogador = jogador.UserId
        local coletadas = coletadasPorJogador[idJogador]
        if coletadas == nil then
            coletadas = {}
            coletadasPorJogador[idJogador] = coletadas
        end

        if coletadas[pista.Id] == true then
            return
        end

        coletadas[pista.Id] = true
        aoColetar(jogador, pista.Id)
    end)
end

function Clues.reiniciar(zonas: { Zona }, aoColetar: (Player, string) -> ()): ()
    assert(#zonas == Config.Zones.Count, "O número de zonas não corresponde à configuração")
    table.clear(coletadasPorJogador)

    local contagemPorZona: { [string]: number } = {}
    local ids: { [string]: boolean } = {}
    for _, pista in ClueData.obterTodas() do
        assert(ids[pista.Id] ~= true, `ID de pista duplicado: {pista.Id}`)
        ids[pista.Id] = true

        local zona = encontrarZona(zonas, pista.Zona)
        assert(zona ~= nil, `A zona da pista {pista.Id} não existe`)
        local zonaValida = zona :: Zona
        contagemPorZona[zonaValida.Nome] = (contagemPorZona[zonaValida.Nome] or 0) + 1
        criarPista(zonaValida, pista, aoColetar)
    end

    for _, zona in zonas do
        local quantidade = contagemPorZona[zona.Nome] or 0
        assert(quantidade >= 2 and quantidade <= 3, `A zona {zona.Nome} precisa ter de 2 a 3 pistas`)
    end
end

function Clues.inicializar(zonas: { Zona }, aoColetar: (Player, string) -> ()): ()
    if inicializado then
        return
    end
    inicializado = true
    Players.PlayerRemoving:Connect(function(jogador: Player)
        coletadasPorJogador[jogador.UserId] = nil
    end)
    Clues.reiniciar(zonas, aoColetar)
end

return Clues
