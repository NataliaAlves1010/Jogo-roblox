--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local zonesModule = script.Parent:WaitForChild("Zones") :: ModuleScript
local MazeGrid = require(mazeGridModule)
local Config = require(configModule)
local Zones = require(zonesModule)

local ObstaclePlacer = {}

type Grade = MazeGrid.Grade
type Lado = MazeGrid.Lado
type Zona = Zones.Zona

export type Candidato = {
    Celula: Vector2,
    Instancia: BasePart | Model,
}

type Movimento = {
    Lado: Lado,
    DeltaLinha: number,
    DeltaColuna: number,
}

local movimentos: { Movimento } = {
    { Lado = "Norte", DeltaLinha = -1, DeltaColuna = 0 },
    { Lado = "Leste", DeltaLinha = 0, DeltaColuna = 1 },
    { Lado = "Sul", DeltaLinha = 1, DeltaColuna = 0 },
    { Lado = "Oeste", DeltaLinha = 0, DeltaColuna = -1 },
}

local function chaveCelula(linha: number, coluna: number): string
    return `{linha}:{coluna}`
end

local function celulaValida(grade: Grade, celula: Vector2): boolean
    local linha = celula.X
    local coluna = celula.Y
    return linha % 1 == 0
        and coluna % 1 == 0
        and linha >= 1
        and linha <= grade.Linhas
        and coluna >= 1
        and coluna <= grade.Colunas
end

local function bloqueadasPorChave(bloqueadas: { Vector2 }?): { [string]: boolean }
    local resultado: { [string]: boolean } = {}
    if bloqueadas ~= nil then
        for _, celula in bloqueadas do
            resultado[chaveCelula(celula.X, celula.Y)] = true
        end
    end
    return resultado
end

function ObstaclePlacer.caminhoValido(
    grade: Grade,
    inicio: Vector2,
    destinos: { Vector2 },
    bloqueadas: { Vector2 }?
): boolean
    if #destinos == 0 or not celulaValida(grade, inicio) then
        return false
    end

    local bloqueadasSet = bloqueadasPorChave(bloqueadas)
    local chaveInicio = chaveCelula(inicio.X, inicio.Y)
    if bloqueadasSet[chaveInicio] then
        return false
    end

    for _, destino in destinos do
        if not celulaValida(grade, destino) or bloqueadasSet[chaveCelula(destino.X, destino.Y)] then
            return false
        end
    end

    local fila: { Vector2 } = { inicio }
    local visitadas: { [string]: boolean } = { [chaveInicio] = true }
    local indiceFila = 1
    while indiceFila <= #fila do
        local atual = fila[indiceFila]
        indiceFila += 1
        local linha = atual.X
        local coluna = atual.Y
        local celula = grade.Celulas[linha][coluna]

        for _, movimento in movimentos do
            if not celula[movimento.Lado] then
                local proximaLinha = linha + movimento.DeltaLinha
                local proximaColuna = coluna + movimento.DeltaColuna
                local chaveProxima = chaveCelula(proximaLinha, proximaColuna)
                if
                    proximaLinha >= 1
                    and proximaLinha <= grade.Linhas
                    and proximaColuna >= 1
                    and proximaColuna <= grade.Colunas
                    and not bloqueadasSet[chaveProxima]
                    and not visitadas[chaveProxima]
                then
                    visitadas[chaveProxima] = true
                    table.insert(fila, Vector2.new(proximaLinha, proximaColuna))
                end
            end
        end
    end

    for _, destino in destinos do
        if not visitadas[chaveCelula(destino.X, destino.Y)] then
            return false
        end
    end
    return true
end

local function zonaDaCelula(zonas: { Zona }, linha: number, coluna: number): Zona?
    for _, zona in zonas do
        if
            linha >= zona.LinhaInicial
            and linha <= zona.LinhaFinal
            and coluna >= zona.ColunaInicial
            and coluna <= zona.ColunaFinal
        then
            return zona
        end
    end
    return nil
end

local function cframeNaCelula(grade: Grade, celula: Vector2, atual: CFrame): CFrame
    local tamanhoCelula = Config.Maze.CellSize
    local largura = grade.Colunas * tamanhoCelula
    local profundidade = grade.Linhas * tamanhoCelula
    local x = (celula.Y - 0.5) * tamanhoCelula - largura / 2
    local z = (celula.X - 0.5) * tamanhoCelula - profundidade / 2
    local posicao = Vector3.new(x, atual.Position.Y, z)
    return CFrame.new(posicao) * (atual - atual.Position)
end

local function posicionarInstancia(instancia: BasePart | Model, cframe: CFrame, zona: Zona): ()
    instancia.Parent = zona.Pasta
    if instancia:IsA("Model") then
        instancia:PivotTo(cframe)
    else
        instancia.CFrame = cframe
    end
end

function ObstaclePlacer.posicionar(
    grade: Grade,
    zonas: { Zona },
    mapa: Folder,
    inicio: Vector2,
    chaves: { Vector2 },
    candidatos: { Candidato }
): ()
    assert(#zonas > 0, "É necessário fornecer as zonas do mapa")
    assert(#candidatos > 0, "É necessário fornecer candidatos de obstáculos")
    assert(#chaves > 0, "É necessário fornecer as células das chaves")
    for _, zona in zonas do
        assert(zona.Pasta.Parent == mapa, `A zona {zona.Nome} não pertence ao mapa fornecido`)
    end
    assert(
        ObstaclePlacer.caminhoValido(grade, inicio, chaves),
        "O mapa inicial já não tem caminho até todas as chaves"
    )

    local bloqueadas: { Vector2 } = {}
    local ocupadas: { [string]: boolean } = {}
    local aceitos = 0
    for _, candidato in candidatos do
        local celula = candidato.Celula
        local chave = chaveCelula(celula.X, celula.Y)
        local zona = if celulaValida(grade, celula) then zonaDaCelula(zonas, celula.X, celula.Y) else nil
        if zona == nil or ocupadas[chave] then
            continue
        end

        local bloqueadasTentativa = table.clone(bloqueadas)
        table.insert(bloqueadasTentativa, celula)
        if ObstaclePlacer.caminhoValido(grade, inicio, chaves, bloqueadasTentativa) then
            local atual = if candidato.Instancia:IsA("Model")
                then candidato.Instancia:GetPivot()
                else candidato.Instancia.CFrame
            local destino = cframeNaCelula(grade, celula, atual)
            candidato.Instancia:SetAttribute("CelulaLinha", celula.X)
            candidato.Instancia:SetAttribute("CelulaColuna", celula.Y)
            posicionarInstancia(candidato.Instancia, destino, zona)
            table.insert(bloqueadas, celula)
            ocupadas[chave] = true
            aceitos += 1
        end
    end

    if aceitos == 0 then
        warn("Nenhum obstáculo foi aceito porque bloquearia o caminho até uma chave ou não havia célula válida.")
    end
end

return ObstaclePlacer
