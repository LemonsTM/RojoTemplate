--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

--// Variables
local DoubleJump = {}

function DoubleJump.onRemote(character: CharacterClassTypes.R6, player: Player)
    if CharacterClass.Actions.isActionActive(character, 'DoubleJump') then return 'Failure' end
    if not CharacterClass.Actions.isActionSafe(character, 'DoubleJump') then return 'Failure' end

    local doubleJumpLength = ReplicatedStorage.Assets.Animations.Movement.DoubleJump:GetAttribute('Length')
    CharacterClass.Actions.startAction(character, 'DoubleJump', doubleJumpLength)
    task.delay(doubleJumpLength, function()
        CharacterClass.Actions.applyCooldown(character, 'DoubleJump', 1.75)
    end)

    return 'Success'
end

return DoubleJump