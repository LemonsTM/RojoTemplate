--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Imports
local PlayerClass = require(ServerScriptService.PlayerClass)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local Types = require(script.Types)
type PassedData = Types.PassedData
type SkillData = Types.SkillData

--// Module Definition
local SkillHandler = {}

--// Variables

--// Private Functions
local function characterHasSkill(character: Model, skillToCheck: string): boolean
    local player = Players:GetPlayerFromCharacter(character)

    local function checkSkill(skillList): boolean
        for _, skillName in skillList do
            if skillName == skillToCheck then
                return true
            end
        end

        return false
    end

    if player then
        local playerObject = PlayerClass.new(player)
        local activeSkills = playerObject:getSlotData('ActiveSkills')

        checkSkill(activeSkills)
    else
        local activeSkills = CharacterClass.Attributes.getAttribute(character, 'ActiveSkills')

        checkSkill(activeSkills)
    end

    return false
end

--// Public Functions
function SkillHandler.callSkill(data: SkillData): boolean
    if not characterHasSkill(data.caster, data.skillName) then return false end

    local skillModule = script.Skills:FindFirstChild(data.skillName, true)
    if not skillModule then return false end

    local skillMod = require(skillModule)
    if not skillMod[data.stage] then
        data.stage = 'onStart'
    end

    local passedData = data --// only pass necessary data
    passedData.skillName = nil
    passedData.stage = nil

    skillMod[data.stage](data)

    return true
end

return SkillHandler