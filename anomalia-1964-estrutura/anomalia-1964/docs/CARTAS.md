# Cartas históricas e pedido de ajuda

## Ideia
Cada **pista** coletada abre uma **carta** escrita por **Dona Cida**, a faxineira do Ministério (personagem fictícia), para o irmão **Tonho** (também fictício). Cada carta conta, na voz de quem viveu, **um fato real** do período 1964–2014, e logo depois mostra o quadro **"O que aconteceu de verdade"** com a explicação objetiva e a **fonte**.

No fim, na Sala 214, o jogador **monta o pedido de ajuda de Dona Cida**: para cada carta que coletou, escolhe entre 3 frases a que resume corretamente o fato. As frases certas formam a **carta final**, que termina com o pedido real: procurar os documentos, ouvir quem viveu e contar para mais alguém. Cartas não coletadas viram buracos na carta final ("trecho que se perdeu").

```text
pista coletada ─▶ carta de Dona Cida ─▶ fato real + fonte ─▶ diário (n/9)
                                                       │
Sala 214 (chaves + mínimo de pistas) ─▶ monta o pedido ─▶ carta final ─▶ vitória
```

## Enquadramento (decisão para você confirmar)
O seu jogo se passa em abril de 1964, mas as cartas vão até 2014. Para isso funcionar, trate o labirinto como a **memória do arquivo**: o jogador está dentro do Ministério de 1964 e as cartas são **lembranças de Dona Cida** que o labirinto guardou. Texto sugerido para o tutorial:
> "Este arquivo guarda mais do que papéis. Cada pista abre uma lembrança de quem limpava estas salas."

Alternativa: tornar a premissa explícita ("o jogador viaja ao arquivo em 2014"). Em ambos os casos, **Dona Cida e Tonho são fictícios** (aviso na tela final).

## O guarda e a leitura (regra de design)
O guarda persegue o tempo todo, então abrir uma página de leitura no meio da fuga seria injusto. Regra (T42): se o guarda está em **Suspeito, Perseguição ou Busca**, a carta **entra numa fila** e o jogador recebe só o aviso "Carta guardada". A fila abre quando ele **se esconde**, **reaparece num checkpoint** ou o guarda volta à **Patrulha** por 5 s. Assim a leitura vira recompensa por escapar.

## As 9 cartas
| Id | Zona sugerida | Data da carta | Tema real | Fato verificado em |
|---|---|---|---|---|
| C01 | Recepção | 12/04/1964 | AI-1 (9/4/1964): cassações, direitos políticos por 10 anos, demissões; lista de 102 nomes | Texto do AI-1; artigos acadêmicos |
| C02 | Recepção | 20/06/1964 | Criação do SNI (Lei nº 4.341, 13/6/1964) | Lei na Câmara; material universitário |
| C03 | Arquivo | 03/05/1964 | Suspensão da estabilidade e demissões de servidores | Texto do AI-1 |
| C04 | Arquivo | 30/10/1965 | AI-2 (27/10/1965) extingue os partidos | Artigo acadêmico |
| C05 | Arquivo | 14/02/1969 | Censura, professores afastados, artistas presos ou exilados após o AI-5 | Reportagem; Câmara |
| C06 | Subsolo | 27/10/1975 | Morte de Vladimir Herzog sob custódia; versão de suicídio desmentida; condenação do Brasil (2018) | Corte Interamericana; imprensa |
| C07 | Subsolo | 15/12/2014 | Relatório Final da CNV: 434 mortos e desaparecidos, 210 ainda desaparecidos | CNV; imprensa; HRW |
| C08 | Gabinete | 20/12/1968 | AI-5 (13/12/1968): Congresso fechado, habeas corpus suspenso, censura prévia; revogado em 13/10/1978 | Conjur; Congresso em Foco |
| C09 | Gabinete | 29/08/1979 | Lei da Anistia (28/8/1979), Diretas Já e Constituição de 1988; debate sobre a interpretação | Lei na Planalto; artigos acadêmicos |

O diário e o pedido ordenam as cartas por **data cronológica**, não pela ordem em que foram achadas.

## Carta final (exemplo com as 9 cartas)
A carta é montada pelo servidor: **abertura** ("Brasília, 15 de dezembro de 2014. Para quem encontrou estas cartas,") + os 9 fragmentos certos + **fechamento** (Dona Cida diz que era só a faxineira, que o irmão Tonho foi afastado em 1964 e que as notícias dele pararam; pede que o jogador procure os documentos, escute quem viveu e conte a mais uma pessoa; "Lembrar não é guardar raiva. É não deixar que apaguem."). Em seguida, a lista **Como ajudar de verdade**: acervo do Arquivo Nacional e Memórias Reveladas, Relatório Final da CNV, conversar com os mais velhos, visitar museus e memoriais.

## Regras de conteúdo
1. **Sem violência gráfica.** As cartas falam de prisão, censura, demissão, exílio e desaparecimento sem descrever tortura ou mortes em detalhe.
2. **Pessoas reais só como fato documentado** (por exemplo, Herzog na nota histórica), nunca como personagem falando ou com falas inventadas.
3. **Cada fato tem fonte.** A voz de Dona Cida é ficção; o quadro "O que aconteceu de verdade" é informação.
4. **Temas em disputa** (interpretação da Lei da Anistia) aparecem de forma neutra, como "segue em debate", sem tomar partido.
5. Texto das cartas e fragmentos **não pode ser editado pela interface**: vem de `shared/LetterData.luau`.
6. O **gabarito** do pedido de ajuda fica em `server/LetterKeys.luau`, fora do alcance do cliente.

## Verificar antes de publicar (T48)
- [ ] **C01**: conferir "cento e dois nomes" na primeira lista (10/4/1964) em fonte primária (Câmara/Planalto) ou obra de referência.
- [ ] **C01/C03**: confirmar a suspensão de **seis meses** das garantias de estabilidade no texto do AI-1 (art. 7º). A expressão "milhares" em C03 só vale se houver estimativa confiável; o número citado em material escolar (cerca de 4,8 mil entre 1964 e 1973) precisa de fonte acadêmica antes de ir ao jogo.
- [ ] **C02**: texto da Lei nº 4.341/1964 e finalidade declarada do SNI.
- [ ] **C04**: confirmar no texto do AI-2 a extinção dos partidos e a data (27/10/1965).
- [ ] **C05**: confirmar cada nome e episódio (prisão de Caetano e Gil; interrogatório de Chico Buarque; saída de Vandré em fevereiro de 1969) em fonte biográfica ou jornalística de referência.
- [ ] **C06**: datas (apresentação em 24/10 e morte em 25/10/1975) e a sentença da Corte Interamericana (2018) no site da própria Corte.
- [ ] **C07**: 434 mortos e desaparecidos e 210 desaparecidos no volume III do Relatório Final da CNV.
- [ ] **C08**: texto do AI-5 e data de revogação (13/10/1978, EC nº 11).
- [ ] **C09**: texto da Lei nº 6.683/1979 (período 2/9/1961 a 15/8/1979). Redação neutra sobre o debate atual.
- [ ] Revisão por professor de História.
- [ ] Política do Roblox sobre temas sensíveis e eventos reais (ver abaixo).

## Roblox: conteúdo sensível
Antes de publicar, leia a política **vigente** do Roblox (Padrões da Comunidade e diretrizes de conteúdo) sobre temas sensíveis e eventos do mundo real, e preencha o questionário de classificação etária de forma honesta. O jogo é educativo e sem violência gráfica, mas a regra pode mudar. Se houver restrição, a alternativa é manter as cartas com **instituições e anos reais, sem imagens e sem descrição de violência**, ou abstrair nomes e datas.

## Fontes consultadas para escrever o conteúdo
Fontes secundárias usadas para conferir fatos neste rascunho (troque por primárias em T48):
- Texto do Ato Institucional nº 1 (Planalto) e sínteses: infoescola.com/ditadura-militar/ai-1; Antíteses/UEL (ojs.uel.br); Politeia/UESB (periodicos2.uesb.br).
- SNI e Lei nº 4.341/1964: UEMG (revista.uemg.br, Histórias Públicas); UFS, História do Brasil República II (cesad.ufs.br).
- AI-2: Politeia/UESB.
- AI-5: Conjur (conjur.com.br, 2018-dez-13); Congresso em Foco; Sul21 (artistas e censura).
- Herzog: Corte Interamericana (corteidh.or.cr, caso Herzog e outros); Agência Brasil via Money Times; IHU/Unisinos.
- CNV: Agência Brasil (via Congresso em Foco, Conjur e Bahia Notícias); Human Rights Watch Brasil (hrw.org/pt); Estado de Minas (210 desaparecidos).
- Anistia: infoescola.com/historia-do-brasil/lei-da-anistia; UFJF, revista Locus.
