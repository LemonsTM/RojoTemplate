--// Types
local Types = require(script.Parent.Parent.Types)
type CharacterType = Types.Character

--// Imports
local StatusEffects = require(script.Parent.Parent.StatusEffectsCache)

--// Variables
local CharacterCache = {}:: Types.CharacterCache

--// Character Constructor
function CharacterCache.createCharacter(characterModel: Types.R6)
	CharacterCache[characterModel] = {
		Instance = characterModel,
		Attributes = {},
		StatusEffects = {},
		Actions = {},
		Connections = {},
		Threads = {},
	}

	characterModel.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end

		for _, connection in CharacterCache[characterModel].Connections do
			connection:Disconnect()
		end

		for _, thread in CharacterCache[characterModel].Threads do
			task.cancel(thread)
		end

		CharacterCache[characterModel] = nil
	end)

    return CharacterCache[characterModel]
end

--// Getter Functions
function CharacterCache.getCharacterCache(characterModel: Model)
	local cache: CharacterType = CharacterCache[characterModel]
	assert(cache, characterModel.Name .. ' not found in CharacterCache')
	return cache
end

function CharacterCache.getActionCache(characterModel: Model, actionName: string)
	local cache = CharacterCache.getCharacterCache(characterModel)
	local action = cache.Actions[actionName]
	assert(action, ' [Action: ' .. actionName .. '] not found for ' .. characterModel.Name)
	return cache, action
end

function CharacterCache.getStatusCache(characterModel: Model, statusEffect: string)
    local cache = CharacterCache.getCharacterCache(characterModel)
	local statusEffectData = StatusEffects[statusEffect]:: Types.StatusEffect
	assert(statusEffectData, ' [statusEffect: ' .. statusEffect .. '] not found for ' .. characterModel.Name)
	return cache, statusEffectData
end
    
return CharacterCache