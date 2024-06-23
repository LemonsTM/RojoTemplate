local ModuleLoader = {}

local clientModules = {
    -- Define modules to pre-load here in array structure
    [1] = game.ReplicatedStorage.Client.test
}

function ModuleLoader.Load()
    for _, module in ipairs(clientModules) do
        local Module

        pcall(function()
            Module = require(module)
        end)

        if not Module or not Module['InitMod'] then continue end

        Module['InitMod']()
    end
end

return ModuleLoader

