--// Types
local Types = require(script.Types)
type CharacterType = Types.Character

--// Imports
local CharacterCache = require(script.Core.CharacterCache)
local StatusEffects = require(script.Core.StatusEffects)
local Actions = require(script.Core.Actions)
local Attributes = require(script.Core.Attributes)

return {
	Construct = function(characterModel): CharacterType
		return CharacterCache.createCharacter(characterModel)
	end,

	Actions = Actions:: Types.ActionsManagement,
	StatusEffects = StatusEffects:: Types.StatusEffects,
	Attributes = Attributes:: Types.AttributesCache
}:: Types.CharacterClass
