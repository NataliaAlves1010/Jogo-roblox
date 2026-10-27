--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CoverUI = {}
local guiAtual: ScreenGui? = nil
local ativo = false

local COR_FUNDO = Color3.fromRGB(24, 21, 19)
local COR_VINHO = Color3.fromRGB(139, 30, 45)
local COR_CREME = Color3.fromRGB(240, 230, 207)
local COR_ESCURO = Color3.fromRGB(31, 26, 20)

local function criarBotao(nome: string, texto: string, corFundo: Color3, corTexto: Color3, ordem: number): TextButton
    local botao = Instance.new("TextButton")
    botao.Name = nome
    botao.Text = texto
    botao.Size = UDim2.fromOffset(130, 56)
    botao.BackgroundColor3 = corFundo
    botao.TextColor3 = corTexto
    botao.Font = Enum.Font.SpecialElite
    botao.TextSize = 18
    botao.BorderSizePixel = 1
    botao.BorderColor3 = COR_ESCURO
    botao.AutoButtonColor = true
    botao.LayoutOrder = ordem

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 0)
    uicorner.Parent = botao

    return botao
end

function CoverUI.estaAtivo(): boolean
    return ativo
end

function CoverUI.esconder(): ()
    local gui = guiAtual
    if gui == nil or not ativo then
        return
    end
    ativo = false

    local fundo = gui:FindFirstChild("Fundo")
    local infoTween = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if fundo ~= nil and fundo:IsA("GuiObject") then
        local elementos = fundo:GetDescendants()
        for _, elemento in elementos do
            if elemento:IsA("TextButton") or elemento:IsA("TextLabel") then
                local tweenTexto = TweenService:Create(elemento, infoTween, {
                    TextTransparency = 1,
                    BackgroundTransparency = 1,
                })
                tweenTexto:Play()
            elseif elemento:IsA("ImageLabel") then
                local tweenImagem = TweenService:Create(elemento, infoTween, {
                    ImageTransparency = 1,
                    BackgroundTransparency = 1,
                })
                tweenImagem:Play()
            end
        end

        local tweenFundo = TweenService:Create(fundo, infoTween, {
            BackgroundTransparency = 1,
        })
        tweenFundo.Completed:Connect(function()
            gui.Enabled = false
            gui:Destroy()
            guiAtual = nil
        end)
        tweenFundo:Play()
    else
        gui.Enabled = false
        gui:Destroy()
        guiAtual = nil
    end
end

function CoverUI.montar(aoJogar: () -> ()): ScreenGui
    if guiAtual ~= nil then
        return guiAtual :: ScreenGui
    end

    local jogador = Players.LocalPlayer
    local playerGui = jogador:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "TelaCapa"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    guiAtual = gui
    ativo = true

    local fundo = Instance.new("Frame")
    fundo.Name = "Fundo"
    fundo.Size = UDim2.fromScale(1, 1)
    fundo.BackgroundColor3 = COR_FUNDO
    fundo.BorderSizePixel = 0
    fundo.Parent = gui

    local imagemCapa = Instance.new("ImageLabel")
    imagemCapa.Name = "ImagemCapa"
    imagemCapa.Size = UDim2.fromScale(1, 1)
    imagemCapa.BackgroundTransparency = 1
    imagemCapa.ScaleType = Enum.ScaleType.Crop
    imagemCapa.Image = "rbxasset://assets/ui/capa.png"
    imagemCapa.Parent = fundo

    local containerTitulo = Instance.new("Frame")
    containerTitulo.Name = "ContainerTitulo"
    containerTitulo.Position = UDim2.fromOffset(36, 36)
    containerTitulo.Size = UDim2.fromOffset(480, 100)
    containerTitulo.BackgroundTransparency = 1
    containerTitulo.Parent = fundo

    local labelTitulo = Instance.new("TextLabel")
    labelTitulo.Name = "Titulo"
    labelTitulo.Size = UDim2.new(1, 0, 0, 48)
    labelTitulo.BackgroundTransparency = 1
    labelTitulo.Font = Enum.Font.SpecialElite
    labelTitulo.Text = "ANOMALIA 1964"
    labelTitulo.TextColor3 = COR_CREME
    labelTitulo.TextSize = 40
    labelTitulo.TextXAlignment = Enum.TextXAlignment.Left
    labelTitulo.Parent = containerTitulo

    local labelSubtitulo = Instance.new("TextLabel")
    labelSubtitulo.Name = "Subtitulo"
    labelSubtitulo.Position = UDim2.fromOffset(0, 48)
    labelSubtitulo.Size = UDim2.new(1, 0, 0, 24)
    labelSubtitulo.BackgroundTransparency = 1
    labelSubtitulo.Font = Enum.Font.SpecialElite
    labelSubtitulo.Text = "Brasília, abril de 1964 — Ministério"
    labelSubtitulo.TextColor3 = Color3.fromRGB(180, 170, 150)
    labelSubtitulo.TextSize = 18
    labelSubtitulo.TextXAlignment = Enum.TextXAlignment.Left
    labelSubtitulo.Parent = containerTitulo

    local containerBotoes = Instance.new("Frame")
    containerBotoes.Name = "Botoes"
    containerBotoes.Position = UDim2.new(0, 36, 1, -104)
    containerBotoes.Size = UDim2.new(1, -72, 0, 64)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.Parent = fundo

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 14)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = containerBotoes

    local botaoJogar = criarBotao("Jogar", "JOGAR", COR_VINHO, COR_CREME, 1)
    botaoJogar.Parent = containerBotoes

    local botaoContinuar = criarBotao("Continuar", "CONTINUAR", COR_CREME, COR_ESCURO, 2)
    botaoContinuar.Parent = containerBotoes

    local botaoGaleria = criarBotao("Galeria", "GALERIA", COR_CREME, COR_ESCURO, 3)
    botaoGaleria.Parent = containerBotoes

    local botaoOpcoes = criarBotao("Opcoes", "OPÇÕES", COR_CREME, COR_ESCURO, 4)
    botaoOpcoes.Parent = containerBotoes

    botaoJogar.MouseButton1Click:Connect(function()
        CoverUI.esconder()
        task.spawn(aoJogar)
    end)

    botaoContinuar.MouseButton1Click:Connect(function()
        -- Não executa ação; mantém a tela de capa conforme especificação
    end)

    botaoGaleria.MouseButton1Click:Connect(function()
        -- Espaço reservado para visualização das cartas desbloqueadas
    end)

    botaoOpcoes.MouseButton1Click:Connect(function()
        -- Espaço reservado para configurações
    end)

    gui.Parent = playerGui
    return gui
end

return CoverUI
