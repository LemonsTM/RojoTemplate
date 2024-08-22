--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local FXController = require(ReplicatedStorage.Client.FXController)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local Types = require(ServerStorage.PlayerManagement.SkillHandler.Types)
type PassedData = Types.PassedData

--// Skill Setup
local SkillTemplate = {}
local config = {
    SkillDuration = 1,
    SkillCooldown = 4
}

--// Functions
function SkillTemplate.onStart(data: PassedData)
    --// Checks to make sure the base skill can start
    if not CharacterClass.Actions.isActionSafe(data.caster, 'Skill') then return end

    --// Makes sure the skill is not on cooldown
    if CharacterClass.Attributes.getAttribute(data.caster, script.Name..'_Cooldown') then return end

    --// Starts the "Skill" action for the duration specified in config
    CharacterClass.Actions.startAction(data.caster, 'Skill', config.SkillDuration)

    --// Apply a cooldown for this specific skill
    CharacterClass.Attributes.applyAttribute(data.caster, script.Name..'_Cooldown', true, config.SkillCooldown)

    --// Replicate to all clients skill has started
    FXController.callEffect(script.Name, 'onStart', {caster = data.caster})
end

return SkillTemplate