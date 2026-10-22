--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local dialogueDataModule = sharedFolder:WaitForChild("DialogueData") :: ModuleScript
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Config = require(configModule)
local DialogueData = require(dialogueDataModule)
local Types = require(typesModule)

local serverFolder = script.Parent
local interactModule = serverFolder:WaitForChild("Interact") :: ModuleScript
local inventoryModule = serverFolder:WaitForChild("Inventory") :: ModuleScript
local zonesModule = serverFolder:WaitForChild("Zones") :: ModuleScript
local Interact = require(interactModule)
local Inventory = require(inventoryModule)
local Zones = require(zonesModule)

type Zona = Zones.Zona
type NomeZona = Types.NomeZona

local Janitor = {}
local remotoDialogo: RemoteEvent? = nil
local inicializado = false

local NOMES_ZONAS: { [string]: boolean } = {
    ["Recepção"] = true,
    Arquivo = true,
    Subsolo = true,
    Gabinete = true,
}

local PISTA_RECOMPENSA = "registro_plantao"
local CHAVE_RECOMPENSA = "chave_gabinete"

local function criarParte(modelo: Model, nome: string, tamanho: Vector3, posicao: Vector3, cor: Color3): BasePart
    local parte = Instance.new("Part")
    parte.Name = nome
    parte.Size = tamanho
    parte.Position = posicao
    parte.Anchored = true
    parte.CanCollide = false
    parte.CanTouch = false
    parte.Color = cor
    parte.Material = Enum.Material.SmoothPlastic
    parte.Parent = modelo
    return parte
end

local function criarFaxineira(zona: Zona): Model
    local linha = math.floor((zona.LinhaInicial + zona.LinhaFinal) / 2)
    local coluna = math.floor((zona.ColunaInicial + zona.ColunaFinal) / 2)
    local nomePiso = string.format("Piso_%d_%d", linha, coluna)
    local piso = zona.Pasta:FindFirstChild(nomePiso)
    assert(piso ~= nil and piso:IsA("BasePart"), `A zona {zona.Nome} precisa de um piso válido`)
    local pisoBase = piso :: BasePart

    local escala = Config.Maze.WallThickness
    local alturaCorpo = escala * 2
    local tamanhoCabeca = Vector3.one * escala
    local origem = pisoBase.Position + Vector3.new(0, pisoBase.Size.Y / 2, 0)
    local modelo = Instance.new("Model")
    modelo.Name = `Faxineira_{zona.Nome}`
    modelo:SetAttribute("Zona", zona.Nome)

    local corpo = criarParte(
        modelo,
        "Corpo",
        Vector3.new(escala * 2, alturaCorpo, escala),
        origem + Vector3.new(0, alturaCorpo / 2, 0),
        Color3.fromRGB(74, 88, 96)
    )
    criarParte(
        modelo,
        "Cabeca",
        tamanhoCabeca,
        origem + Vector3.new(0, alturaCorpo + tamanhoCabeca.Y / 2, 0),
        Color3.fromRGB(207, 168, 137)
    )
    criarParte(
        modelo,
        "Cabelo",
        Vector3.new(tamanhoCabeca.X, escala / 3, tamanhoCabeca.Z),
        origem + Vector3.new(0, alturaCorpo + tamanhoCabeca.Y + escala / 6, 0),
        Color3.fromRGB(93, 83, 76)
    )
    modelo.PrimaryPart = corpo
    modelo.Parent = zona.Pasta

    Interact.criar(corpo, "Conversar", function(jogador: Player)
        Janitor.conversar(jogador, modelo)
    end)

    return modelo
end

function Janitor.recompensar(jogador: Player, faxineira: Model): boolean
    local corpo = faxineira:FindFirstChild("Corpo")
    if corpo == nil or not corpo:IsA("BasePart") or not Interact.distanciaValida(jogador, corpo) then
        return false
    end

    if not Inventory.temPista(jogador, PISTA_RECOMPENSA) or Inventory.temChave(jogador, CHAVE_RECOMPENSA) then
        return false
    end

    return Inventory.adicionarChave(jogador, CHAVE_RECOMPENSA)
end

function Janitor.conversar(jogador: Player, faxineira: Model): boolean
    local corpo = faxineira:FindFirstChild("Corpo")
    local zona = faxineira:GetAttribute("Zona")
    local remoto = remotoDialogo
    if
        corpo == nil
        or not corpo:IsA("BasePart")
        or typeof(zona) ~= "string"
        or NOMES_ZONAS[zona] ~= true
        or remoto == nil
    then
        return false
    end

    if not Interact.distanciaValida(jogador, corpo) then
        return false
    end

    local fala: DialogueData.Fala
    if Janitor.recompensar(jogador, faxineira) then
        fala = DialogueData.obterConfirmacaoRecompensa()
    else
        local pistas = Inventory.obter(jogador).Pistas
        if Inventory.temChave(jogador, CHAVE_RECOMPENSA) then
            for indice, id in pistas do
                if id == PISTA_RECOMPENSA then
                    table.remove(pistas, indice)
                    break
                end
            end
        end
        fala = DialogueData.obterFala(zona :: NomeZona, pistas)
    end

    remoto:FireClient(jogador, fala)
    return true
end

function Janitor.reiniciar(zonas: { Zona }): ()
    assert(#zonas == Config.Zones.Count, "O número de zonas não corresponde à configuração")
    for _, zona in zonas do
        criarFaxineira(zona)
    end
end

function Janitor.inicializar(zonas: { Zona }): ()
    if inicializado then
        return
    end
    assert(#zonas == Config.Zones.Count, "O número de zonas não corresponde à configuração")

    local remotesFolder = ReplicatedStorage:WaitForChild("Remotos")
    local remoto = remotesFolder:WaitForChild("DialogoAtualizado")
    assert(remoto:IsA("RemoteEvent"), "DialogoAtualizado precisa ser um RemoteEvent")
    remotoDialogo = remoto

    Janitor.reiniciar(zonas)
    inicializado = true
end

return Janitor
