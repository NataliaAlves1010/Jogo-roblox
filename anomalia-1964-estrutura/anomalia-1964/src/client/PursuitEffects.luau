--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local configModule = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local PursuitEffects = {}

local jogador = Players.LocalPlayer
local guarda: Model? = nil
local conexoesGuardas: { [Model]: RBXScriptConnection } = {}
local vinhetaGui: ScreenGui? = nil
local bordasVinheta: { Frame } = {}
local desfoque: BlurEffect? = nil
local correcao: ColorCorrectionEffect? = nil
local distorcaoAtiva = false
local proximaDistorcao = 0
local inicializado = false

local function criarBorda(parent: Instance, nome: string, posicao: UDim2, tamanho: UDim2, rotacao: number): Frame
    local borda = Instance.new("Frame")
    borda.Name = nome
    borda.Position = posicao
    borda.Size = tamanho
    borda.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
    borda.BackgroundTransparency = 0.5
    borda.BorderSizePixel = 0
    borda.ZIndex = 2
    borda.Parent = parent

    local gradiente = Instance.new("UIGradient")
    gradiente.Rotation = rotacao
    gradiente.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradiente.Parent = borda
    table.insert(bordasVinheta, borda)
    return borda
end

local function criarInterface(): ()
    local playerGui = jogador:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "EfeitosPerseguicao"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 15
    gui.Enabled = false
    gui.Parent = playerGui
    vinhetaGui = gui

    criarBorda(gui, "VinhetaSuperior", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.28), 90)
    criarBorda(gui, "VinhetaInferior", UDim2.fromScale(0, 0.72), UDim2.fromScale(1, 0.28), 270)
    criarBorda(gui, "VinhetaEsquerda", UDim2.fromScale(0, 0), UDim2.fromScale(0.2, 1), 0)
    criarBorda(gui, "VinhetaDireita", UDim2.fromScale(0.8, 0), UDim2.fromScale(0.2, 1), 180)

    local blur = Instance.new("BlurEffect")
    blur.Name = "DistorcaoPerseguicao"
    blur.Size = 0
    blur.Parent = Lighting
    desfoque = blur

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "CorPerseguicao"
    color.Saturation = 0
    color.Contrast = 0
    color.Parent = Lighting
    correcao = color
end

local function conectarGuarda(objeto: Instance): ()
    if not objeto:IsA("Model") or objeto.Name ~= "Guarda" or objeto:FindFirstChildOfClass("Humanoid") == nil then
        return
    end
    if conexoesGuardas[objeto] ~= nil then
        return
    end

    local modelo = objeto
    conexoesGuardas[modelo] = modelo:GetAttributeChangedSignal("AlvoPerseguicaoUserId"):Connect(function()
        if guarda == modelo and modelo:GetAttribute("AlvoPerseguicaoUserId") ~= jogador.UserId then
            guarda = nil
        end
    end)
    modelo.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            local conexao = conexoesGuardas[modelo]
            if conexao ~= nil then
                conexao:Disconnect()
                conexoesGuardas[modelo] = nil
            end
            if guarda == modelo then
                guarda = nil
            end
        end
    end)
end

local function dispararDistorcao(agora: number): ()
    local blur = desfoque
    local color = correcao
    if blur == nil or color == nil then
        return
    end

    proximaDistorcao = agora + Config.PursuitEffects.DistortionInterval
    if distorcaoAtiva then
        return
    end
    distorcaoAtiva = true
    blur.Size = Config.PursuitEffects.DistortionBlurSize
    color.Saturation = Config.PursuitEffects.DistortionSaturation
    color.Contrast = Config.PursuitEffects.DistortionContrast
    local tweenInfo =
        TweenInfo.new(Config.PursuitEffects.DistortionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenBlur = TweenService:Create(blur, tweenInfo, { Size = 0 })
    local tweenColor = TweenService:Create(color, tweenInfo, { Saturation = 0, Contrast = 0 })
    tweenColor.Completed:Once(function()
        distorcaoAtiva = false
    end)
    tweenBlur:Play()
    tweenColor:Play()
end

local function atualizar(agora: number): ()
    local alvoGuarda = guarda
    local personagem = jogador.Character
    local raizJogador = if personagem ~= nil then personagem:FindFirstChild("HumanoidRootPart") else nil
    local raizGuarda = if alvoGuarda ~= nil then alvoGuarda:FindFirstChild("HumanoidRootPart") else nil
    local gui = vinhetaGui
    if
        alvoGuarda == nil
        or alvoGuarda.Parent == nil
        or alvoGuarda:GetAttribute("AlvoPerseguicaoUserId") ~= jogador.UserId
        or raizJogador == nil
        or not raizJogador:IsA("BasePart")
        or raizGuarda == nil
        or not raizGuarda:IsA("BasePart")
        or gui == nil
    then
        if gui ~= nil then
            gui.Enabled = false
        end
        return
    end

    gui.Enabled = true
    local distancia = (raizJogador.Position - raizGuarda.Position).Magnitude
    local intensidade = 1 - math.clamp(distancia / Config.PursuitEffects.DistanceForMaximumIntensity, 0, 1)
    local pulso = (math.sin(agora * Config.PursuitEffects.VignettePulseSpeed) + 1) / 2
    local opacidade = Config.PursuitEffects.VignetteMinimumOpacity
        + intensidade * (Config.PursuitEffects.VignetteMaximumOpacity - Config.PursuitEffects.VignetteMinimumOpacity)
        + pulso * Config.PursuitEffects.VignettePulseAmount * intensidade
    for _, borda in bordasVinheta do
        borda.BackgroundTransparency = 1 - math.clamp(opacidade, 0, 0.85)
    end

    if agora >= proximaDistorcao then
        dispararDistorcao(agora)
    end

    local camera = Workspace.CurrentCamera
    if camera ~= nil then
        local amplitude = intensidade * Config.PursuitEffects.CameraShakeMaximumOffset
        local angulo = math.rad(intensidade * Config.PursuitEffects.CameraShakeMaximumAngleDegrees)
        local deslocamento = Vector3.new(math.sin(agora * 31) * amplitude, math.cos(agora * 37) * amplitude, 0)
        local rotacao = CFrame.Angles(math.sin(agora * 29) * angulo, 0, math.cos(agora * 33) * angulo)
        camera.CFrame = camera.CFrame * CFrame.new(deslocamento) * rotacao
    end
end

function PursuitEffects.inicializar(): ()
    if inicializado then
        return
    end
    inicializado = true
    criarInterface()
    for _, objeto in Workspace:GetDescendants() do
        conectarGuarda(objeto)
    end
    Workspace.DescendantAdded:Connect(conectarGuarda)
    RunService:BindToRenderStep("EfeitosPerseguicao", Enum.RenderPriority.Camera.Value + 1, function()
        atualizar(os.clock())
    end)

    task.spawn(function()
        while inicializado do
            for modelo in conexoesGuardas do
                if modelo:GetAttribute("AlvoPerseguicaoUserId") == jogador.UserId then
                    guarda = modelo
                    break
                end
            end
            task.wait(0.2)
        end
    end)
end

return PursuitEffects
