# Anomalia 1964 (Roblox, Luau, Rojo)

> Jogo de suspense e escape em labirinto gigante ambientado em um ministério em Brasília, abril de 1964.

---

## 🎯 Sobre o Jogo

O jogador acorda em um ministério labiríntico e precisa escapar reunindo pistas históricas e chaves até destrancar a misteriosa **Sala 214**. 
Um guarda implacável patrulha os corredores com inteligência artificial de visão e audição, enquanto uma faxineira oferece orientações e troca de itens por meio de diálogos. Se capturado, o jogador é enviado de volta ao último checkpoint alcançado sem perda dura de progresso.

---

## 🕹️ Comandos e Controles

| Tecla / Ação | Função |
|---|---|
| **`W`, `A`, `S`, `D`** | Andar / Mover avatar |
| **`Espaço`** | Pular |
| **`Shift Esquerdo`** | Correr (Sprint) — consome a barra de estamina |
| **`F`** | Ligar / Desligar Lanterna |
| **`E` (Interagir)** | Coletar pistas, conversar com a faxineira, esconder em armários, abrir portas e usar dutos |
| **Mouse (Botão Direito)** | Girar a câmera |
| **Mouse (Clique Esquerdo)** | Escolher respostas de diálogo e botões na tela |

---

## 🛠️ Pré-requisitos para Desenvolvimento

Para rodar e editar o projeto localmente, você precisa ter instalado:

1. [Roblox Studio](https://create.roblox.com/)
2. [Git](https://git-scm.com/)
3. [Rokit](https://github.com/rojo-rbx/rokit) (Gerenciador de ferramentas Luau)
4. Extensão do **Rojo** no Roblox Studio (instalada automaticamente ou via aba de Plugins do Studio)

---

## 🚀 Como Executar o Projeto na sua Máquina (Passo a Passo)

### 1. Clonar o Repositório
Abra o PowerShell ou Terminal e clone o repositório:
```powershell
git clone https://github.com/NataliaAlves1010/Jogo-roblox.git
cd Jogo-roblox
```

### 2. Restaurar as Ferramentas (Rokit)
Na raiz do repositório, instale o Rojo, StyLua e Selene:
```powershell
rokit install
```
*(Caso o comando `rokit` não esteja no seu PATH de usuário, use `& "$env:USERPROFILE\.rokit\bin\rokit.exe" install`)*.

### 3. Iniciar o Servidor do Rojo
No terminal, execute o servidor do Rojo apontando para o arquivo de projeto:
```powershell
& "$env:USERPROFILE\.rokit\bin\rojo.exe" serve "anomalia-1964-estrutura/anomalia-1964/default.project.json"
```
Você verá a mensagem:
```text
[INFO  rojo] Rojo server listening on 127.0.0.1:34872
```

### 4. Abrir no Roblox Studio e Conectar
1. Abra o **Roblox Studio**.
2. Na tela inicial, clique em **New** > escolha um **Baseplate** em branco (não precisa de arquivo salvo).
3. Na barra superior do Studio, vá na aba **Plugins** e clique no ícone do **Rojo**.
4. Na janela lateral do Rojo, clique em **Connect** (porta padrão `34872`).
5. Todo o código do jogo (`src/shared`, `src/server`, `src/client`) será sincronizado no jogo automaticamente!
6. Clique em **Play** para testar!

---

## 📱 Como Testar no Mobile e Desktop (Mais Fácil para Qualquer Jogador)

Jogadores comuns **não precisam** de VS Code, Git ou Rojo. A forma oficial e mais simples de disponibilizar o jogo para qualquer pessoa testar no PC, celular ou tablet é **publicando na nuvem do Roblox**:

### Passo a Passo para Publicar:
1. Com o jogo sincronizado no **Roblox Studio**:
   * Clique no menu superior **File (Arquivo)** > **Publish to Roblox** (Publicar na Roblox).
   * Dê um nome para a experiência (ex: `Anomalia 1964`) e salve.
2. Ativar dispositivos permitidos:
   * Vá em **Home** > **Game Settings** (Configurações do Jogo) > **Places / Devices**.
   * Certifique-se de que **Computer (Computador)** e **Phone / Tablet (Mobile)** estejam marcados.
3. Configurar quem pode jogar:
   * Em **Game Settings** > **Permissions** (Permissões):
     * Escolha **Friends** (se quiser que apenas seus amigos entrem) ou **Public** (para qualquer um jogar via link).
4. Compartilhar o link:
   * Vá na página do jogo no site do Roblox e copie o link.
   * **No Mobile ou Desktop:** A pessoa só precisa abrir o link pelo app ou navegador do Roblox e apertar o botão verde de **Play**!

> **Dica para Mobile:** As interações de cenário (`ProximityPrompt`) e os menus na tela já funcionam nativamente pelo toque na tela do celular.

---

## 📁 Estrutura de Pastas

```text
anomalia-1964/
├── README.md
├── AGENTS.md
├── rokit.toml
└── anomalia-1964-estrutura/anomalia-1964/
    ├── default.project.json
    ├── selene.toml
    ├── stylua.toml
    ├── docs/
    │   ├── PLANO.md
    │   └── tarefas/
    └── src/
        ├── client/          # Interfaces, efeitos, áudio e movimentação
        ├── shared/          # Configurações globais, tipos e remotos
        └── server/          # IA do guarda, geração do labirinto, obstáculos e progresso
```

---

## 📜 Regras de Desenvolvimento
- Luau com `--!strict` obrigatório.
- Servidor valida todas as ações (inventário, portas, colisões e progresso).
- Variáveis de ajuste centralizadas em `src/shared/Config.luau`.
- Formatação com StyLua e validação de linter com Selene.
