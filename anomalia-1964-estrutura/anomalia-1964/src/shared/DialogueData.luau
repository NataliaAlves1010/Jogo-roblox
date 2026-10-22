--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local typesModule = sharedFolder:WaitForChild("Types") :: ModuleScript
local Types = require(typesModule)

type NomeZona = Types.NomeZona

export type Fala = {
    Nome: string,
    Texto: string,
    Escolhas: { string },
}

type DialogoZona = {
    Base: string,
    Pistas: { [string]: string },
}

local dialogos: { [NomeZona]: DialogoZona } = {
    ["Recepção"] = {
        Base = "Fique longe da entrada principal. Tem gente perguntando por quem passou por aqui.",
        Pistas = {
            protocolo_entrada = "Esse protocolo não devia existir. Procure quem autorizou a entrada.",
            ordem_evacuacao = "A ordem saiu cedo demais. Alguém sabia o que estava para acontecer.",
        },
    },
    Arquivo = {
        Base = "Os arquivos foram mexidos durante a noite. Procure os papéis que saíram do lugar.",
        Pistas = {
            registro_plantao = "Conheço esse registro. A chave do Gabinete ficou comigo por segurança.",
            memorando_214 = "Se o memorando cita a Sala 214, confira os documentos guardados no Gabinete.",
        },
    },
    Subsolo = {
        Base = "O subsolo é antigo. Siga as marcas de manutenção e não faça barulho nos dutos.",
        Pistas = {
            planta_subsolo = "A planta está certa. O corredor de serviço passa por trás das tubulações.",
            lista_manutencao = "Esse duto leva ao corredor do Gabinete, mas vá agachado.",
        },
    },
    Gabinete = {
        Base = "Não deixe os documentos espalhados. A porta da Sala 214 está no fim do corredor.",
        Pistas = {
            relatorio_sigilo = "O relatório explica por que esconderam os documentos. Falta chegar à Sala 214.",
            chaveiro_registro = "Guarde esse registro. O chaveiro certo abre a porta final.",
            telegrama_abril = "Esse telegrama confirma a data. Agora você sabe o que aconteceu aqui.",
        },
    },
}

local ESCOLHAS = { "Continuar", "Encerrar conversa" }

local DialogueData = {}

function DialogueData.obterFala(zona: NomeZona, pistas: { string }): Fala
    local dialogo = dialogos[zona]
    if dialogo == nil then
        return {
            Nome = "Faxineira",
            Texto = "Não posso conversar agora. Tome cuidado por aqui.",
            Escolhas = table.clone(ESCOLHAS),
        }
    end

    local texto = dialogo.Base
    for _, id in pistas do
        local dica = dialogo.Pistas[id]
        if dica ~= nil then
            texto = dica
            break
        end
    end

    return {
        Nome = "Faxineira",
        Texto = texto,
        Escolhas = table.clone(ESCOLHAS),
    }
end

return DialogueData
