--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local configModule = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local Animation = {}

type Controle = {
    Conexoes: { RBXScriptConnection },
    Faixas: { [string]: AnimationTrack },
    FaixaAtual: AnimationTrack?,
    Velocidade: number,
    Ativo: boolean,
}

local controles: { [Model]: Controle } = {}

local function carregarFaixa(
    animador: Animator,
    nome: string,
    id: string,
    prioridade: Enum.AnimationPriority
): AnimationTrack?
    local animacao = Instance.new("Animation")
    animacao.Name = nome
    animacao.AnimationId = id

    local sucesso, faixa = pcall(function(): AnimationTrack
        return animador:LoadAnimation(animacao)
    end)
    animacao:Destroy()

    if not sucesso then
        warn(string.format("Não foi possível carregar a animação %s do guarda.", nome))
        return nil
    end

    faixa.Looped = true
    faixa.Priority = prioridade
    return faixa
end

local function encerrar(guarda: Model, controle: Controle): ()
    if not controle.Ativo then
        return
    end

    controle.Ativo = false
    for _, conexao in controle.Conexoes do
        conexao:Disconnect()
    end
    for _, faixa in controle.Faixas do
        faixa:Stop(Config.GuardAnimations.FadeDuration)
        faixa:Destroy()
    end
    if controles[guarda] == controle then
        controles[guarda] = nil
    end
end

local function atualizar(guarda: Model, controle: Controle): ()
    if not controle.Ativo then
        return
    end

    local nomeFaixa = "Idle"
    if controle.Velocidade > 0.5 then
        nomeFaixa = if guarda:GetAttribute("EstadoGuarda") == "Perseguição" then "Run" else "Walk"
    end

    local proximaFaixa = controle.Faixas[nomeFaixa]
    if proximaFaixa == nil or proximaFaixa == controle.FaixaAtual then
        return
    end

    local duracaoTransicao = Config.GuardAnimations.FadeDuration
    if controle.FaixaAtual ~= nil then
        controle.FaixaAtual:Stop(duracaoTransicao)
    end
    controle.FaixaAtual = proximaFaixa
    proximaFaixa:Play(duracaoTransicao)
    if nomeFaixa == "Walk" then
        proximaFaixa:AdjustSpeed(math.clamp(controle.Velocidade / 8, 0.75, 1.8))
    elseif nomeFaixa == "Run" then
        proximaFaixa:AdjustSpeed(math.clamp(controle.Velocidade / 16, 0.75, 1.4))
    end
end

function Animation.inicializar(guarda: Model): ()
    if controles[guarda] ~= nil then
        return
    end

    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    if humanoide == nil then
        return
    end

    local animador = humanoide:FindFirstChildOfClass("Animator") :: Animator?
    if animador == nil then
        animador = Instance.new("Animator")
        animador.Parent = humanoide
    end

    local configuracao = Config.GuardAnimations
    local faixas: { [string]: AnimationTrack } = {}
    local configuracoes = {
        { Nome = "Idle", Id = configuracao.IdleAnimationId, Prioridade = Enum.AnimationPriority.Idle },
        { Nome = "Walk", Id = configuracao.WalkAnimationId, Prioridade = Enum.AnimationPriority.Movement },
        { Nome = "Run", Id = configuracao.RunAnimationId, Prioridade = Enum.AnimationPriority.Movement },
    }
    for _, item in configuracoes do
        local faixa = carregarFaixa(animador, item.Nome, item.Id, item.Prioridade)
        if faixa ~= nil then
            faixas[item.Nome] = faixa
        end
    end

    local controle: Controle = {
        Conexoes = {},
        Faixas = faixas,
        FaixaAtual = nil,
        Velocidade = 0,
        Ativo = true,
    }
    controles[guarda] = controle
    table.insert(
        controle.Conexoes,
        humanoide.Running:Connect(function(velocidade)
            controle.Velocidade = velocidade
            atualizar(guarda, controle)
        end)
    )
    table.insert(
        controle.Conexoes,
        guarda:GetAttributeChangedSignal("EstadoGuarda"):Connect(function()
            atualizar(guarda, controle)
        end)
    )
    table.insert(
        controle.Conexoes,
        guarda.Destroying:Connect(function()
            encerrar(guarda, controle)
        end)
    )
    table.insert(
        controle.Conexoes,
        humanoide.Died:Connect(function()
            encerrar(guarda, controle)
        end)
    )
    atualizar(guarda, controle)
end

return Animation
