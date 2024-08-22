--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

local Slide = {}

function Slide.onRemote(character: CharacterClassTypes.R6, player: Player, inputState: 'Begin'|'End')
    if CharacterClass.Actions.isActionActive(character, 'Slide') and inputState == 'End' then
        CharacterClass.Actions.endAction(character, 'Slide')
        CharacterClass.Actions.applyCooldown(character, 'Slide', 1.25)
        CharacterClass.Actions.applyCooldown(character, 'M1', 0.35)

        ServerRemotes.SlideReplication.fireAll({caster = character, status = 'End'})

        if CharacterClass.Attributes.getAttribute(character, 'WasSprinting') then
            local sprintMod = require(script.Parent.Sprint)
            sprintMod.onRemote(character, player, 'Begin')
            sprintMod.onRemote(character, player, 'End')
            sprintMod.onRemote(character, player, 'Begin')

            CharacterClass.Attributes.removeAttribute(character, 'WasSprinting')
        end

        return {attempt = 'Success', status = 'End'}
    elseif not CharacterClass.Actions.isActionActive(character, 'Slide') and inputState == 'Begin' then
        if not CharacterClass.Actions.isActionSafe(character, 'Slide') then return {attempt = 'Failure'} end 

        if CharacterClass.Actions.isActionActive(character, 'Sprint') then
            local sprintMod = require(script.Parent.Sprint)
            sprintMod.cancel(character)
            CharacterClass.Attributes.applyAttribute(character, 'WasSprinting', true)
        end

        CharacterClass.Actions.startAction(character, 'Slide', nil)

        ServerRemotes.SlideReplication.fireAll({caster = character, status = 'Start'})

        return {attempt = 'Success', status = 'Start'}
    end

    return {attempt = 'Failure'}
end

function Slide.cancel(character: CharacterClassTypes.R6)
    
end

return Slide