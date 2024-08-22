--[[
    Lithium is a framework that is designed with simplicity for a single-script architecture, using its built-in libraries for quality of life and performance purposes
]]

--// Services
local ServerStorage = game:GetService("ServerStorage")
    
--// Variables
local Lithium = {
    Client = {
        modulesToPreload = {
            [1] = game.ReplicatedStorage.Client.InputController,
            [2] = game.ReplicatedStorage.Client.FXController
        }:: {ModuleScript}?, --// Modules to preload on client startup
        modulesToClean = {}:: {ModuleScript}? --// Modules with a .onDeath function in them for when a character dies
    },
    Server = {
        modulesToPreload = {}:: {ModuleScript}? --// Modules to preload on server startup
    },
}

--// Client Code
function Lithium.Client.loadLithium()
    --// Preload specified modules
    for _, object in Lithium.Client.modulesToPreload do
        local module = require(object)
        if module['preLoad'] then
            module['preLoad']()
        end
    end

    Lithium.Client.modulesToPreload = nil --// Clean once initialized
end

function Lithium.Client.cleanSystems(characterDied: Model)
    for _, object in Lithium.Client.modulesToClean do
        local module = require(object)
        if module['onDeath'] then
            module['onDeath'](characterDied)
        end
    end
end

--// Server Code
function Lithium.Server.loadLithium()
    --// Preload specified modules
    for _, object in Lithium.Server.modulesToPreload do
        local module = require(object)
        if module['preLoad'] then
            module['preLoad']()
        end
    end

    Lithium.Server.modulesToPreload = nil --// Clean once initialized

    require(ServerStorage.ServerRemotes) --// Require zap server remotes to initialize them
end

return Lithium