--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local MazeGrid = require(mazeGridModule)
local Config = require(configModule)

local GoalRoom = {}

type Grade = MazeGrid.Grade

local function criarPeca(
    modelo: Model,
    nome: string,
    tamanho: Vector3,
    posicao: Vector3,
    material: Enum.Material,
    cor: Color3
): Part
    local parte = Instance.new("Part")
    parte.Name = nome
    parte.Anchored = true
    parte.CanCollide = true
    parte.Size = tamanho
    parte.Position = posicao
    parte.Material = material
    parte.Color = cor
    parte.TopSurface = Enum.SurfaceType.Smooth
    parte.BottomSurface = Enum.SurfaceType.Smooth
    parte.Parent = modelo
    return parte
end

function GoalRoom.criar(mapa: Folder, grade: Grade): Model
    local salaExistente = mapa:FindFirstChild("Sala 214")
    if salaExistente ~= nil then
        assert(salaExistente:IsA("Model"), "O nome Sala 214 já está sendo usado por outro objeto")
        return salaExistente
    end

    assert(grade.Linhas > 0 and grade.Colunas > 0, "A grade precisa ter linhas e colunas")

    local configLabirinto = Config.Maze
    local tamanhoCelula = configLabirinto.CellSize
    local alturaParede = configLabirinto.WallHeight
    local espessuraParede = configLabirinto.WallThickness
    local espessuraPiso = configLabirinto.FloorThickness
    local larguraLabirinto = grade.Colunas * tamanhoCelula
    local profundidadeLabirinto = grade.Linhas * tamanhoCelula
    local centroX = (grade.Colunas - 0.5) * tamanhoCelula - larguraLabirinto / 2
    local centroZ = (grade.Linhas - 0.5) * tamanhoCelula - profundidadeLabirinto / 2
    local limiteSul = centroZ + tamanhoCelula / 2
    local centroSalaZ = limiteSul + tamanhoCelula / 2
    local larguraPorta = tamanhoCelula / 3
    local alturaPorta = alturaParede * 0.75
    local larguraTrechoParede = (tamanhoCelula + espessuraParede * 2 - larguraPorta) / 2
    local modelo = Instance.new("Model")
    modelo.Name = "Sala 214"
    modelo:SetAttribute("SalaFinal", true)
    modelo:SetAttribute("Linha", grade.Linhas)
    modelo:SetAttribute("Coluna", grade.Colunas)

    local nomeParedeSul = string.format("ParedeSul_%d_%d", grade.Linhas, grade.Colunas)
    local paredeSul = mapa:FindFirstChild(nomeParedeSul, true)
    if paredeSul ~= nil then
        assert(paredeSul:IsA("BasePart"), "A parede sul da última célula precisa ser uma peça")
        paredeSul:Destroy()
    end

    local materialConcreto = Enum.Material.Concrete
    local corParede = Color3.fromRGB(112, 108, 101)
    local corPiso = Color3.fromRGB(92, 86, 76)
    local corPorta = Color3.fromRGB(92, 57, 37)

    criarPeca(
        modelo,
        "Piso",
        Vector3.new(tamanhoCelula, espessuraPiso, tamanhoCelula),
        Vector3.new(centroX, -espessuraPiso / 2, centroSalaZ),
        materialConcreto,
        corPiso
    )
    criarPeca(
        modelo,
        "Teto",
        Vector3.new(tamanhoCelula, espessuraPiso, tamanhoCelula),
        Vector3.new(centroX, alturaParede + espessuraPiso / 2, centroSalaZ),
        materialConcreto,
        corParede
    )
    criarPeca(
        modelo,
        "ParedeOeste",
        Vector3.new(espessuraParede, alturaParede, tamanhoCelula),
        Vector3.new(centroX - tamanhoCelula / 2, alturaParede / 2, centroSalaZ),
        materialConcreto,
        corParede
    )
    criarPeca(
        modelo,
        "ParedeLeste",
        Vector3.new(espessuraParede, alturaParede, tamanhoCelula),
        Vector3.new(centroX + tamanhoCelula / 2, alturaParede / 2, centroSalaZ),
        materialConcreto,
        corParede
    )
    criarPeca(
        modelo,
        "ParedeFundo",
        Vector3.new(tamanhoCelula + espessuraParede * 2, alturaParede, espessuraParede),
        Vector3.new(centroX, alturaParede / 2, centroSalaZ + tamanhoCelula / 2),
        materialConcreto,
        corParede
    )

    local deslocamentoTrecho = larguraPorta / 2 + larguraTrechoParede / 2
    for _, lado in { -1, 1 } do
        criarPeca(
            modelo,
            "ParedeEntrada" .. tostring(lado),
            Vector3.new(larguraTrechoParede, alturaParede, espessuraParede),
            Vector3.new(centroX + lado * deslocamentoTrecho, alturaParede / 2, limiteSul),
            materialConcreto,
            corParede
        )
    end
    criarPeca(
        modelo,
        "VergaEntrada",
        Vector3.new(larguraPorta, alturaParede - alturaPorta, espessuraParede),
        Vector3.new(centroX, (alturaParede + alturaPorta) / 2, limiteSul),
        materialConcreto,
        corParede
    )

    local porta = criarPeca(
        modelo,
        "PortaFinal",
        Vector3.new(larguraPorta, alturaPorta, espessuraParede),
        Vector3.new(centroX, alturaPorta / 2, limiteSul),
        Enum.Material.Wood,
        corPorta
    )
    porta:SetAttribute("PortaFinal", true)
    porta:SetAttribute("SalaFinal", "Sala 214")
    porta:SetAttribute("ProgressaoValidadaPeloServidor", false)
    modelo.PrimaryPart = porta
    modelo.Parent = mapa

    return modelo
end

return GoalRoom
