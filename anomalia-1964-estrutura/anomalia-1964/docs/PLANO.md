# Anomalia 1964 — PLANO (Roblox, Luau, Rojo)

Conceito: escape em labirinto gigante (Ministério, Brasília, abril/1964). Chegar à Sala 214 reunindo pistas e chaves, com um guarda que persegue o jogador. A faxineira dá dicas por diálogo. O jogador desbloqueia trechos de cartas históricas ao coletar pistas e compila a carta completa ao vencer na Sala 214.

Regras: uma tarefa por vez · servidor valida tudo · labirinto gerado por código (Codex não edita .rbxl) · `--!strict` · `task.wait()`.

## Fase 0 — Base
- [x] T01 AGENTS.md + docs/PLANO.md + docs/tarefas/ (modelo de ficha)
- [x] T02 `default.project.json` (Rojo), pastas `src/server`, `src/client`, `src/shared`
- [x] T03 stylua.toml, selene.toml, wally/aftman (se usar)
- [x] T04 `shared/Config.luau` (tamanho da célula, velocidades, tempos, nº de zonas)
- [x] T05 `shared/Types.luau` e `shared/Remotes.luau` (RemoteEvents criados pelo servidor)

## Fase 1 — Labirinto (dep.: F0)
- [x] T06 `shared/MazeGrid.luau`: grade NxM, paredes por célula, seed fixa
- [x] T07 `server/MazeGenerator.luau`: DFS/backtracker + loops extras (evita só-um-caminho)
- [x] T08 `server/MazeBuilder.luau`: transforma a grade em Parts (piso, paredes, teto) numa Folder
- [x] T09 `server/Zones.luau`: divide em 4 zonas (Recepção, Arquivo, Subsolo, Gabinete) com cor/iluminação própria
- [x] T10 `server/Checkpoints.luau`: 1 por zona; respawn do jogador
- [x] T11 `server/GoalRoom.luau`: Sala 214 no centro/fim, porta final marcada

## Fase 2 — Guarda (dep.: T08)
- [x] T12 `server/Guard/Spawn.luau`: NPC guarda (Humanoid) na zona 1
- [x] T13 `Guard/Patrol.luau`: waypoints nos cruzamentos, PathfindingService
- [x] T14 `Guard/Vision.luau`: cone de visão + raycast (parede bloqueia)
- [x] T15 `Guard/StateMachine.luau`: Patrulha → Suspeito → Perseguição → Busca (vai ao último ponto visto)
- [x] T16 `Guard/Chase.luau`: perseguição contínua, recalcula caminho, velocidade um pouco abaixo da do jogador
- [x] T17 `server/Capture.luau`: capturado = volta ao checkpoint + guarda reinicia patrulha (sem game over duro)
- [x] T18 `server/HideSpots.luau`: armários/caixas; esconder quebra a visão e baixa o alerta
- [x] T19 `client/AlertHUD.luau`: barra de alerta do guarda (calmo/suspeito/perseguição)

## Fase 3 — Obstáculos (dep.: T08, T05)
- [x] T20 `server/Interact.luau`: base com ProximityPrompt (valida distância no servidor)
- [x] T21 `Obstacles/LockedDoor.luau` + chaves por cor
- [x] T22 `Obstacles/Lever.luau`: alavanca abre portão em outro ponto do mapa
- [x] T23 `Obstacles/FallingFloor.luau`: piso temporário que cai e volta
- [x] T24 `Obstacles/LightBeam.luau`: feixe de luz/câmera com ritmo; atravessar só no intervalo
- [x] T25 `Obstacles/Vent.luau`: duto de atalho (agachado, mais lento, guarda não segue)
- [x] T26 `server/ObstaclePlacer.luau`: distribui obstáculos por zona, garantindo que o caminho até a chave continua possível (validar com BFS)

## Fase 4 — Pistas e Faxineira (dep.: T20)
- [x] T27 `server/Clues.luau` + `shared/ClueData.luau`: 9 pistas espalhadas, 2–3 por zona
- [x] T28 `server/Inventory.luau`: chaves e pistas por jogador (servidor é a fonte da verdade)
- [x] T29 `client/InventoryUI.luau` + diário de pistas
- [x] T30 `shared/DialogueData.luau`: falas da faxineira (dica por zona, reação a pistas já achadas)
- [x] T31 `server/Janitor.luau`: NPC com prompt de conversa, uma por zona ou itinerante
- [x] T32 `client/DialogueUI.luau`: caixa de diálogo (nome, texto digitando, botões de escolha)
- [x] T33 Faxineira entrega 1 chave/pista quando o jogador traz um item específico

## Fase 5 — Fechamento Básico
- [x] T34 `server/Progress.luau`: porta da Sala 214 exige as chaves + mínimo de pistas
- [x] T35 Vitória/final (tela, tempo, reiniciar mapa com nova seed)
- [x] T36 Iluminação, névoa, sons e música por zona
- [x] T37 Câmera/lanterna do jogador (opcional), sprint com estamina
- [ ] T38 Playtest e balanceamento inicial (Config.luau: tamanho, velocidades, tempos)
- [ ] T39 Testes: BFS de solvabilidade, TestEZ/jest para MazeGrid e Inventory

## Fase 6 — Interface de Entrada e Navegação
- [x] T40 `client/CoverUI.luau` + `assets/ui/capa.png`: Tela de capa/menu inicial (fundo da capa, botões Jogar, Continuar, Galeria e Opções; Continuar mantém na tela sem ação; Jogar faz fade out e inicia o spawn do jogador)
- [x] T41 `client/MapUI.luau` + `shared/Config.luau`: Tela cheia de mapa do Ministério acionada por tecla M ou botão na tela, renderizando a grade 31x31 das 4 zonas com a posição em tempo real do jogador

## Fase 7 — Dinâmica de Pistas, Perseguição Agressiva e Cartas Históricas
Conceito: cada pista coletada desaparece localmente para o jogador, emite alerta de ruído ao guarda e exibe um trecho da carta histórica. O guarda fica mais agressivo a cada pista achada. Na Sala 214, a carta completa com todos os trechos reunidos é revelada ao jogador.
- [x] T42 Ligar cartas e trechos às pistas: `letterId` e `trecho` em `shared/ClueData.luau` e `shared/LetterData.luau`
- [x] T43 `shared/Remotes.luau` + `shared/Types.luau`: remotes para ocultação de pistas no cliente, alerta acústico do guarda e envio de trechos
- [x] T44 `server/Clues.luau` + `client/CluesClient.luau`: pista desaparece localmente para quem coletou e emite ruído na célula da pista
- [x] T45 `server/Guard/StateMachine.luau` + `Config.luau`: guarda investiga ruído da pista imediatamente (`Suspeito`) e ganha velocidade e percepção progressivas por pista coletada
- [x] T46 `client/ClueToastUI.luau`: notificação rápida exibindo o trecho da carta recém-descoberta (sem travar controles do jogador)
- [x] T47 `client/InventoryUI.luau`: aba Cartas no Diário com os trechos parciais reunidos em ordem cronológica (n/9)
- [x] T48 `server/HelpRequest.luau`: validação e compilação da carta histórica completa para a Sala 214
- [x] T49 `client/HelpRequestUI.luau`: tela de leitura da carta final completa com os fatos históricos comprovados e tela de vitória
- [ ] T50 `docs/CARTAS.md`: revisão pedagógica e fontes primárias históricas (tarefa humana)
- [ ] T51 Testes integrados: `tests/letters.spec.luau` e validação do fluxo completo no Studio

Paralelizáveis: T40+T41, T46+T47. Execução recomendada na ordem sequencial da Fase 6 e Fase 7.
