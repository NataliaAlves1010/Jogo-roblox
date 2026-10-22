--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local MazeGrid = require(mazeGridModule)
local Config = require(configModule)

local Zones = {}

export type Zona = {
    Nome: string,
    LinhaInicial: number,
    LinhaFinal: number,
    ColunaInicial: number,
    ColunaFinal: number,
    Pasta: Folder,
    Cor: Color3,
    CorIluminacao: Color3,
}

type Grade = MazeGrid.Grade
type DefinicaoZona = Zona

local function pertence(zona: Zona, linha: number, coluna: number): boolean
    return linha >= zona.LinhaInicial
        and linha <= zona.LinhaFinal
        and coluna >= zona.ColunaInicial
        and coluna <= zona.ColunaFinal
end

function Zones.criar(mapa: Folder, grade: Grade): { Zona }
    assert(grade.Linhas >= 2 and grade.Colunas >= 2, "A grade precisa ter pelo menos duas linhas e colunas")

    local metadeLinhas = math.floor(grade.Linhas / 2)
    local metadeColunas = math.floor(grade.Colunas / 2)
    local definicoes: { DefinicaoZona } = {
        {
            Nome = "Recepção",
            LinhaInicial = 1,
            LinhaFinal = metadeLinhas,
            ColunaInicial = 1,
            ColunaFinal = metadeColunas,
            Pasta = Instance.new("Folder"),
            Cor = Color3.fromRGB(206, 190, 150),
            CorIluminacao = Color3.fromRGB(255, 226, 166),
        },
        {
            Nome = "Arquivo",
            LinhaInicial = 1,
            LinhaFinal = metadeLinhas,
            ColunaInicial = metadeColunas + 1,
            ColunaFinal = grade.Colunas,
            Pasta = Instance.new("Folder"),
            Cor = Color3.fromRGB(170, 194, 205),
            CorIluminacao = Color3.fromRGB(170, 215, 255),
        },
        {
            Nome = "Subsolo",
            LinhaInicial = metadeLinhas + 1,
            LinhaFinal = grade.Linhas,
            ColunaInicial = 1,
            ColunaFinal = metadeColunas,
            Pasta = Instance.new("Folder"),
            Cor = Color3.fromRGB(139, 156, 142),
            CorIluminacao = Color3.fromRGB(182, 215, 191),
        },
        {
            Nome = "Gabinete",
            LinhaInicial = metadeLinhas + 1,
            LinhaFinal = grade.Linhas,
            ColunaInicial = metadeColunas + 1,
            ColunaFinal = grade.Colunas,
            Pasta = Instance.new("Folder"),
            Cor = Color3.fromRGB(188, 151, 142),
            CorIluminacao = Color3.fromRGB(255, 184, 159),
        },
    }

    local zonas: { Zona } = {}

    for _, definicao in definicoes do
        definicao.Pasta.Name = definicao.Nome
        definicao.Pasta:SetAttribute("LinhaInicial", definicao.LinhaInicial)
        definicao.Pasta:SetAttribute("LinhaFinal", definicao.LinhaFinal)
        definicao.Pasta:SetAttribute("ColunaInicial", definicao.ColunaInicial)
        definicao.Pasta:SetAttribute("ColunaFinal", definicao.ColunaFinal)
        definicao.Pasta.Parent = mapa

        table.insert(zonas, {
            Nome = definicao.Nome,
            LinhaInicial = definicao.LinhaInicial,
            LinhaFinal = definicao.LinhaFinal,
            ColunaInicial = definicao.ColunaInicial,
            ColunaFinal = definicao.ColunaFinal,
            Pasta = definicao.Pasta,
            Cor = definicao.Cor,
            CorIluminacao = definicao.CorIluminacao,
        })
    end

    for _, objeto in mapa:GetChildren() do
        if objeto:IsA("BasePart") then
            local textoLinha, textoColuna = string.match(objeto.Name, "_(%d+)_(%d+)$")

            if textoLinha ~= nil and textoColuna ~= nil then
                local linha = tonumber(textoLinha)
                local coluna = tonumber(textoColuna)

                if linha ~= nil and coluna ~= nil then
                    for _, zona in zonas do
                        if pertence(zona, linha, coluna) then
                            objeto.Color = zona.Cor
                            objeto.Parent = zona.Pasta
                            break
                        end
                    end
                end
            end
        end
    end

    for _, zona in zonas do
        local linhaCentro = math.floor((zona.LinhaInicial + zona.LinhaFinal) / 2)
        local colunaCentro = math.floor((zona.ColunaInicial + zona.ColunaFinal) / 2)
        local nomeTeto = string.format("Teto_%d_%d", linhaCentro, colunaCentro)
        local teto = zona.Pasta:FindFirstChild(nomeTeto)

        if teto ~= nil and teto:IsA("BasePart") then
            local luz = Instance.new("PointLight")
            luz.Name = "Iluminacao"
            luz.Color = zona.CorIluminacao
            luz.Range = Config.Maze.CellSize * 2
            luz.Shadows = false
            luz.Parent = teto
        end
    end

    return zonas
end

return Zones
