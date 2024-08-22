--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

local Climb = {}

function Climb.onRemote(character: CharacterClassTypes.R6, player: Player)
    if CharacterClass.Actions.isActionActive(character, 'Climb') then return end
    if not CharacterClass.Actions.isActionSafe(character, 'Climb') then return end

    if CharacterClass.Actions.isActionActive(character, 'Sprint') then 
        local sprintMod = require(script.Parent.Sprint)
		sprintMod.cancel(character)
    end

    CharacterClass.Actions.startAction(character, 'Climb')
    ServerRemotes.ClimbReplication.fire(player)
end

function Climb.cancel(character: CharacterClassTypes.R6)
    
end

ServerRemotes.NotifyClimb.setCallback(function(a0: Player)  
    local character = a0.Character

    if not CharacterClass.Actions.isActionActive(character, 'Climb') then return end

    CharacterClass.Actions.endAction(character, 'Climb')
    CharacterClass.Actions.applyCooldown(character, 'Climb', 1.5)
end)

return Climb