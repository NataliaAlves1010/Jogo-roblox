--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)
local PlayerMovement = {}

type EstadoJogador = {
    Estamina: number,
    Correndo: boolean,
}

local estados: { [Player]: EstadoJogador } = {}

local function obterHumanoide(jogador: Player): Humanoid?
    local personagem = jogador.Character
    return if personagem ~= nil then personagem:FindFirstChildOfClass("Humanoid") else nil
end

local function aplicarVelocidade(jogador: Player, estado: EstadoJogador): ()
    local humanoide = obterHumanoide(jogador)
    if humanoide == nil or humanoide.Health <= 0 then
        return
    end

    if jogador:GetAttribute("DentroDoDuto") == true then
        if estado.Correndo then
            estado.Correndo = false
            humanoide.WalkSpeed = Config.Movement.VentWalkSpeed
        end
        return
    end

    humanoide.WalkSpeed = if estado.Correndo then Config.Movement.SprintWalkSpeed else Config.Movement.PlayerWalkSpeed
end

local function publicarEstamina(jogador: Player, estado: EstadoJogador): ()
    jogador:SetAttribute("Estamina", estado.Estamina)
end

local function inicializarJogador(jogador: Player): ()
    if estados[jogador] ~= nil then
        return
    end

    local movimento = Config.Movement
    local estado: EstadoJogador = {
        Estamina = movimento.SprintMaxStamina,
        Correndo = false,
    }
    estados[jogador] = estado
    publicarEstamina(jogador, estado)

    jogador.CharacterAdded:Connect(function(personagem)
        estado.Estamina = movimento.SprintMaxStamina
        estado.Correndo = false
        publicarEstamina(jogador, estado)
        local humanoide = personagem:WaitForChild("Humanoid", 10)
        if humanoide ~= nil and humanoide:IsA("Humanoid") then
            humanoide.WalkSpeed = movimento.PlayerWalkSpeed
        end
    end)

    task.spawn(function()
        while jogador.Parent == Players and estados[jogador] == estado do
            task.wait(movimento.StaminaUpdateInterval)
            if jogador.Parent ~= Players or estados[jogador] ~= estado then
                break
            end

            if estado.Correndo then
                if jogador:GetAttribute("DentroDoDuto") == true then
                    estado.Correndo = false
                else
                    estado.Estamina =
                        math.max(0, estado.Estamina - movimento.StaminaDrainPerSecond * movimento.StaminaUpdateInterval)
                    if estado.Estamina <= 0 then
                        estado.Correndo = false
                    end
                end
            else
                estado.Estamina = math.min(
                    movimento.SprintMaxStamina,
                    estado.Estamina + movimento.StaminaRecoveryPerSecond * movimento.StaminaUpdateInterval
                )
            end

            aplicarVelocidade(jogador, estado)
            publicarEstamina(jogador, estado)
        end
    end)
end

function PlayerMovement.validarSprint(jogador: Player, ativo: boolean): ()
    if jogador.Parent ~= Players or typeof(ativo) ~= "boolean" then
        return
    end

    inicializarJogador(jogador)
    local estado = estados[jogador]
    if estado == nil then
        return
    end

    local humanoide = obterHumanoide(jogador)
    if humanoide == nil or humanoide.Health <= 0 or not ativo then
        estado.Correndo = false
    else
        estado.Correndo = estado.Estamina > 0 and jogador:GetAttribute("DentroDoDuto") ~= true
    end

    aplicarVelocidade(jogador, estado)
end

Players.PlayerAdded:Connect(inicializarJogador)
Players.PlayerRemoving:Connect(function(jogador)
    estados[jogador] = nil
end)

for _, jogador in Players:GetPlayers() do
    inicializarJogador(jogador)
end

return PlayerMovement
