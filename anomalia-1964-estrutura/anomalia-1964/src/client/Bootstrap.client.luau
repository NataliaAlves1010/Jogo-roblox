--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript

local Config = require(configModule)
local MazeGrid = require(mazeGridModule)

local AlertHUD = require(script.Parent:WaitForChild("AlertHUD") :: ModuleScript)
local InventoryUI = require(script.Parent:WaitForChild("InventoryUI") :: ModuleScript)
local DialogueUI = require(script.Parent:WaitForChild("DialogueUI") :: ModuleScript)
local EndingUI = require(script.Parent:WaitForChild("EndingUI") :: ModuleScript)
local HelpRequestUI = require(script.Parent:WaitForChild("HelpRequestUI") :: ModuleScript)
local ZoneAtmosphere = require(script.Parent:WaitForChild("ZoneAtmosphere") :: ModuleScript)
local PlayerMovement = require(script.Parent:WaitForChild("PlayerMovement") :: ModuleScript)
local CluesClient = require(script.Parent:WaitForChild("CluesClient") :: ModuleScript)
local ClueToastUI = require(script.Parent:WaitForChild("ClueToastUI") :: ModuleScript)
local CoverUI = require(script.Parent:WaitForChild("CoverUI") :: ModuleScript)
local MapUI = require(script.Parent:WaitForChild("MapUI") :: ModuleScript)

local jogador = Players.LocalPlayer

local function travarMovimento(): ()
    local personagem = jogador.Character
    if personagem == nil then
        return
    end
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    if humanoide ~= nil then
        humanoide.WalkSpeed = 0
        humanoide.JumpPower = 0
    end
end

local function liberarMovimento(): ()
    local personagem = jogador.Character
    if personagem == nil then
        return
    end
    local humanoide = personagem:FindFirstChildOfClass("Humanoid")
    if humanoide ~= nil then
        humanoide.WalkSpeed = 16
        humanoide.JumpPower = 50
    end
end

local function obterGradeDoMundo(): MazeGrid.Grade
    local grade = MazeGrid.criar(Config.Maze.Rows, Config.Maze.Columns, Config.Maze.Seed)
    local labirinto = workspace:WaitForChild("Labirinto", 10)
    if labirinto ~= nil then
        local prazo = os.clock() + Config.Map.LayoutReadyTimeout
        while labirinto:GetAttribute("MapaPronto") ~= true and os.clock() < prazo do
            task.wait()
        end

        if labirinto:GetAttribute("MapaPronto") == true then
            local quantidadeEsperada = labirinto:GetAttribute("QuantidadeParedes")
            while typeof(quantidadeEsperada) ~= "number" and os.clock() < prazo do
                task.wait()
                quantidadeEsperada = labirinto:GetAttribute("QuantidadeParedes")
            end

            local quantidadeRecebida = 0
            local conexaoParedes = labirinto.DescendantAdded:Connect(function(descendente: Instance)
                if string.sub(descendente.Name, 1, 6) == "Parede" then
                    quantidadeRecebida += 1
                end
            end)
            for _, descendente in labirinto:GetDescendants() do
                if string.sub(descendente.Name, 1, 6) == "Parede" then
                    quantidadeRecebida += 1
                end
            end

            while
                typeof(quantidadeEsperada) == "number"
                and quantidadeRecebida < quantidadeEsperada
                and os.clock() < prazo
            do
                task.wait()
            end
            conexaoParedes:Disconnect()

            if typeof(quantidadeEsperada) == "number" and quantidadeRecebida >= quantidadeEsperada then
                for linha = 1, Config.Maze.Rows do
                    for coluna = 1, Config.Maze.Columns do
                        local sufixo = string.format("_%d_%d", linha, coluna)
                        grade.Celulas[linha][coluna].Norte = labirinto:FindFirstChild("ParedeNorte" .. sufixo, true)
                            ~= nil
                        grade.Celulas[linha][coluna].Leste = labirinto:FindFirstChild("ParedeLeste" .. sufixo, true)
                            ~= nil
                        grade.Celulas[linha][coluna].Sul = labirinto:FindFirstChild("ParedeSul" .. sufixo, true) ~= nil
                        grade.Celulas[linha][coluna].Oeste = labirinto:FindFirstChild("ParedeOeste" .. sufixo, true)
                            ~= nil
                    end
                end
            else
                warn("As paredes do labirinto não replicaram a tempo para desenhar o mapa completo.")
            end
        else
            warn("O labirinto não ficou pronto a tempo de desenhar as paredes do mapa.")
        end
    end
    return grade
end

AlertHUD.inicializar()
InventoryUI.inicializar()
DialogueUI.inicializar()
EndingUI.inicializar()
HelpRequestUI.inicializar()
ZoneAtmosphere.inicializar()
PlayerMovement.inicializar()
CluesClient.inicializar()
ClueToastUI.inicializar()

local gradeLabirinto = obterGradeDoMundo()
MapUI.inicializar(gradeLabirinto)

travarMovimento()
jogador.CharacterAdded:Connect(function()
    if CoverUI.estaAtivo() then
        task.defer(travarMovimento)
    end
end)

CoverUI.montar(function()
    liberarMovimento()
end)
