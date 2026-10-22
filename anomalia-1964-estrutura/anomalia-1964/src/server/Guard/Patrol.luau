--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configModule = sharedFolder:WaitForChild("Config") :: ModuleScript
local Config = require(configModule)

local Patrol = {}

type Waypoint = {
    Posicao: Vector3,
}

type Controle = {
    Ativo: boolean,
    EventoAtual: BindableEvent?,
}

local controles: { [Model]: Controle } = {}

local function chave(linha: number, coluna: number): string
    return string.format("%d_%d", linha, coluna)
end

local function coletarWaypoints(mapa: Folder, humanoide: Humanoid, raiz: BasePart): { Waypoint }
    local pisos: { [string]: BasePart } = {}
    local paredesNorte: { [string]: boolean } = {}
    local paredesOeste: { [string]: boolean } = {}

    for _, objeto in mapa:GetDescendants() do
        if objeto:IsA("BasePart") then
            local linhaPiso, colunaPiso = string.match(objeto.Name, "^Piso_(%d+)_(%d+)$")
            local linhaParedeNorte, colunaParedeNorte = string.match(objeto.Name, "^ParedeNorte_(%d+)_(%d+)$")
            local linhaParedeOeste, colunaParedeOeste = string.match(objeto.Name, "^ParedeOeste_(%d+)_(%d+)$")

            if linhaPiso ~= nil and colunaPiso ~= nil then
                pisos[chave(tonumber(linhaPiso) :: number, tonumber(colunaPiso) :: number)] = objeto
            elseif linhaParedeNorte ~= nil and colunaParedeNorte ~= nil then
                paredesNorte[chave(tonumber(linhaParedeNorte) :: number, tonumber(colunaParedeNorte) :: number)] = true
            elseif linhaParedeOeste ~= nil and colunaParedeOeste ~= nil then
                paredesOeste[chave(tonumber(linhaParedeOeste) :: number, tonumber(colunaParedeOeste) :: number)] = true
            end
        end
    end

    local cruzamentos: { Waypoint } = {}
    local bifurcacoes: { Waypoint } = {}
    local passagens: { Waypoint } = {}
    local alturaRaiz = humanoide.HipHeight + raiz.Size.Y / 2

    for identificador, piso in pisos do
        local linhaTexto, colunaTexto = string.match(identificador, "^(%d+)_(%d+)$")
        assert(linhaTexto ~= nil and colunaTexto ~= nil, "A coordenada do piso precisa ser válida")
        local linha = tonumber(linhaTexto)
        local coluna = tonumber(colunaTexto)
        assert(linha ~= nil and coluna ~= nil, "A coordenada do piso precisa ser numérica")

        local norte = pisos[chave(linha - 1, coluna)] ~= nil and not paredesNorte[chave(linha, coluna)]
        local leste = pisos[chave(linha, coluna + 1)] ~= nil and not paredesOeste[chave(linha, coluna + 1)]
        local sul = pisos[chave(linha + 1, coluna)] ~= nil and not paredesNorte[chave(linha + 1, coluna)]
        local oeste = pisos[chave(linha, coluna - 1)] ~= nil and not paredesOeste[chave(linha, coluna)]
        local saidasAbertas = (if norte then 1 else 0)
            + (if leste then 1 else 0)
            + (if sul then 1 else 0)
            + (if oeste then 1 else 0)
        local posicao = piso.Position + Vector3.new(0, piso.Size.Y / 2 + alturaRaiz, 0)
        local waypoint: Waypoint = { Posicao = posicao }

        if saidasAbertas >= 3 then
            table.insert(cruzamentos, waypoint)
        end
        if saidasAbertas >= 2 then
            table.insert(bifurcacoes, waypoint)
        end
        table.insert(passagens, waypoint)
    end

    if #cruzamentos >= 2 then
        return cruzamentos
    elseif #bifurcacoes >= 2 then
        return bifurcacoes
    end

    return passagens
end

local function aguardarMovimento(
    controle: Controle,
    humanoide: Humanoid,
    caminho: Path,
    indiceWaypoint: number,
    posicao: Vector3
): boolean
    local evento = Instance.new("BindableEvent")
    controle.EventoAtual = evento
    local conexoes: { RBXScriptConnection } = {}

    table.insert(
        conexoes,
        humanoide.MoveToFinished:Connect(function(alcancou)
            evento:Fire(if alcancou then "chegou" else "falhou")
        end)
    )
    table.insert(
        conexoes,
        caminho.Blocked:Connect(function(indiceBloqueado)
            if indiceBloqueado >= indiceWaypoint then
                evento:Fire("bloqueado")
            end
        end)
    )

    humanoide:MoveTo(posicao)
    local resultado = evento.Event:Wait()

    for _, conexao in conexoes do
        conexao:Disconnect()
    end
    if controle.EventoAtual == evento then
        controle.EventoAtual = nil
    end
    evento:Destroy()

    return resultado == "chegou" and controle.Ativo
end

local function seguirRota(
    guarda: Model,
    humanoide: Humanoid,
    raiz: BasePart,
    destino: Waypoint,
    controle: Controle
): boolean
    local caminho = PathfindingService:CreatePath()
    local calculado = pcall(function()
        caminho:ComputeAsync(raiz.Position, destino.Posicao)
    end)

    if not calculado or caminho.Status ~= Enum.PathStatus.Success then
        caminho:Destroy()
        return false
    end

    local rotaConcluida = true
    for indice, waypoint in caminho:GetWaypoints() do
        if not controle.Ativo or guarda.Parent == nil then
            rotaConcluida = false
            break
        end
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoide.Jump = true
        end
        if not aguardarMovimento(controle, humanoide, caminho, indice, waypoint.Position) then
            rotaConcluida = false
            break
        end
    end

    caminho:Destroy()
    return rotaConcluida
end

function Patrol.parar(guarda: Model): ()
    local controle = controles[guarda]
    if controle == nil then
        return
    end

    controle.Ativo = false
    if controle.EventoAtual ~= nil then
        controle.EventoAtual:Fire("cancelado")
    end

    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raiz = guarda:FindFirstChild("HumanoidRootPart")
    if humanoide ~= nil and raiz ~= nil and raiz:IsA("BasePart") then
        humanoide:MoveTo(raiz.Position)
    end

    controles[guarda] = nil
end

function Patrol.iniciar(guarda: Model, mapa: Folder): ()
    local humanoide = guarda:FindFirstChildOfClass("Humanoid")
    local raiz = guarda:FindFirstChild("HumanoidRootPart")
    assert(humanoide ~= nil, "O guarda precisa ter um Humanoid para patrulhar")
    assert(raiz ~= nil and raiz:IsA("BasePart"), "O guarda precisa ter uma raiz válida para patrulhar")

    Patrol.parar(guarda)
    local waypoints = coletarWaypoints(mapa, humanoide, raiz)
    if #waypoints < 2 then
        warn("A patrulha precisa de pelo menos dois waypoints válidos no mapa.")
        return
    end

    local controle: Controle = { Ativo = true, EventoAtual = nil }
    controles[guarda] = controle

    task.spawn(function()
        local aleatorio = Random.new()
        local ultimoIndice = 0

        while controle.Ativo and guarda.Parent ~= nil do
            local indice = aleatorio:NextInteger(1, #waypoints)
            if #waypoints > 1 and indice == ultimoIndice then
                indice = indice % #waypoints + 1
            end

            local destino = waypoints[indice]
            assert(destino ~= nil, "O waypoint escolhido precisa existir")

            while controle.Ativo and guarda.Parent ~= nil do
                if seguirRota(guarda, humanoide, raiz, destino, controle) then
                    ultimoIndice = indice
                    break
                end
                if controle.Ativo then
                    task.wait(Config.Timing.GuardRepathInterval)
                end
            end
        end

        if controles[guarda] == controle then
            controles[guarda] = nil
        end
    end)
end

return Patrol
