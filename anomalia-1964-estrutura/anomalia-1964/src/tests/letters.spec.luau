--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local clueDataModule = sharedFolder:WaitForChild("ClueData") :: ModuleScript
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local letterDataModule = sharedFolder:WaitForChild("LetterData") :: ModuleScript
local remotesFolder = ReplicatedStorage:WaitForChild("Remotos")
local serverFolder = ServerScriptService:WaitForChild("Server")
local helpRequestModule = serverFolder:WaitForChild("HelpRequest") :: ModuleScript
local inventoryModule = serverFolder:WaitForChild("Inventory") :: ModuleScript
local progressModule = serverFolder:WaitForChild("Progress") :: ModuleScript

local ClueData = require(clueDataModule)
local Config = require(configModule)
local LetterData = require(letterDataModule)
local HelpRequest = require(helpRequestModule)
local Inventory = require(inventoryModule)
local Progress = require(progressModule)

local jogador: Player? = nil
local raizJogador: BasePart? = nil
local posicaoOriginal: CFrame? = nil
local portaFinal: BasePart? = nil
local abertaOriginal: boolean? = nil

local function valorData(data: string): number
    local diaTexto, mesTexto, anoTexto = string.match(data, "^(%d%d)/(%d%d)/(%d%d%d%d)$")
    local dia = tonumber(diaTexto)
    local mes = tonumber(mesTexto)
    local ano = tonumber(anoTexto)
    assert(dia ~= nil and mes ~= nil and ano ~= nil, `Data inválida na carta: {data}`)
    return ano * 10000 + mes * 100 + dia
end

return function(): ()
    local ambienteTeste = getfenv() :: any
    local describe = ambienteTeste.describe
    local it = ambienteTeste.it
    local beforeAll = ambienteTeste.beforeAll
    local beforeEach = ambienteTeste.beforeEach
    local afterAll = ambienteTeste.afterAll

    describe("Fluxo integrado das cartas históricas", function()
        beforeAll(function()
            local jogadores = Players:GetPlayers()
            assert(#jogadores > 0, "Inicie um Play Solo e execute a suíte no servidor.")
            jogador = jogadores[1]

            local inventario = Inventory.obter(jogador :: Player)
            assert(
                #inventario.Chaves == 0 and #inventario.Pistas == 0,
                "Execute a suíte em uma sessão nova, antes de coletar itens."
            )

            local labirinto = workspace:WaitForChild("Labirinto")
            local sala = labirinto:WaitForChild("Sala 214") :: Model
            local piso = sala:WaitForChild("Piso") :: BasePart
            portaFinal = sala.PrimaryPart
            assert(portaFinal ~= nil, "A Sala 214 precisa ter uma porta principal.")
            assert(
                portaFinal:GetAttribute("ProgressaoValidadaPeloServidor") == true,
                "A progressão da Sala 214 ainda não foi inicializada pelo servidor."
            )
            -- O runner TestEZ tem seu próprio contexto de módulos no Studio.
            Progress.inicializar(sala)
            abertaOriginal = portaFinal:GetAttribute("Aberta") == true

            local personagem = (jogador :: Player).Character
            assert(personagem ~= nil, "O personagem do jogador ainda não foi criado.")
            local raiz = personagem:FindFirstChild("HumanoidRootPart")
            assert(raiz ~= nil and raiz:IsA("BasePart"), "O personagem não tem HumanoidRootPart.")
            raizJogador = raiz
            posicaoOriginal = raiz.CFrame
            raiz.CFrame = piso.CFrame * CFrame.new(0, piso.Size.Y / 2 + 3, 0)

            portaFinal:SetAttribute("Aberta", true)
            assert(remotesFolder:IsA("Folder"), "Os remotos do servidor não foram inicializados.")
            HelpRequest.inicializar()
        end)

        beforeEach(function()
            Inventory.resetarTodos()
        end)

        afterAll(function()
            if raizJogador ~= nil and raizJogador.Parent ~= nil and posicaoOriginal ~= nil then
                raizJogador.CFrame = posicaoOriginal
            end
            if portaFinal ~= nil and portaFinal.Parent ~= nil and abertaOriginal ~= nil then
                portaFinal:SetAttribute("Aberta", abertaOriginal)
            end
        end)

        it("01 - associa cada pista ao trecho e à carta correspondentes", function()
            local ambiente = getfenv() :: any
            local expect = ambiente.expect

            for _, pista in ClueData.obterTodas() do
                local carta = LetterData.obterCarta(pista.LetterId)
                expect(carta ~= nil).to.equal(true)
                if carta ~= nil then
                    expect(carta.Trecho).to.equal(pista.Trecho)
                end
            end
        end)

        it("02 - recusa entrada e carta sem inventário suficiente", function()
            local ambiente = getfenv() :: any
            local expect = ambiente.expect
            local jogadorAtual = jogador :: Player

            expect(Progress.validarEntrada(jogadorAtual)).to.equal(false)
            expect(HelpRequest.compilar(jogadorAtual)).to.equal(nil)
        end)

        it("03 - compila a carta depois da coleta completa", function()
            local ambiente = getfenv() :: any
            local expect = ambiente.expect
            local jogadorAtual = jogador :: Player

            for _, chave in Config.Progress.RequiredKeys do
                expect(Inventory.adicionarChave(jogadorAtual, chave)).to.equal(true)
            end
            for _, pista in ClueData.obterTodas() do
                expect(Inventory.adicionarPista(jogadorAtual, pista.Id)).to.equal(true)
            end

            expect(Progress.validarEntrada(jogadorAtual)).to.equal(true)
            local cartaCompilada = HelpRequest.compilar(jogadorAtual)
            expect(cartaCompilada ~= nil).to.equal(true)
            if cartaCompilada == nil then
                return
            end
            expect(cartaCompilada.Total).to.equal(#LetterData.obterTodas())

            Progress.concluir(jogadorAtual)
        end)

        it("04 - compila os trechos em ordem cronológica com fontes", function()
            local ambiente = getfenv() :: any
            local expect = ambiente.expect
            local jogadorAtual = jogador :: Player

            for _, pista in ClueData.obterTodas() do
                Inventory.adicionarPista(jogadorAtual, pista.Id)
            end
            local carta = HelpRequest.compilar(jogadorAtual)

            expect(carta ~= nil).to.equal(true)
            if carta == nil then
                return
            end

            expect(#carta.Trechos).to.equal(carta.Total)
            for indice, item in carta.Trechos do
                expect(item.Fonte ~= "").to.equal(true)
                if indice > 1 then
                    expect(valorData(carta.Trechos[indice - 1].Data) <= valorData(item.Data)).to.equal(true)
                end
            end
        end)
    end)
end
