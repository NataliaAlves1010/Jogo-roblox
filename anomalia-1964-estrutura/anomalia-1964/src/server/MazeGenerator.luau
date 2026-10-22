--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript
local MazeGrid = require(mazeGridModule)

local MazeGenerator = {}

type Grade = MazeGrid.Grade
type Lado = MazeGrid.Lado

type Posicao = {
    Linha: number,
    Coluna: number,
}

type Ligacao = {
    Linha: number,
    Coluna: number,
    Lado: Lado,
    Oposto: Lado,
}

local function abrirParede(grade: Grade, ligacao: Ligacao)
    grade.Celulas[ligacao.Linha][ligacao.Coluna][ligacao.Lado] = false

    local linhaVizinha = ligacao.Linha
    local colunaVizinha = ligacao.Coluna

    if ligacao.Lado == "Norte" then
        linhaVizinha -= 1
    elseif ligacao.Lado == "Leste" then
        colunaVizinha += 1
    elseif ligacao.Lado == "Sul" then
        linhaVizinha += 1
    else
        colunaVizinha -= 1
    end

    grade.Celulas[linhaVizinha][colunaVizinha][ligacao.Oposto] = false
end

function MazeGenerator.gerar(linhas: number, colunas: number, seed: number): Grade
    assert(linhas > 0 and colunas > 0, "O labirinto precisa ter linhas e colunas positivas")
    assert(
        linhas == math.floor(linhas) and colunas == math.floor(colunas),
        "As dimensões precisam ser números inteiros"
    )

    local grade = MazeGrid.criar(linhas, colunas, seed)
    local aleatorio = Random.new(seed)
    local visitadas: { { boolean } } = {}

    for linha = 1, linhas do
        visitadas[linha] = {}

        for coluna = 1, colunas do
            visitadas[linha][coluna] = false
        end
    end

    local pilha: { Posicao } = { { Linha = 1, Coluna = 1 } }
    visitadas[1][1] = true

    while #pilha > 0 do
        local atual = pilha[#pilha]
        assert(atual ~= nil, "A pilha do labirinto não pode estar vazia")

        local vizinhos: { Ligacao } = {}

        if atual.Linha > 1 and not visitadas[atual.Linha - 1][atual.Coluna] then
            table.insert(vizinhos, {
                Linha = atual.Linha,
                Coluna = atual.Coluna,
                Lado = "Norte",
                Oposto = "Sul",
            })
        end

        if atual.Coluna < colunas and not visitadas[atual.Linha][atual.Coluna + 1] then
            table.insert(vizinhos, {
                Linha = atual.Linha,
                Coluna = atual.Coluna,
                Lado = "Leste",
                Oposto = "Oeste",
            })
        end

        if atual.Linha < linhas and not visitadas[atual.Linha + 1][atual.Coluna] then
            table.insert(vizinhos, {
                Linha = atual.Linha,
                Coluna = atual.Coluna,
                Lado = "Sul",
                Oposto = "Norte",
            })
        end

        if atual.Coluna > 1 and not visitadas[atual.Linha][atual.Coluna - 1] then
            table.insert(vizinhos, {
                Linha = atual.Linha,
                Coluna = atual.Coluna,
                Lado = "Oeste",
                Oposto = "Leste",
            })
        end

        if #vizinhos == 0 then
            table.remove(pilha)
        else
            local indice = aleatorio:NextInteger(1, #vizinhos)
            local proximaLigacao = vizinhos[indice]
            assert(proximaLigacao ~= nil, "A ligação escolhida precisa existir")

            local linhaVizinha = proximaLigacao.Linha
            local colunaVizinha = proximaLigacao.Coluna

            if proximaLigacao.Lado == "Norte" then
                linhaVizinha -= 1
            elseif proximaLigacao.Lado == "Leste" then
                colunaVizinha += 1
            elseif proximaLigacao.Lado == "Sul" then
                linhaVizinha += 1
            else
                colunaVizinha -= 1
            end

            abrirParede(grade, proximaLigacao)
            visitadas[linhaVizinha][colunaVizinha] = true
            table.insert(pilha, { Linha = linhaVizinha, Coluna = colunaVizinha })
        end
    end

    local paredesParaCiclo: { Ligacao } = {}

    for linha = 1, linhas do
        for coluna = 1, colunas do
            if coluna < colunas and MazeGrid.temParede(grade, linha, coluna, "Leste") then
                table.insert(paredesParaCiclo, {
                    Linha = linha,
                    Coluna = coluna,
                    Lado = "Leste",
                    Oposto = "Oeste",
                })
            end

            if linha < linhas and MazeGrid.temParede(grade, linha, coluna, "Sul") then
                table.insert(paredesParaCiclo, {
                    Linha = linha,
                    Coluna = coluna,
                    Lado = "Sul",
                    Oposto = "Norte",
                })
            end
        end
    end

    local ciclos = math.min(#paredesParaCiclo, math.max(1, math.floor(math.sqrt(linhas * colunas))))

    for _ = 1, ciclos do
        local indice = aleatorio:NextInteger(1, #paredesParaCiclo)
        local ligacao = table.remove(paredesParaCiclo, indice)
        assert(ligacao ~= nil, "A parede escolhida para o ciclo precisa existir")
        abrirParede(grade, ligacao)
    end

    return grade
end

return MazeGenerator
