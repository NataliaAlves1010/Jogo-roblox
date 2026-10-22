--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Types = require(typesModule)

export type Pista = {
    Id: string,
    Zona: Types.NomeZona,
    Celula: Vector2,
    Texto: string,
}

local pistas: { Pista } = {
    {
        Id = "protocolo_entrada",
        Zona = "Recepção",
        Celula = Vector2.new(3, 4),
        Texto = "O protocolo registra a entrada de um grupo sem autorização oficial.",
    },
    {
        Id = "ordem_evacuacao",
        Zona = "Recepção",
        Celula = Vector2.new(11, 12),
        Texto = "A ordem de evacuação foi assinada antes do início do expediente.",
    },
    {
        Id = "registro_plantao",
        Zona = "Arquivo",
        Celula = Vector2.new(3, 20),
        Texto = "O registro de plantão diz que a faxineira guardou uma chave do Gabinete.",
    },
    {
        Id = "memorando_214",
        Zona = "Arquivo",
        Celula = Vector2.new(11, 27),
        Texto = "Um memorando menciona movimentação de documentos na Sala 214.",
    },
    {
        Id = "planta_subsolo",
        Zona = "Subsolo",
        Celula = Vector2.new(20, 3),
        Texto = "A planta mostra um corredor de serviço que não aparece nas placas.",
    },
    {
        Id = "lista_manutencao",
        Zona = "Subsolo",
        Celula = Vector2.new(27, 11),
        Texto = "A lista de manutenção confirma que o duto leva ao corredor do Gabinete.",
    },
    {
        Id = "relatorio_sigilo",
        Zona = "Gabinete",
        Celula = Vector2.new(20, 20),
        Texto = "O relatório ordena que os documentos de abril permaneçam sob sigilo.",
    },
    {
        Id = "chaveiro_registro",
        Zona = "Gabinete",
        Celula = Vector2.new(23, 28),
        Texto = "Uma anotação descreve o chaveiro usado para trancar a Sala 214.",
    },
    {
        Id = "telegrama_abril",
        Zona = "Gabinete",
        Celula = Vector2.new(29, 29),
        Texto = "O telegrama confirma que a ordem chegou a Brasília em abril de 1964.",
    },
}

local ClueData = {}

function ClueData.obterTodas(): { Pista }
    return table.clone(pistas)
end

return ClueData
