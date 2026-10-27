--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CoverUI = {}
local guiAtual: ScreenGui? = nil
local ativo = false

local ASSET_CAPA = "rbxassetid://98867738852278"
local COR_FUNDO_PAPEL = Color3.fromRGB(233, 222, 196)
local COR_VINHO = Color3.fromRGB(139, 30, 45)
local COR_CREME = Color3.fromRGB(240, 230, 207)
local COR_ESCURO = Color3.fromRGB(31, 26, 20)

local function criarBotao(nome: string, texto: string, corFundo: Color3, corTexto: Color3, ordem: number): TextButton
    local botao = Instance.new("TextButton")
    botao.Name = nome
    botao.Text = texto
    botao.Size = UDim2.fromScale(0.235, 1)
    botao.BackgroundColor3 = corFundo
    botao.TextColor3 = corTexto
    botao.Font = Enum.Font.RobotoMono
    botao.TextSize = 18
    botao.BorderSizePixel = 2
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

    local painelPrincipal = gui:FindFirstChild("PainelPrincipal")
    local infoTween = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if painelPrincipal ~= nil and painelPrincipal:IsA("GuiObject") then
        local elementos = painelPrincipal:GetDescendants()
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

        local tweenPainel = TweenService:Create(painelPrincipal, infoTween, {
            BackgroundTransparency = 1,
        })
        tweenPainel.Completed:Connect(function()
            gui.Enabled = false
            gui:Destroy()
            guiAtual = nil
        end)
        tweenPainel:Play()
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
    gui.DisplayOrder = 100
    guiAtual = gui
    ativo = true

    local painelPrincipal = Instance.new("Frame")
    painelPrincipal.Name = "PainelPrincipal"
    painelPrincipal.Size = UDim2.fromScale(1, 1)
    painelPrincipal.BackgroundColor3 = COR_FUNDO_PAPEL
    painelPrincipal.BorderSizePixel = 0
    painelPrincipal.Parent = gui

    local imagemCapa = Instance.new("ImageLabel")
    imagemCapa.Name = "ImagemCapa"
    imagemCapa.Size = UDim2.fromScale(1, 1)
    imagemCapa.Position = UDim2.fromScale(0, 0)
    imagemCapa.BackgroundTransparency = 1
    imagemCapa.ScaleType = Enum.ScaleType.Crop
    imagemCapa.Image = ASSET_CAPA
    imagemCapa.Parent = painelPrincipal

    local containerArte = Instance.new("Frame")
    containerArte.Name = "ContainerArte"
    containerArte.AnchorPoint = Vector2.new(0.5, 0.5)
    containerArte.Position = UDim2.fromScale(0.5, 0.5)
    containerArte.Size = UDim2.fromScale(1, 1)
    containerArte.BackgroundTransparency = 1
    containerArte.BorderSizePixel = 0
    containerArte.Parent = painelPrincipal

    local aspectConstraint = Instance.new("UIAspectRatioConstraint")
    aspectConstraint.AspectRatio = 1024 / 572
    aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
    aspectConstraint.DominantAxis = Enum.DominantAxis.Width
    aspectConstraint.Parent = containerArte

    -- Container dos 4 botões posicionado exatamente onde ficavam na arte antiga
    local containerBotoes = Instance.new("Frame")
    containerBotoes.Name = "Botoes"
    containerBotoes.Position = UDim2.fromScale(0.075, 0.795)
    containerBotoes.Size = UDim2.fromScale(0.47, 0.075)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.Parent = containerArte

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0.02, 0)
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
        -- Não executa ação; mantém na capa conforme regra
    end)

    botaoGaleria.MouseButton1Click:Connect(function()
        -- Espaço reservado para galeria
    end)

    botaoOpcoes.MouseButton1Click:Connect(function()
        -- Espaço reservado para opções
    end)

    gui.Parent = playerGui
    return gui
end

return CoverUI
