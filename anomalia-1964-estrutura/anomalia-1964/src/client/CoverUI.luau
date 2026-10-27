--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CoverUI = {}
local guiAtual: ScreenGui? = nil
local ativo = false

local ASSET_CAPA = "rbxassetid://77365543011119"
local COR_FUNDO_PAPEL = Color3.fromRGB(233, 222, 196)

-- Proporções exatas dos 4 botões na arte original (1327x742 px)
-- Y: 589 px a 639 px (H = 50 px)
-- Largura de cada botão = 146 px (146/1327 = 0.1100)
local BOTOES_CONFIG = {
    { Nome = "Jogar", X = 0.0746, W = 0.1100 },
    { Nome = "Continuar", X = 0.1937, W = 0.1100 },
    { Nome = "Galeria", X = 0.3127, W = 0.1100 },
    { Nome = "Opcoes", X = 0.4318, W = 0.1100 },
}

local POSICAO_Y = 0.7938
local ALTURA_BOTAO = 0.0674

local function criarBotaoInvisivelSobreposto(
    nome: string,
    posX: number,
    largura: number,
    container: GuiObject
): TextButton
    local botao = Instance.new("TextButton")
    botao.Name = nome
    botao.Text = "" -- Texto vazio para usar o texto original desenhado na arte
    botao.Position = UDim2.fromScale(posX, POSICAO_Y)
    botao.Size = UDim2.fromScale(largura, ALTURA_BOTAO)
    botao.BackgroundTransparency = 1
    botao.BorderSizePixel = 0
    botao.AutoButtonColor = false
    botao.Active = true
    botao.Parent = container

    -- Efeito sutil de destaque ao passar o mouse por cima do botão desenhado
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.fromScale(1, 1)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    highlight.BackgroundTransparency = 1
    highlight.BorderSizePixel = 0
    highlight.Parent = botao

    botao.MouseEnter:Connect(function()
        highlight.BackgroundTransparency = 0.82
    end)

    botao.MouseLeave:Connect(function()
        highlight.BackgroundTransparency = 1
    end)

    botao.MouseButton1Down:Connect(function()
        highlight.BackgroundTransparency = 0.65
    end)

    botao.MouseButton1Up:Connect(function()
        highlight.BackgroundTransparency = 0.82
    end)

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
            if elemento:IsA("ImageLabel") then
                local tweenImagem = TweenService:Create(elemento, infoTween, {
                    ImageTransparency = 1,
                    BackgroundTransparency = 1,
                })
                tweenImagem:Play()
            elseif elemento:IsA("GuiObject") then
                local tweenObj = TweenService:Create(elemento, infoTween, {
                    BackgroundTransparency = 1,
                })
                tweenObj:Play()
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

    -- Painel de tela cheia sem barras pretas
    local painelPrincipal = Instance.new("Frame")
    painelPrincipal.Name = "PainelPrincipal"
    painelPrincipal.Size = UDim2.fromScale(1, 1)
    painelPrincipal.BackgroundColor3 = COR_FUNDO_PAPEL
    painelPrincipal.BorderSizePixel = 0
    painelPrincipal.Parent = gui

    -- Imagem de capa em tela cheia (ScaleType Crop para preencher sem bordas)
    local imagemCapa = Instance.new("ImageLabel")
    imagemCapa.Name = "ImagemCapa"
    imagemCapa.Size = UDim2.fromScale(1, 1)
    imagemCapa.Position = UDim2.fromScale(0, 0)
    imagemCapa.BackgroundTransparency = 1
    imagemCapa.ScaleType = Enum.ScaleType.Crop
    imagemCapa.Image = ASSET_CAPA
    imagemCapa.Parent = painelPrincipal

    -- Container que espelha o aspect ratio da imagem (1327 / 742) para posicionar os botões
    local containerArte = Instance.new("Frame")
    containerArte.Name = "ContainerArte"
    containerArte.AnchorPoint = Vector2.new(0.5, 0.5)
    containerArte.Position = UDim2.fromScale(0.5, 0.5)
    containerArte.Size = UDim2.fromScale(1, 1)
    containerArte.BackgroundTransparency = 1
    containerArte.BorderSizePixel = 0
    containerArte.Parent = painelPrincipal

    local aspectConstraint = Instance.new("UIAspectRatioConstraint")
    aspectConstraint.AspectRatio = 1327 / 742
    aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
    aspectConstraint.DominantAxis = Enum.DominantAxis.Width
    aspectConstraint.Parent = containerArte

    -- Cria os botões sobrepostos exatamente na posição dos botões da arte
    local botoesInstanciados: { [string]: TextButton } = {}
    for _, cfg in BOTOES_CONFIG do
        local btn = criarBotaoInvisivelSobreposto(cfg.Nome, cfg.X, cfg.W, containerArte)
        botoesInstanciados[cfg.Nome] = btn
    end

    local botaoJogar = botoesInstanciados["Jogar"]
    if botaoJogar ~= nil then
        botaoJogar.MouseButton1Click:Connect(function()
            CoverUI.esconder()
            task.spawn(aoJogar)
        end)
    end

    local botaoContinuar = botoesInstanciados["Continuar"]
    if botaoContinuar ~= nil then
        botaoContinuar.MouseButton1Click:Connect(function()
            -- Mantém na tela de capa sem ação
        end)
    end

    local botaoGaleria = botoesInstanciados["Galeria"]
    if botaoGaleria ~= nil then
        botaoGaleria.MouseButton1Click:Connect(function()
            -- Reservado para galeria
        end)
    end

    local botaoOpcoes = botoesInstanciados["Opcoes"]
    if botaoOpcoes ~= nil then
        botaoOpcoes.MouseButton1Click:Connect(function()
            -- Reservado para opções
        end)
    end

    gui.Parent = playerGui
    return gui
end

return CoverUI
