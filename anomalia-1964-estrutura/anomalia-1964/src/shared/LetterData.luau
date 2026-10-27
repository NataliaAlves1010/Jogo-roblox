--!strict

-- Tabela de cartas históricas de Dona Cida — sem require, sem Vector3, sem Color3
-- Cada carta está vinculada a uma pista via ClueData.letterId

local LetterData = {}

export type Carta = {
    Id: string,
    Zona: string,
    Data: string,
    Titulo: string,
    Trecho: string,
    Texto: string,
    Fonte: string,
}

local cartas: { [string]: Carta } = {
    C01 = {
        Id = "C01",
        Zona = "Recepção",
        Data = "12/04/1964",
        Titulo = "O decreto que cassou tudo",
        Trecho = "Tonho, assinaram um papel e noventa e oito nomes sumiram das listas. Incluindo o do seu chefe.",
        Texto = "Tonho, três dias depois do golpe saiu o Ato Institucional n.º 1. "
            .. "Em nove de abril de mil novecentos e sessenta e quatro, o governo cassou mandatos, "
            .. "suspendeu direitos políticos por dez anos e demitiu servidores por decreto. "
            .. "A lista dos primeiros atingidos trazia cento e dois nomes. "
            .. "Aqui no Ministério a gente ficou sabendo pelo corredor, bem baixinho. "
            .. "Ninguém quis assinar o memorando que trouxe a notícia.",
        Fonte = "Texto do Ato Institucional n.º 1, 09/04/1964 (Planalto.gov.br).",
    },

    C02 = {
        Id = "C02",
        Zona = "Recepção",
        Data = "20/06/1964",
        Titulo = "O serviço que não aparece no organograma",
        Trecho = "Tonho, criaram uma repartição nova. Ninguém sabe exatamente o que fazem lá dentro.",
        Texto = "Tonho, em junho criaram o Serviço Nacional de Informações pelo "
            .. "Decreto-Lei n.º 4.341, de treze de junho de mil novecentos e sessenta e quatro. "
            .. "Disseram que era para coordenar as informações de interesse da segurança nacional. "
            .. "Na prática, qualquer suspeito podia ser investigado sem aviso. "
            .. "A repartição nova do andar de cima não tem plaquinha na porta "
            .. "e ninguém sabe o nome do chefe.",
        Fonte = "Lei n.º 4.341, 13/06/1964 (Câmara.leg.br).",
    },

    C03 = {
        Id = "C03",
        Zona = "Arquivo",
        Data = "03/05/1964",
        Titulo = "As demissões que o AI-1 permitiu",
        Trecho = "Tonho, o AI-1 suspendeu as garantias de estabilidade. Muita gente foi embora sem direito a recurso.",
        Texto = "Tonho, o artigo sétimo do Ato Institucional n.º 1 suspendeu, "
            .. "por seis meses, as garantias de estabilidade e vitaliciedade. "
            .. "Nesse período qualquer servidor podia ser demitido ou aposentado sem processo. "
            .. "Muita gente foi embora do Ministério carregando uma caixinha de pertences. "
            .. "Eu esfregava o corredor e fingia não ver.",
        Fonte = "Ato Institucional n.º 1, art. 7º, 09/04/1964 (Planalto.gov.br).",
    },

    C04 = {
        Id = "C04",
        Zona = "Arquivo",
        Data = "30/10/1965",
        Titulo = "O fim dos partidos",
        Trecho = "Tonho, agora só existe um partido do governo e um da oposição. Os outros foram extintos por decreto.",
        Texto = "Tonho, saiu o Ato Institucional n.º 2 em vinte e sete de outubro "
            .. "de mil novecentos e sessenta e cinco. "
            .. "Extinguiu todos os partidos políticos. Criaram dois no lugar: "
            .. "Arena e MDB, governo e oposição controlada. "
            .. "O voto direto para presidente também acabou. "
            .. "No arquivo eu arquivei sem ler o ofício que comunicava isso ao Ministério.",
        Fonte = "Ato Institucional n.º 2, 27/10/1965 (Planalto.gov.br); Politeia/UESB.",
    },

    C05 = {
        Id = "C05",
        Zona = "Arquivo",
        Data = "14/02/1969",
        Titulo = "A voz que a censura tentou calar",
        Trecho = "Tonho, professores foram afastados, músicos presos. Quem cantava errado sumia do rádio.",
        Texto = "Tonho, depois do AI-5 de dezembro de mil novecentos e sessenta e oito "
            .. "a censura ficou oficial. "
            .. "Professores foram aposentados compulsoriamente, artistas presos ou forçados ao exílio. "
            .. "Aqui no rádio da repartição pararam de tocar certas músicas do dia para a noite. "
            .. "Uma colega minha foi chamada para depor só porque guardava um vinil proibido. "
            .. "Eu passei a varrer mais rápido e falar menos.",
        Fonte = "AI-5, 13/12/1968 (Câmara.leg.br); Sul21, matéria sobre artistas e censura.",
    },

    C06 = {
        Id = "C06",
        Zona = "Subsolo",
        Data = "27/10/1975",
        Titulo = "O jornalista que não se suicidou",
        Trecho = "Tonho, o jornalista Vladimir Herzog morreu sob custódia. A versão oficial não convenceu ninguém.",
        Texto = "Tonho, em vinte e cinco de outubro de mil novecentos e setenta e cinco "
            .. "o jornalista Vladimir Herzog foi convocado para depor no DOI-CODI em São Paulo. "
            .. "No dia seguinte anunciaram que ele havia se suicidado na cela. "
            .. "A foto da cena não fechava com a história contada. "
            .. "Em dois mil e dezoito a Corte Interamericana de Direitos Humanos "
            .. "condenou o Brasil pelo assassinato. "
            .. "Eu ouvi a notícia num rádio escondido no subsolo.",
        Fonte = "Corte IDH, caso Herzog e outros vs. Brasil, sentença de 15/03/2018 (corteidh.or.cr).",
    },

    C07 = {
        Id = "C07",
        Zona = "Subsolo",
        Data = "15/12/2014",
        Titulo = "Os que ainda não voltaram",
        Trecho = "Tonho, a Comissão da Verdade confirmou 434 mortos e desaparecidos. Duzentos e dez ainda não foram encontrados.",
        Texto = "Tonho, a Comissão Nacional da Verdade encerrou os trabalhos em dezembro "
            .. "de dois mil e quatorze. "
            .. "O relatório final confirmou quatrocentas e trinta e quatro mortes e desaparecimentos "
            .. "causados pelo Estado entre mil novecentos e quarenta e seis e mil novecentos e oitenta e oito. "
            .. "Duzentos e dez pessoas continuam desaparecidas. "
            .. "Nunca soube se o Tonho está nessa lista. "
            .. "É por isso que ainda escrevo.",
        Fonte = "Relatório Final da CNV, v. III (2014); Human Rights Watch Brasil (hrw.org/pt).",
    },

    C08 = {
        Id = "C08",
        Zona = "Gabinete",
        Data = "20/12/1968",
        Titulo = "O ato que fechou o Congresso",
        Trecho = "Tonho, o Congresso foi fechado. Habeas corpus suspenso. A censura virou lei.",
        Texto = "Tonho, em treze de dezembro de mil novecentos e sessenta e oito "
            .. "veio o Ato Institucional n.º 5. "
            .. "Fechou o Congresso, suspendeu o habeas corpus para crimes políticos "
            .. "e autorizou a censura prévia da imprensa. "
            .. "Aqui no Ministério o silêncio ficou mais pesado que de costume. "
            .. "O AI-5 só foi revogado em treze de outubro de mil novecentos e setenta e oito "
            .. "pela Emenda Constitucional n.º 11.",
        Fonte = "AI-5, 13/12/1968; EC n.º 11, 13/10/1978 (Câmara.leg.br; Conjur).",
    },

    C09 = {
        Id = "C09",
        Zona = "Gabinete",
        Data = "29/08/1979",
        Titulo = "A anistia e o que ficou em aberto",
        Trecho = "Tonho, a Lei da Anistia passou. Alguns voltaram. O debate sobre quem ela protege ainda não acabou.",
        Texto = "Tonho, em vinte e oito de agosto de mil novecentos e setenta e nove "
            .. "o Congresso aprovou a Lei n.º 6.683, a Lei da Anistia. "
            .. "Muitos exilados puderam voltar. "
            .. "Mas a interpretação sobre quem a lei protege "
            .. "— se só os perseguidos políticos ou também os agentes do Estado — "
            .. "segue em debate até hoje. "
            .. "Depois vieram as Diretas Já e a Constituição de mil novecentos e oitenta e oito. "
            .. "Cada passo foi uma luta.",
        Fonte = "Lei n.º 6.683, 28/08/1979 (Planalto.gov.br); revista Locus, UFJF.",
    },
}

function LetterData.obterCarta(id: string): Carta?
    return cartas[id]
end

function LetterData.obterTodas(): { Carta }
    local lista: { Carta } = {}
    for _, carta in cartas do
        table.insert(lista, carta)
    end
    return lista
end

return LetterData
