--// Types
local Types = require(script.Parent.Parent.Types)
type CharacterType = Types.Character

--// Imports
local CharacterCache = require(script.Parent.CharacterCache)
local Attributes = {} :: Types.AttributesCache

function Attributes.applyAttribute(characterModel: Types.R6, attributeName: string, value: any, duration: number, doReplicate: boolean?)
	local cache = CharacterCache.getCharacterCache(characterModel)

	local previousTask = cache.Threads[attributeName.. 'Duration']
	if previousTask then
		task.cancel(previousTask)
	end

	if doReplicate == true then
		characterModel:SetAttribute(attributeName, value) --// Setting attributes is the same speed as sending a remote

		if duration then
			local durationTask = task.spawn(function()
				task.wait(duration)

				characterModel:SetAttribute(attributeName, nil)
			end)

			cache.Threads[attributeName.. 'Duration'] = durationTask
		end

		return
	end

	if not value then
		value = true
	end

	cache.Attributes[attributeName] = value

	if duration then
		local durationTask = task.spawn(function()
			task.wait(duration)

			cache.Attributes[attributeName] = nil
		end)

		cache.Threads[attributeName.. 'Duration'] = durationTask
	end
end

function Attributes.removeAttribute(characterModel: Types.R6, attributeName: string, doReplicate: boolean?)
	local cache = CharacterCache.getCharacterCache(characterModel)

	local previousTask = cache.Threads[attributeName.. 'Duration']
	if previousTask then
		task.cancel(previousTask)
	end

	if doReplicate then
		characterModel:SetAttribute(attributeName, nil)
		return
	end

	cache.Attributes[attributeName] = nil
end

function Attributes.getAttribute(characterModel: Types.R6, attributeName: string): any?
	local cache = CharacterCache.getCharacterCache(characterModel)

	if cache.Attributes[attributeName] then
		return cache.Attributes[attributeName]
	end

	if characterModel:GetAttribute(attributeName) then
		return characterModel:GetAttribute(attributeName)
	end

	return nil
end

return Attributes
