local ReplicatedStorage = game:GetService("ReplicatedStorage")
--// Types
local StatusEffectsCache = require(ReplicatedStorage.Shared.CharacterClass.StatusEffectsCache)
local Types = require(script.Parent.Parent.Types)
type CharacterType = Types.Character

--// Imports
local CharacterCache = require(script.Parent.CharacterCache)

--// Variables
local StatusEffects = {} :: Types.StatusEffects

--// Public Functions
function StatusEffects.enableStatusEffect(characterModel: Model, statusEffect: string, duration: number?)
	local cache: CharacterType, statusEffectData: Types.StatusEffect =
		CharacterCache.getStatusCache(characterModel, statusEffect)

	local previousThread: thread = cache.Threads[statusEffect .. "statusDuration"]
	if previousThread then
		task.cancel(previousThread)
		cache.Threads[statusEffect .. "statusDuration"] = nil
	end

	local priority = statusEffectData.Priority or 0

	cache.StatusEffects[statusEffect] = true
	if statusEffectData["OnStart"] then

		local canStart = true
		for activeStatus in cache.StatusEffects do
			if (StatusEffectsCache[activeStatus].Priority or 0) > priority then 
				canStart = false
			end
		end

		if canStart then
			statusEffectData["OnStart"](cache)
		end
	end

	local durationThread
	if duration then
		durationThread = task.spawn(function()
			task.wait(duration)

			local canEnd = true
			for activeStatus in cache.StatusEffects do
				if (StatusEffectsCache[activeStatus].Priority or 0) > priority then 
					canEnd = false
				end
			end

			if statusEffectData["OnEnd"] and canEnd then
				statusEffectData["OnEnd"](cache)
			end

			cache.StatusEffects[statusEffect] = nil --// We just clean it entirely since it'd be a waste of memory to keep it cached
			cache.Threads[statusEffect .. "statusDuration"] = nil
		end)
	end

	cache.Threads[statusEffect .. "statusDuration"] = durationThread
end

function StatusEffects.disableStatusEffect(characterModel: Model, statusEffect: string)
	local cache: CharacterType, statusEffectData: Types.StatusEffect =
		CharacterCache.getStatusCache(characterModel, statusEffect)

	local existingThread: thread = cache.Threads[statusEffect .. "statusDuration"]
	if existingThread then
		task.cancel(existingThread)
		cache.Threads[statusEffect .. "statusDuration"] = nil
	end

	if statusEffectData["OnEnd"] then
		statusEffectData["OnEnd"](cache)
	end

	cache.StatusEffects[statusEffect] = nil
	cache.Threads[statusEffect .. "statusDuration"] = nil
end

function StatusEffects.isStatusActive(characterModel: Model, statusEffect: string)
	local cache: CharacterType = CharacterCache.getCharacterCache(characterModel)

	return cache.StatusEffects[statusEffect] ~= nil
end

return StatusEffects
