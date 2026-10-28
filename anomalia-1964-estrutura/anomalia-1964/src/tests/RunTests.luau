--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local RunService = game:GetService("RunService")

local RunTests = {}

function RunTests.executar(): ()
    assert(RunService:IsRunning(), "Inicie uma sessão de Play no Roblox Studio antes dos testes.")
    assert(RunService:IsServer(), "Execute os testes no contexto do servidor.")

    local packages = ReplicatedStorage:WaitForChild("DevPackages")
    local testezModule = packages:WaitForChild("TestEZ") :: ModuleScript
    local TestEZ = require(testezModule)
    local raizTestes = TestService:WaitForChild("Tests")
    local resultados = TestEZ.TestBootstrap:run({ raizTestes }, TestEZ.Reporters.TextReporter)

    if #resultados.errors > 0 or resultados.failureCount > 0 then
        error(`TestEZ encontrou {resultados.failureCount} falha(s) e {#resultados.errors} erro(s).`, 0)
    end

    print(`TestEZ: {resultados.successCount} teste(s) passaram.`)
end

return RunTests
