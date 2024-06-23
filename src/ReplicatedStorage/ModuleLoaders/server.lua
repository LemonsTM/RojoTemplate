local ModuleLoader = {}

local serverModules = {
    -- Define modules to pre-load here in array format
    [1] = game.ReplicatedStorage.Client.test
}

function ModuleLoader.Load()
    for _, module in ipairs(serverModules) do
        local Module

        pcall(function()
            Module = require(module)
        end)

        if not Module or not Module['InitMod'] then continue end

        Module['InitMod']()
    end
end

return ModuleLoader

