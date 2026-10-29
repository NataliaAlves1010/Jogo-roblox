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
    LetterId: string,
    Trecho: string,
}

-- Mapeamento zona → cartas: Recepção → C01, C02 | Arquivo → C03, C04, C05 | Subsolo → C06, C07 | Gabinete → C08, C09
local pistas: { Pista } = {
    {
        Id = "protocolo_entrada",
        Zona = "Recepção",
        Celula = Vector2.new(3, 4),
        Texto = "O protocolo registra a entrada de um grupo sem autorização oficial.",
        LetterId = "C01",
        Trecho = "Tonho, assinaram um papel e noventa e oito nomes sumiram das listas. Incluindo o do seu chefe.",
    },
    {
        Id = "ordem_evacuacao",
        Zona = "Recepção",
        Celula = Vector2.new(11, 12),
        Texto = "A ordem de evacuação foi assinada antes do início do expediente.",
        LetterId = "C02",
        Trecho = "Tonho, criaram uma repartição nova. Ninguém sabe exatamente o que fazem lá dentro.",
    },
    {
        Id = "registro_plantao",
        Zona = "Arquivo",
        Celula = Vector2.new(3, 20),
        Texto = "O registro de plantão diz que a faxineira guardou uma chave do Gabinete.",
        LetterId = "C03",
        Trecho = "Tonho, o AI-1 suspendeu as garantias de estabilidade. Muita gente foi embora sem direito a recurso.",
    },
    {
        Id = "memorando_214",
        Zona = "Arquivo",
        Celula = Vector2.new(11, 22),
        Texto = "Um memorando menciona movimentação de documentos na Sala 214.",
        LetterId = "C04",
        Trecho = "Tonho, agora só existe um partido do governo e um da oposição. Os outros foram extintos por decreto.",
    },
    {
        Id = "ficha_censura",
        Zona = "Arquivo",
        Celula = Vector2.new(7, 23),
        Texto = "A ficha lista obras censuradas após dezembro de 1968.",
        LetterId = "C05",
        Trecho = "Tonho, professores foram afastados, músicos presos. Quem cantava errado sumia do rádio.",
    },
    {
        Id = "planta_subsolo",
        Zona = "Subsolo",
        Celula = Vector2.new(20, 3),
        Texto = "A planta mostra um corredor de serviço que não aparece nas placas.",
        LetterId = "C06",
        Trecho = "Tonho, o jornalista Vladimir Herzog morreu sob custódia. A versão oficial não convenceu ninguém.",
    },
    {
        Id = "lista_manutencao",
        Zona = "Subsolo",
        Celula = Vector2.new(22, 11),
        Texto = "A lista de manutenção confirma que o duto leva ao corredor do Gabinete.",
        LetterId = "C07",
        Trecho = "Tonho, a Comissão da Verdade confirmou 434 mortos e desaparecidos. Duzentos e dez ainda não foram encontrados.",
    },
    {
        Id = "relatorio_sigilo",
        Zona = "Gabinete",
        Celula = Vector2.new(20, 20),
        Texto = "O relatório ordena que os documentos de abril permaneçam sob sigilo.",
        LetterId = "C08",
        Trecho = "Tonho, o Congresso foi fechado. Habeas corpus suspenso. A censura virou lei.",
    },
    {
        Id = "telegrama_abril",
        Zona = "Gabinete",
        Celula = Vector2.new(22, 22),
        Texto = "O telegrama confirma que a ordem chegou a Brasília em abril de 1964.",
        LetterId = "C09",
        Trecho = "Tonho, a Lei da Anistia passou. Alguns voltaram. O debate sobre quem ela protege ainda não acabou.",
    },
}

local ClueData = {}

function ClueData.obterTodas(): { Pista }
    return table.clone(pistas)
end

function ClueData.obterTrecho(pistaId: string): string?
    for _, pista in pistas do
        if pista.Id == pistaId then
            return pista.Trecho
        end
    end
    return nil
end

return ClueData
