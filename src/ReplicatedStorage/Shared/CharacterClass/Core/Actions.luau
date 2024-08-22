--// Types
local Types = require(script.Parent.Parent.Types)
type CharacterType = Types.Character

--// Imports
local CharacterCache = require(script.Parent.CharacterCache)
local ActionsList = require(script.Parent.Parent.ActionsList)

--// Variables
local ActionsManagement = {} :: Types.ActionsManagement

--// Public Methods
function ActionsManagement.giveAction(characterModel: Model, actionName: string)
	local cache = CharacterCache.getCharacterCache(characterModel)

	local newAction = {
		IsDisabled = false,
		IsActive = false,
		CooldownInfo = {
			ReleaseTime = nil,
			DurationRequested = nil,
		},
	} :: Types.Action

	cache.Actions[actionName] = newAction
end

function ActionsManagement.removeAction(characterModel: Model, actionName: string)
	local cache: CharacterType, _ = CharacterCache.getActionCache(characterModel, actionName)
	cache.Actions[actionName] = nil
end

function ActionsManagement.startAction(characterModel: Model, actionName: string, duration: number?)
	local cache: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)
	action.IsActive = true

	if duration then
		local durationThread: thread = task.spawn(function()
			task.wait(duration)
			action.IsActive = false
			cache.Threads[actionName .. "Duration"] = nil
		end)

		cache.Threads[actionName .. "Duration"] = durationThread
	end
end

function ActionsManagement.endAction(characterModel: Model, actionName: string)
	local cache: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)

	local previousThread: thread = cache.Threads[actionName .. "Duration"]
	if previousThread then
		task.cancel(previousThread)
		cache.Threads[actionName .. "Duration"] = nil
	end

	action.IsActive = false
end

function ActionsManagement.isActionActive(characterModel: Model, actionName: string): boolean?
	local _: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)

	return action.IsActive
end

function ActionsManagement.disableAction(characterModel: Model, actionName: string, duration: number?)
	local cache: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)
	action.IsDisabled = true

	local durationThread: thread
	if duration then
		durationThread = task.spawn(function()
			task.wait(duration)
			action.IsDisabled = false
			cache.Threads[actionName .. "ForceDuration"] = nil
		end)
	end

	cache.Threads[actionName .. "ForceDuration"] = durationThread
end

function ActionsManagement.enableAction(characterModel: Model, actionName: string)
	local cache: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)

	local previousThread: thread = cache.Threads[actionName .. "ForceDuration"]
	if previousThread then
		task.cancel(previousThread)
		cache.Threads[actionName .. "ForceDuration"] = nil
	end

	action.IsDisabled = false
end

function ActionsManagement.applyCooldown(characterModel: Model, actionName: string, duration: number)
	local _: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)

	action.CooldownInfo.DurationRequested = duration
	action.CooldownInfo.ReleaseTime = os.clock() + duration
end

function ActionsManagement.removeCooldown(characterModel: Model, actionName: string)
	local _: CharacterType, action = CharacterCache.getActionCache(characterModel, actionName)

	action.CooldownInfo.DurationRequested = nil
	action.CooldownInfo.ReleaseTime = nil
end

function ActionsManagement.isActionSafe(characterModel: Model, actionName: string): boolean
	local cache: CharacterType = CharacterCache.getCharacterCache(characterModel, actionName)
	local actionData = ActionsList[actionName]

	if
		cache.Actions[actionName].CooldownInfo.ReleaseTime
		and cache.Actions[actionName].CooldownInfo.ReleaseTime > os.clock()
	then
		return false
	end

	for _, actionSet in actionData.BlacklistedActions do
		if cache.Actions[actionSet].IsActive then
			return false
		end
	end

	for _, statusSet in actionData.BlacklistedStatusEffects do
		if cache.StatusEffects[statusSet] then
			return false
		end
	end

	for _, requiredAction in actionData.RequiredActions do
		if not cache.Actions[requiredAction] or not cache.Actions[requiredAction].IsActive then
			return false
		end
	end

	for requiredAttribute, requiredValue in actionData.RequiredAttributes do
		if cache.Attributes[requiredAttribute] == nil and characterModel:GetAttribute(requiredAttribute) == nil then
			return false
		end

		if
			requiredValue and requiredValue ~= 'NaN'
			and (
				cache.Attributes[requiredAttribute].Value ~= requiredValue
				or characterModel:GetAttribute(requiredAttribute) ~= requiredValue
			)
		then
			print('reutrning false')
			return false
		end
	end

	for _, requiredStatus in actionData.RequiredStatusEffects do
		if not cache.StatusEffects[requiredStatus] then
			return false
		end
	end

	return true
end

return ActionsManagement
