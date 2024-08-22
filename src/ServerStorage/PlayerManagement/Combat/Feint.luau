--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

--// Variables
local Feint = {}

function Feint.onRemote(character: CharacterClassTypes.R6, _: Player)
	if CharacterClass.Actions.isActionActive(character, "Feint") then
		return
	end
	if not CharacterClass.Actions.isActionSafe(character, "Feint") then
		return
	end

	if
		not CharacterClass.Attributes.getAttribute(character, "FeintFrames")
		and not CharacterClass.Attributes.getAttribute(character, "DashCancelFrames")
	then
		return
	end

	--// Action Management
	CharacterClass.Actions.startAction(character, "Feint", 0.1)
	CharacterClass.Actions.applyCooldown(character, "Feint", 1)

    --// Logic
    if CharacterClass.Attributes.getAttribute(character, 'FeintFrames') then
        local m1Mod = require(script.Parent.M1)
        m1Mod.cancel(character)
    elseif CharacterClass.Attributes.getAttribute(character, 'DashCancelFrames') then
        local dashMod = require(script.Parent.Dash)
        dashMod.cancel(character)
    end
end

function Feint.cancel() end

return Feint
