--// Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--// Imports
local PostureController = require(script.Parent.PostureController)
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)

--// Variables
local Combat = {}
local isInitialized = false
local CombatMechanics = { 'M1', 'M2', 'SprintM1', 'Block', 'DownSlam', 'Feint', 'Dash', 'Slide', 'Climb', 'Equip', 'Sprint', 'DoubleJump', 'Skill' }

function Combat.setupCharacter(character)
	if not isInitialized then
		Combat.initializeMechanics()
	end

	CharacterClass.Construct(character)
	PostureController.initializeCharacter(character)

	--// Give the character all main combat actions
	for _, actionName in CombatMechanics do
		CharacterClass.Actions.giveAction(character, actionName)
	end

	--// Parent character to alive folder
	character.Parent = workspace:FindFirstChild('Alive')
end

function Combat.initializeMechanics()
	isInitialized = true

	for _, actionName in CombatMechanics do
		local actionObject = script:FindFirstChild(actionName)
		if not actionObject then
			continue
		end

		local actionModule = require(script:FindFirstChild(actionName))

		--// Setup the combat actions
		if not actionModule or not actionModule['onRemote'] then
			continue
		end

		ServerRemotes[actionName].setCallback(function(player, ...)
			local character = player.Character

			return actionModule['onRemote'](character, player, ...)
		end)
	end
end

function Combat.manualCall(character, player, data, actionName, actionFunction)
	local actionObject = script:FindFirstChild(actionName)
	assert(actionObject, 'Action object not found')
	assert(character, 'Character not found')

	local actionModule = require(script:FindFirstChild(actionName))
	assert(actionModule[actionFunction], 'Function not found in .'.. actionName.. ' module')

	return actionModule[actionFunction](character, player, data)
end

return Combat
