# AGENTS.md — Anomalia 1964 (Roblox, Luau, Rojo)

## Repositório
- URL do GitHub: `COLE_AQUI_A_URL_DO_REPOSITORIO`
- Branch principal: `main`
- Remoto: `origin`

## O jogo
Escape em labirinto gigante (Ministério, Brasília, abril de 1964). O jogador reúne pistas e chaves para chegar à Sala 214. Um guarda persegue o jogador o tempo todo. A faxineira dá dicas por diálogo. Se o guarda capturar o jogador, ele volta ao último checkpoint (sem game over).

## Regras fixas
1. Todo o código fica em `src/`. Nunca edite arquivos `.rbxl` ou `.rbxlx`.
2. Faça UMA tarefa por vez: apenas a indicada no prompt.
3. Não edite arquivos fora da tarefa. Se faltar algo, pare e avise o que falta.
4. Luau com `--!strict` na primeira linha de cada arquivo.
5. Use `task.wait()`, `task.spawn()` e `task.delay()`. Nunca `wait()`, `spawn()` ou `delay()`.
6. O servidor valida tudo (inventário, portas, captura, progresso). O cliente só mostra interface e envia pedidos.
7. Valores de ajuste (velocidades, tempos, tamanhos) ficam em `src/shared/Config.luau`, nunca soltos no código.
8. Comentários e nomes de mensagens ao jogador em português.

## Estrutura de pastas
```
src/
  server/   lógica autoritativa (labirinto, guarda, obstáculos, inventário)
  client/   interface e efeitos
  shared/   Config, Types, Remotes, dados (pistas, diálogos)
docs/
  PLANO.md          lista T01 a T39 com [ ]
  tarefas/Txx.md    uma ficha por tarefa
default.project.json
```

## Passo a passo de cada tarefa
Quando o prompt for `Leia AGENTS.md e docs/tarefas/Txx.md. Execute apenas a Txx.`, faça exatamente isto, na ordem:

1. Rode `git status`. Se houver alterações não commitadas, pare e avise.
2. Rode `git checkout main && git pull origin main`.
3. Crie a branch da tarefa: `git checkout -b Txx-titulo-curto`.
4. Leia `docs/tarefas/Txx.md` e confira em `docs/PLANO.md` que as tarefas das quais ela depende estão marcadas `[x]`. Se não estiverem, pare e avise.
5. Crie ou edite SOMENTE os arquivos listados na ficha, seguindo as assinaturas de função indicadas.
6. Rode `& "$env:USERPROFILE\.rokit\tool-storage\johnnymorganz\stylua\2.6.0\stylua.exe" src/` e corrija a formatação.
7. Rode `& "$env:USERPROFILE\.rokit\tool-storage\kampfkarren\selene\0.32.0\selene.exe" src/` e corrija todos os avisos e erros.
8. Se a ficha tiver critério de teste, rode-o. Se o teste falhar, corrija e repita os passos 6 a 8.
9. Marque `[x]` na linha da tarefa em `docs/PLANO.md`.
10. Faça o commit: `git add -A && git commit -m "Txx: título da tarefa"`.
11. Envie a branch: `git push -u origin Txx-titulo-curto`.
12. Responda com um resumo curto: arquivos criados ou alterados, como testar no Studio e qualquer dúvida ou limitação.

## O que NÃO fazer
- Não faça merge na `main`. Quem revisa e faz o merge é o dono do projeto.
- Não comece a próxima tarefa por conta própria.
- Não refatore código de tarefas anteriores. Se achar um problema nele, descreva no resumo final.
- Não instale dependências novas sem estar na ficha.
- Não crie documentação além da pedida.

## Se algo der errado
- Falha em `git push` (sem acesso ao remoto): pare, informe o erro e deixe o commit na branch local.
- Ficha ambígua ou incompleta: pare e faça no máximo uma pergunta objetiva.
- Conflito de arquivos: não resolva sozinho, avise.

## Revisão (feita pelo dono do projeto)
1. `git fetch && git diff main..Txx-titulo-curto`
2. Testar no Studio com o Rojo conectado (`rojo serve`).
3. Se estiver bom, merge na `main` e próxima tarefa. Se não, pedir ajuste na mesma sessão do Codex.
