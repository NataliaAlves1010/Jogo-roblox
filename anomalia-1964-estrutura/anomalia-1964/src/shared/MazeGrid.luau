--!strict

local MazeGrid = {}

export type Lado = "Norte" | "Leste" | "Sul" | "Oeste"

export type Celula = {
    Norte: boolean,
    Leste: boolean,
    Sul: boolean,
    Oeste: boolean,
}

export type Grade = {
    Linhas: number,
    Colunas: number,
    Seed: number,
    Celulas: { { Celula } },
}

function MazeGrid.criar(linhas: number, colunas: number, seed: number): Grade
    assert(linhas > 0 and colunas > 0, "A grade precisa ter linhas e colunas positivas")

    local celulas: { { Celula } } = {}

    for linha = 1, linhas do
        local celulasDaLinha: { Celula } = {}

        for coluna = 1, colunas do
            celulasDaLinha[coluna] = {
                Norte = true,
                Leste = true,
                Sul = true,
                Oeste = true,
            }
        end

        celulas[linha] = celulasDaLinha
    end

    return {
        Linhas = linhas,
        Colunas = colunas,
        Seed = seed,
        Celulas = celulas,
    }
end

function MazeGrid.temParede(grade: Grade, linha: number, coluna: number, lado: Lado): boolean
    assert(linha >= 1 and linha <= grade.Linhas, "Linha fora dos limites da grade")
    assert(coluna >= 1 and coluna <= grade.Colunas, "Coluna fora dos limites da grade")

    return grade.Celulas[linha][coluna][lado]
end

return MazeGrid
