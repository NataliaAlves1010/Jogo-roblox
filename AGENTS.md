# AGENTS.md — Anomalia 1964 (Roblox, Luau, Rojo)

## Repositório
- URL do GitHub: https://github.com/NataliaAlves1010/Jogo-roblox
- Branch principal: `master`
- Remoto: `origin`

## O jogo
Escape em labirinto gigante (Ministério, Brasília, abril de 1964). O jogador reúne pistas e chaves para chegar à Sala 214. Um guarda persegue o jogador o tempo todo. A faxineira dá dicas por diálogo. Se o guarda capturar o jogador, ele volta ao último checkpoint (sem game over). O personagem do jogador é o próprio avatar do Roblox.

## Regras fixas
1. Todo o código fica em `src/`. Nunca edite arquivos `.rbxl` ou `.rbxlx`.
2. Faça UMA tarefa por vez: apenas a indicada no prompt.
3. Não edite arquivos fora da tarefa. Se faltar algo, pare e avise o que falta.
4. Luau com `--!strict` na primeira linha de cada arquivo.
5. Use `task.wait()`, `task.spawn()` e `task.delay()`. Nunca `wait()`, `spawn()` ou `delay()`.
6. O servidor valida tudo (inventário, portas, captura, progresso). O cliente só mostra interface e envia pedidos.
7. Valores de ajuste (velocidades, tempos, tamanhos) ficam em `src/shared/Config.luau`, nunca soltos no código.
8. Comentários e mensagens ao jogador em português.

## Estrutura de pastas
```
anomalia-1964/
├── AGENTS.md
├── assets/npcs/
├── docs/
│   ├── PLANO.md
│   └── tarefas/
└── src/
    ├── client/
    ├── shared/
    └── server/
        ├── Guard/
        └── Obstacles/
```

## Ferramentas (PowerShell, caminho completo)
O PATH do Codex não enxerga o Rokit. Use sempre estes comandos:
- StyLua: `& "$env:USERPROFILE\.rokit\bin\stylua.exe" src/`
- Selene: `& "$env:USERPROFILE\.rokit\bin\selene.exe" src/`

Se `selene.toml` ou `default.project.json` ainda não existirem (antes da T03 e da T02), ignore o aviso de configuração ausente e diga isso no resumo.

## Passo a passo de cada tarefa
Quando o prompt for `Leia AGENTS.md e docs/tarefas/Txx.md. Execute apenas a Txx.`, faça exatamente isto, na ordem:

1. Rode `git status`. Se houver alterações não commitadas, pare e avise.
2. Rode `git checkout master && git pull origin master`.
3. Crie a branch da tarefa: `git checkout -b Txx-titulo-curto`.
4. Leia `docs/tarefas/Txx.md` e confira em `docs/PLANO.md` que as tarefas das quais ela depende estão marcadas `[x]`. Se não estiverem, pare e avise.
5. Crie ou edite SOMENTE os arquivos listados na ficha, seguindo as assinaturas de função indicadas.
6. Rode o StyLua (comando da seção Ferramentas) e corrija a formatação.
7. Rode o Selene (comando da seção Ferramentas) e corrija todos os avisos e erros.
8. Se a ficha tiver critério de teste, rode-o. Se o teste falhar, corrija e repita os passos 6 a 8.
9. Marque `[x]` na linha da tarefa em `docs/PLANO.md`.
10. Faça o commit: `git add -A && git commit -m "Txx: título da tarefa"`.
11. Envie a branch: `git push -u origin Txx-titulo-curto`.
12. Responda com um resumo curto: arquivos criados ou alterados, como testar no Studio e qualquer dúvida ou limitação.

## O que NÃO fazer
- Não faça merge na `master`. Quem revisa e faz o merge é o dono do projeto.
- Não comece a próxima tarefa por conta própria.
- Não refatore código de tarefas anteriores. Se achar um problema nele, descreva no resumo final.
- Não instale dependências novas sem estar na ficha.
- Não crie documentação além da pedida.

## Se algo der errado
- Falha em `git push` (sem acesso ao remoto): pare, informe o erro e deixe o commit na branch local.
- Ficha ambígua ou incompleta: pare e faça no máximo uma pergunta objetiva.
- Conflito de arquivos: não resolva sozinho, avise.

## Revisão (feita pelo dono do projeto)
1. `git fetch && git diff master..Txx-titulo-curto`
2. Testar no Studio com o Rojo conectado (`rojo serve`).
3. Se estiver bom, merge na `master` e próxima tarefa. Se não, pedir ajuste na mesma sessão do Codex.
