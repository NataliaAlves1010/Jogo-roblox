# Anomalia 1964 — PLANO (Roblox, Luau, Rojo)

Conceito: escape em labirinto gigante (Ministério, Brasília, abril/1964). Chegar à Sala 214 reunindo pistas e chaves, com um guarda que persegue o jogador o tempo todo. A faxineira dá dicas por diálogo.

Regras: uma tarefa por vez · servidor valida tudo · labirinto gerado por código (Codex não edita .rbxl) · `--!strict` · `task.wait()`.

## Fase 0 — Base
- [x] T01 AGENTS.md + docs/PLANO.md + docs/tarefas/ (modelo de ficha)
- [x] T02 `default.project.json` (Rojo), pastas `src/server`, `src/client`, `src/shared`
- [x] T03 stylua.toml, selene.toml, wally/aftman (se usar)
- [x] T04 `shared/Config.luau` (tamanho da célula, velocidades, tempos, nº de zonas)
- [ ] T05 `shared/Types.luau` e `shared/Remotes.luau` (RemoteEvents criados pelo servidor)

## Fase 1 — Labirinto (dep.: F0)
- [ ] T06 `shared/MazeGrid.luau`: grade NxM, paredes por célula, seed fixa
- [ ] T07 `server/MazeGenerator.luau`: DFS/backtracker + loops extras (evita só-um-caminho)
- [ ] T08 `server/MazeBuilder.luau`: transforma a grade em Parts (piso, paredes, teto) numa Folder
- [ ] T09 `server/Zones.luau`: divide em 4 zonas (Recepção, Arquivo, Subsolo, Gabinete) com cor/iluminação própria
- [ ] T10 `server/Checkpoints.luau`: 1 por zona; respawn do jogador
- [ ] T11 `server/GoalRoom.luau`: Sala 214 no centro/fim, porta final marcada

## Fase 2 — Guarda (dep.: T08)
- [ ] T12 `server/Guard/Spawn.luau`: NPC guarda (Humanoid) na zona 1
- [ ] T13 `Guard/Patrol.luau`: waypoints nos cruzamentos, PathfindingService
- [ ] T14 `Guard/Vision.luau`: cone de visão + raycast (parede bloqueia)
- [ ] T15 `Guard/StateMachine.luau`: Patrulha → Suspeito → Perseguição → Busca (vai ao último ponto visto)
- [ ] T16 `Guard/Chase.luau`: perseguição contínua, recalcula caminho, velocidade um pouco abaixo da do jogador
- [ ] T17 `server/Capture.luau`: capturado = volta ao checkpoint + guarda reinicia patrulha (sem game over duro)
- [ ] T18 `server/HideSpots.luau`: armários/caixas; esconder quebra a visão e baixa o alerta
- [ ] T19 `client/AlertHUD.luau`: barra de alerta do guarda (calmo/suspeito/perseguição)

## Fase 3 — Obstáculos (dep.: T08, T05)
- [ ] T20 `server/Interact.luau`: base com ProximityPrompt (valida distância no servidor)
- [ ] T21 `Obstacles/LockedDoor.luau` + chaves por cor
- [ ] T22 `Obstacles/Lever.luau`: alavanca abre portão em outro ponto do mapa
- [ ] T23 `Obstacles/FallingFloor.luau`: piso temporário que cai e volta
- [ ] T24 `Obstacles/LightBeam.luau`: feixe de luz/câmera com ritmo; atravessar só no intervalo
- [ ] T25 `Obstacles/Vent.luau`: duto de atalho (agachado, mais lento, guarda não segue)
- [ ] T26 `server/ObstaclePlacer.luau`: distribui obstáculos por zona, garantindo que o caminho até a chave continua possível (validar com BFS)

## Fase 4 — Pistas e Faxineira (dep.: T20)
- [ ] T27 `server/Clues.luau` + `shared/ClueData.luau`: 9 pistas espalhadas, 2–3 por zona
- [ ] T28 `server/Inventory.luau`: chaves e pistas por jogador (servidor é a fonte da verdade)
- [ ] T29 `client/InventoryUI.luau` + diário de pistas
- [ ] T30 `shared/DialogueData.luau`: falas da faxineira (dica por zona, reação a pistas já achadas)
- [ ] T31 `server/Janitor.luau`: NPC com prompt de conversa, uma por zona ou itinerante
- [ ] T32 `client/DialogueUI.luau`: caixa de diálogo (nome, texto digitando, botões de escolha)
- [ ] T33 Faxineira entrega 1 chave/pista quando o jogador traz um item específico

## Fase 5 — Fechamento
- [ ] T34 `server/Progress.luau`: porta da Sala 214 exige as chaves + mínimo de pistas
- [ ] T35 Vitória/final (tela, tempo, reiniciar mapa com nova seed)
- [ ] T36 Iluminação, névoa, sons e música por zona
- [ ] T37 Câmera/lanterna do jogador (opcional), sprint com estamina
- [ ] T38 Playtest e balanceamento (Config.luau: tamanho, velocidades, tempos)
- [ ] T39 Testes: BFS de solvabilidade, TestEZ/jest para MazeGrid e Inventory

Paralelizáveis (arquivos distintos): T22+T23, T24+T25, T30+T32. Fases 0→1→2 em ordem.

## Aproveitável do zip (Godot)
| Do zip | Uso no Roblox |
|---|---|
| Lore: Sala 214, Brasília, abril/1964, arquivo, zeladora, guarda | Texto, nomes e `DialogueData` |
| `Suit.fbx` (Quaternius) | Importar como malha/rig do guarda ou faxineira; as animações do FBX não migram sozinhas, recrie Idle/Walk no Animation Editor |
| Paleta de `level_environment.gd` (parede, piso, madeira, papel) | Cores do `MazeBuilder` e iluminação da zona 1 |
| Layout corredor + sala de arquivo, estantes | Modelo de cenário da zona "Arquivo" |
| `guard_patrol.gd` (ciclo de waypoints) | Só a ideia; T13 usa Pathfinding |
| `controle_vigia.gd` (WASD, câmera) | Descartar, o Roblox já tem controle e câmera |

Código GDScript não é convertido; só ideias, textos e o FBX.
