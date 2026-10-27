--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local mazeGridModule = sharedFolder:WaitForChild("MazeGrid") :: ModuleScript

local Config = require(configModule)
local MazeGrid = require(mazeGridModule)

type Grade = MazeGrid.Grade

local MapUI = {}
local guiAtual: ScreenGui? = nil
local painelMapa: Frame? = nil
local pinoJogador: Frame? = nil
local containerGrade: Frame? = nil
local conexaoRender: RBXScriptConnection? = nil
local gradeAtual: Grade? = nil
local visivel = false

local jogador = Players.LocalPlayer

local function obterCorZona(linha: number, coluna: number, linhasTotal: number, colunasTotal: number): Color3
    local meioLinha = math.floor(linhasTotal / 2)
    local meioColuna = math.floor(colunasTotal / 2)

    -- Centro do labirinto (Sala 214)
    if math.abs(linha - (meioLinha + 1)) <= 1 and math.abs(coluna - (meioColuna + 1)) <= 1 then
        return Config.Map.ZoneColors.GoalRoom
    end

    if linha <= meioLinha then
        if coluna <= meioColuna then
            return Config.Map.ZoneColors.Recepcao
        else
            return Config.Map.ZoneColors.Arquivo
        end
    else
        if coluna <= meioColuna then
            return Config.Map.ZoneColors.Subsolo
        else
            return Config.Map.ZoneColors.Gabinete
        end
    end
end

local function atualizarPosicaoJogador(): ()
    if not visivel or pinoJogador == nil or containerGrade == nil or gradeAtual == nil then
        return
    end

    local personagem = jogador.Character
    if personagem == nil then
        return
    end

    local raiz = personagem:FindFirstChild("HumanoidRootPart")
    if raiz == nil or not raiz:IsA("BasePart") then
        return
    end

    local posMundo = raiz.Position
    local configLabirinto = Config.Maze
    local tamanhoCelula = configLabirinto.CellSize
    local larguraTotal = gradeAtual.Colunas * tamanhoCelula
    local profundidadeTotal = gradeAtual.Linhas * tamanhoCelula

    -- Converte coordenadas 3D do mundo para proporção [0, 1] no mapa
    local normX = math.clamp((posMundo.X + larguraTotal / 2) / larguraTotal, 0, 1)
    local normY = math.clamp((posMundo.Z + profundidadeTotal / 2) / profundidadeTotal, 0, 1)

    pinoJogador.Position = UDim2.fromScale(normX, normY)

    -- Direção do olhar
    local vetorOlhar = raiz.CFrame.LookVector
    local anguloGraus = math.deg(math.atan2(vetorOlhar.X, -vetorOlhar.Z))
    pinoJogador.Rotation = anguloGraus
end

function MapUI.alternarVisibilidade(): ()
    visivel = not visivel

    if painelMapa ~= nil then
        painelMapa.Visible = visivel
    end

    if visivel then
        if conexaoRender == nil then
            conexaoRender = RunService.RenderStepped:Connect(atualizarPosicaoJogador)
        end
        atualizarPosicaoJogador()
    else
        if conexaoRender ~= nil then
            conexaoRender:Disconnect()
            conexaoRender = nil
        end
    end
end

local function criarItemLegenda(parent: Instance, texto: string, cor: Color3, ordem: number): ()
    local item = Instance.new("Frame")
    item.Name = "ItemLegenda_" .. texto
    item.Size = UDim2.new(1, 0, 0, 22)
    item.BackgroundTransparency = 1
    item.LayoutOrder = ordem
    item.Parent = parent

    local amostra = Instance.new("Frame")
    amostra.Name = "Amostra"
    amostra.Size = UDim2.fromOffset(14, 14)
    amostra.Position = UDim2.fromOffset(0, 4)
    amostra.BackgroundColor3 = cor
    amostra.BorderSizePixel = 1
    amostra.BorderColor3 = Color3.fromRGB(30, 26, 22)
    amostra.Parent = item

    local label = Instance.new("TextLabel")
    label.Name = "Texto"
    label.Position = UDim2.fromOffset(22, 0)
    label.Size = UDim2.new(1, -24, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.RobotoMono
    label.Text = texto
    label.TextColor3 = Color3.fromRGB(240, 230, 207)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = item
end

function MapUI.inicializar(grade: Grade): ()
    if guiAtual ~= nil then
        return
    end

    gradeAtual = grade
    local playerGui = jogador:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "TelaMapa"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20
    guiAtual = gui

    -- Botão rápido no HUD para abrir/fechar mapa
    local botaoHud = Instance.new("TextButton")
    botaoHud.Name = "BotaoAbrirMapa"
    botaoHud.AnchorPoint = Vector2.new(1, 0)
    botaoHud.Position = UDim2.new(1, -20, 0, 20)
    botaoHud.Size = UDim2.fromOffset(110, 36)
    botaoHud.BackgroundColor3 = Color3.fromRGB(36, 32, 28)
    botaoHud.TextColor3 = Color3.fromRGB(240, 230, 207)
    botaoHud.Font = Enum.Font.RobotoMono
    botaoHud.TextSize = 14
    botaoHud.Text = "MAPA [M]"
    botaoHud.BorderSizePixel = 1
    botaoHud.BorderColor3 = Color3.fromRGB(240, 230, 207)
    botaoHud.Parent = gui

    local cornerHud = Instance.new("UICorner")
    cornerHud.CornerRadius = UDim.new(0, 4)
    cornerHud.Parent = botaoHud

    botaoHud.MouseButton1Click:Connect(function()
        MapUI.alternarVisibilidade()
    end)

    -- Painel em Tela Cheia do Mapa
    local painel = Instance.new("Frame")
    painel.Name = "PainelCheio"
    painel.Size = UDim2.fromScale(1, 1)
    painel.BackgroundColor3 = Color3.fromRGB(16, 14, 12)
    painel.BackgroundTransparency = 0.15
    painel.BorderSizePixel = 0
    painel.Visible = false
    painel.Parent = gui
    painelMapa = painel

    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Position = UDim2.fromOffset(30, 20)
    titulo.Size = UDim2.new(1, -60, 0, 32)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.SpecialElite
    titulo.Text = "PLANTA DO MINISTÉRIO — BRASÍLIA, 1964"
    titulo.TextColor3 = Color3.fromRGB(240, 230, 207)
    titulo.TextSize = 22
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = painel

    local subtitulo = Instance.new("TextLabel")
    subtitulo.Name = "Subtitulo"
    subtitulo.Position = UDim2.fromOffset(30, 52)
    subtitulo.Size = UDim2.new(1, -60, 0, 20)
    subtitulo.BackgroundTransparency = 1
    subtitulo.Font = Enum.Font.RobotoMono
    subtitulo.Text = "Aperte [M] para fechar o mapa"
    subtitulo.TextColor3 = Color3.fromRGB(180, 170, 150)
    subtitulo.TextSize = 13
    subtitulo.TextXAlignment = Enum.TextXAlignment.Left
    subtitulo.Parent = painel

    local botaoFechar = Instance.new("TextButton")
    botaoFechar.Name = "BotaoFechar"
    botaoFechar.AnchorPoint = Vector2.new(1, 0)
    botaoFechar.Position = UDim2.new(1, -30, 0, 20)
    botaoFechar.Size = UDim2.fromOffset(100, 36)
    botaoFechar.BackgroundColor3 = Color3.fromRGB(139, 30, 45)
    botaoFechar.TextColor3 = Color3.fromRGB(240, 230, 207)
    botaoFechar.Font = Enum.Font.RobotoMono
    botaoFechar.TextSize = 14
    botaoFechar.Text = "FECHAR"
    botaoFechar.BorderSizePixel = 1
    botaoFechar.BorderColor3 = Color3.fromRGB(30, 26, 22)
    botaoFechar.Parent = painel

    botaoFechar.MouseButton1Click:Connect(function()
        MapUI.alternarVisibilidade()
    end)

    -- Painel Lateral de Legenda
    local painelLegenda = Instance.new("Frame")
    painelLegenda.Name = "Legenda"
    painelLegenda.AnchorPoint = Vector2.new(0, 0.5)
    painelLegenda.Position = UDim2.new(0, 30, 0.55, 0)
    painelLegenda.Size = UDim2.fromOffset(180, 220)
    painelLegenda.BackgroundColor3 = Color3.fromRGB(26, 23, 20)
    painelLegenda.BorderSizePixel = 1
    painelLegenda.BorderColor3 = Color3.fromRGB(60, 52, 44)
    painelLegenda.Parent = painel

    local tituloLegenda = Instance.new("TextLabel")
    tituloLegenda.Name = "TituloLegenda"
    tituloLegenda.Size = UDim2.new(1, 0, 0, 28)
    tituloLegenda.BackgroundTransparency = 1
    tituloLegenda.Font = Enum.Font.SpecialElite
    tituloLegenda.Text = "ZONAS"
    tituloLegenda.TextColor3 = Color3.fromRGB(240, 230, 207)
    tituloLegenda.TextSize = 16
    tituloLegenda.Parent = painelLegenda

    local listaLegenda = Instance.new("Frame")
    listaLegenda.Name = "Lista"
    listaLegenda.Position = UDim2.fromOffset(12, 34)
    listaLegenda.Size = UDim2.new(1, -24, 1, -40)
    listaLegenda.BackgroundTransparency = 1
    listaLegenda.Parent = painelLegenda

    local layoutLegenda = Instance.new("UIListLayout")
    layoutLegenda.SortOrder = Enum.SortOrder.LayoutOrder
    layoutLegenda.Padding = UDim.new(0, 6)
    layoutLegenda.Parent = listaLegenda

    criarItemLegenda(listaLegenda, "Recepção", Config.Map.ZoneColors.Recepcao, 1)
    criarItemLegenda(listaLegenda, "Arquivo", Config.Map.ZoneColors.Arquivo, 2)
    criarItemLegenda(listaLegenda, "Subsolo", Config.Map.ZoneColors.Subsolo, 3)
    criarItemLegenda(listaLegenda, "Gabinete", Config.Map.ZoneColors.Gabinete, 4)
    criarItemLegenda(listaLegenda, "Sala 214", Config.Map.ZoneColors.GoalRoom, 5)
    criarItemLegenda(listaLegenda, "Você", Config.Map.PlayerPinColor, 6)

    -- Área Central Quadrada da Grade
    local areaGrade = Instance.new("Frame")
    areaGrade.Name = "AreaGrade"
    areaGrade.AnchorPoint = Vector2.new(0.5, 0.5)
    areaGrade.Position = UDim2.fromScale(0.55, 0.55)
    areaGrade.Size = UDim2.fromScale(0.72, 0.72)
    areaGrade.BackgroundColor3 = Config.Map.WallColor
    areaGrade.BorderSizePixel = 2
    areaGrade.BorderColor3 = Color3.fromRGB(240, 230, 207)
    areaGrade.Parent = painel
    containerGrade = areaGrade

    local aspectGrade = Instance.new("UIAspectRatioConstraint")
    aspectGrade.AspectRatio = grade.Colunas / grade.Linhas
    aspectGrade.AspectType = Enum.AspectType.FitWithinMaxSize
    aspectGrade.DominantAxis = Enum.DominantAxis.Height
    aspectGrade.Parent = areaGrade

    -- Constrói as 31x31 células
    local larguraCelula = 1 / grade.Colunas
    local alturaCelula = 1 / grade.Linhas

    for linha = 1, grade.Linhas do
        for coluna = 1, grade.Colunas do
            local celulaFrame = Instance.new("Frame")
            celulaFrame.Name = string.format("C_%d_%d", linha, coluna)
            celulaFrame.Position = UDim2.fromScale((coluna - 1) * larguraCelula, (linha - 1) * alturaCelula)
            celulaFrame.Size = UDim2.fromScale(larguraCelula, alturaCelula)
            celulaFrame.BackgroundColor3 = obterCorZona(linha, coluna, grade.Linhas, grade.Colunas)
            celulaFrame.BorderSizePixel = 0
            celulaFrame.Parent = areaGrade

            -- Paredes representadas como linhas finas escuras
            if MazeGrid.temParede(grade, linha, coluna, "Norte") then
                local bordaNorte = Instance.new("Frame")
                bordaNorte.Name = "W_Norte"
                bordaNorte.Size = UDim2.new(1, 0, 0, 1)
                bordaNorte.Position = UDim2.fromScale(0, 0)
                bordaNorte.BackgroundColor3 = Config.Map.WallColor
                bordaNorte.BorderSizePixel = 0
                bordaNorte.ZIndex = 2
                bordaNorte.Parent = celulaFrame
            end

            if MazeGrid.temParede(grade, linha, coluna, "Oeste") then
                local bordaOeste = Instance.new("Frame")
                bordaOeste.Name = "W_Oeste"
                bordaOeste.Size = UDim2.new(0, 1, 1, 0)
                bordaOeste.Position = UDim2.fromScale(0, 0)
                bordaOeste.BackgroundColor3 = Config.Map.WallColor
                bordaOeste.BorderSizePixel = 0
                bordaOeste.ZIndex = 2
                bordaOeste.Parent = celulaFrame
            end
        end
    end

    -- Pino indicador do jogador em tempo real
    local pino = Instance.new("Frame")
    pino.Name = "PinoJogador"
    pino.AnchorPoint = Vector2.new(0.5, 0.5)
    pino.Position = UDim2.fromScale(0.5, 0.5)
    pino.Size = UDim2.fromOffset(12, 12)
    pino.BackgroundColor3 = Config.Map.PlayerPinColor
    pino.BorderSizePixel = 1
    pino.BorderColor3 = Color3.fromRGB(255, 255, 255)
    pino.ZIndex = 10
    pino.Parent = areaGrade
    pinoJogador = pino

    local cornerPino = Instance.new("UICorner")
    cornerPino.CornerRadius = UDim.new(1, 0)
    cornerPino.Parent = pino

    -- Ponta indicadora da direção (seta)
    local seta = Instance.new("Frame")
    seta.Name = "Seta"
    seta.AnchorPoint = Vector2.new(0.5, 1)
    seta.Position = UDim2.fromScale(0.5, 0)
    seta.Size = UDim2.fromOffset(4, 7)
    seta.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    seta.BorderSizePixel = 0
    seta.ZIndex = 11
    seta.Parent = pino

    -- Tecla de atalho M
    UserInputService.InputBegan:Connect(function(input: InputObject, processado: boolean)
        if processado then
            return
        end

        if input.KeyCode == Config.Map.ToggleKey then
            MapUI.alternarVisibilidade()
        end
    end)

    gui.Parent = playerGui
end

return MapUI
