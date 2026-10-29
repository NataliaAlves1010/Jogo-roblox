--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local collisionGroupsModule = script.Parent:WaitForChild("CollisionGroups") :: ModuleScript
local MazeGrid = require(mazeGridModule)
local Config = require(configModule)
local CollisionGroups = require(collisionGroupsModule)

local MazeBuilder = {}

type Grade = MazeGrid.Grade

local function criarPeca(folder: Folder, nome: string, tamanho: Vector3, posicao: Vector3)
    local parte = Instance.new("Part")
    parte.Name = nome
    parte.Anchored = true
    parte.CanCollide = true
    parte.Size = tamanho
    parte.Position = posicao
    parte.TopSurface = Enum.SurfaceType.Smooth
    parte.BottomSurface = Enum.SurfaceType.Smooth
    if string.sub(nome, 1, 6) == "Parede" then
        CollisionGroups.configurarParede(parte)
    end
    parte.Parent = folder
end

function MazeBuilder.construir(grade: Grade, parent: Instance): Folder
    CollisionGroups.inicializar()
    local configLabirinto = Config.Maze
    local tamanhoCelula = configLabirinto.CellSize
    local alturaParede = configLabirinto.WallHeight
    local espessuraParede = configLabirinto.WallThickness
    local espessuraPiso = configLabirinto.FloorThickness
    local largura = grade.Colunas * tamanhoCelula
    local profundidade = grade.Linhas * tamanhoCelula
    local folder = Instance.new("Folder")
    folder.Name = "Labirinto"

    for linha = 1, grade.Linhas do
        for coluna = 1, grade.Colunas do
            local centroX = (coluna - 0.5) * tamanhoCelula - largura / 2
            local centroZ = (linha - 0.5) * tamanhoCelula - profundidade / 2
            local nomeCelula = string.format("_%d_%d", linha, coluna)

            criarPeca(
                folder,
                "Piso" .. nomeCelula,
                Vector3.new(tamanhoCelula, espessuraPiso, tamanhoCelula),
                Vector3.new(centroX, -espessuraPiso / 2, centroZ)
            )
            criarPeca(
                folder,
                "Teto" .. nomeCelula,
                Vector3.new(tamanhoCelula, espessuraPiso, tamanhoCelula),
                Vector3.new(centroX, alturaParede + espessuraPiso / 2, centroZ)
            )

            if MazeGrid.temParede(grade, linha, coluna, "Norte") then
                criarPeca(
                    folder,
                    "ParedeNorte" .. nomeCelula,
                    Vector3.new(tamanhoCelula + espessuraParede, alturaParede, espessuraParede),
                    Vector3.new(centroX, alturaParede / 2, centroZ - tamanhoCelula / 2)
                )
            end

            if MazeGrid.temParede(grade, linha, coluna, "Oeste") then
                criarPeca(
                    folder,
                    "ParedeOeste" .. nomeCelula,
                    Vector3.new(espessuraParede, alturaParede, tamanhoCelula + espessuraParede),
                    Vector3.new(centroX - tamanhoCelula / 2, alturaParede / 2, centroZ)
                )
            end

            if linha == grade.Linhas and MazeGrid.temParede(grade, linha, coluna, "Sul") then
                criarPeca(
                    folder,
                    "ParedeSul" .. nomeCelula,
                    Vector3.new(tamanhoCelula + espessuraParede, alturaParede, espessuraParede),
                    Vector3.new(centroX, alturaParede / 2, centroZ + tamanhoCelula / 2)
                )
            end

            if coluna == grade.Colunas and MazeGrid.temParede(grade, linha, coluna, "Leste") then
                criarPeca(
                    folder,
                    "ParedeLeste" .. nomeCelula,
                    Vector3.new(espessuraParede, alturaParede, tamanhoCelula + espessuraParede),
                    Vector3.new(centroX + tamanhoCelula / 2, alturaParede / 2, centroZ)
                )
            end
        end
    end

    folder.Parent = parent
    return folder
end

return MazeBuilder
