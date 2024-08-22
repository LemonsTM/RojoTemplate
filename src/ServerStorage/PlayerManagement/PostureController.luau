--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)

--// Constants
local postureLoseRate = 5 --// Lose 5 posture every 1 second
local maxPosture = 100 --// Maximum posture value

--// Variables
local PostureController = {}
local CharacterCache = {}

function PostureController.initializeCharacter(character: Model)
    CharacterCache[character] = {
        currentPosture = 0,
        postureLoseRateModifier = 0, --// Allows for the posture rate to be modified per player
        lastUpdated = tick()
    }

    character.AncestryChanged:Connect(function(_, parent)
        if parent then return end
        CharacterCache[character] = nil
    end)
end

--// Changes posture based on the operation specified
function PostureController.changePosture(character: Model, amount: number, operation: 'add'|'subtract'|'multiply'|'divide')
    local data = CharacterCache[character]
    if not data then return end

    PostureController.updatePosture(character)

    if operation == "add" then
        data.currentPosture += amount
    elseif operation == "subtract" then
        data.currentPosture -= amount
    elseif operation == "multiply" then
        data.currentPosture *= amount
    elseif operation == "divide" then
        if amount ~= 0 then
            data.currentPosture /= amount
        else
            warn("Cannot divide by zero")
        end
    else
        warn("Invalid operation")
    end

    if data.currentPosture >= maxPosture then
        data.currentPosture = maxPosture
        PostureController.onMaxPosture(character)
    end

    if data.currentPosture < 0 then
        data.currentPosture = 0
    end

    data.currentPosture = math.clamp(data.currentPosture, 0, 100)

    return data.currentPosture
end

--// Updates the posture based on time passed
function PostureController.updatePosture(character: Model)
    local data = CharacterCache[character]
    if not data then return end

    local currentTime = tick()
    local elapsedTime = currentTime - data.lastUpdated
    data.lastUpdated = currentTime

    local postureLoss = (postureLoseRate + data.postureLoseRateModifier) * elapsedTime
    local newPosture = math.max(0, data.currentPosture - postureLoss)
    data.currentPosture = math.clamp(newPosture, 0, 100)
end

--// Returns the current posture calculated by the time passed
function PostureController.getPosture(character: Model)
    local data = CharacterCache[character]
    if not data then return end

    PostureController.updatePosture(character)
    return data.currentPosture
end

--// Allows modifying the posture lose rate modifier
function PostureController.setPostureLoseRateModifier(character: Model, modifier: number)
    local data = CharacterCache[character]
    if not data then return end

    data.postureLoseRateModifier = modifier
end

--// Function to be called when posture reaches max
function PostureController.onMaxPosture(character: Model)
    print(character.Name .. " has reached max posture!")

    for _, object in script.Parent.Combat:GetChildren() do
		if not CharacterClass.Actions.isActionActive(character, object.Name) then continue end

		local module = require(object)
		if not module['cancel'] then continue end

		module['cancel'](character)
	end

    CharacterClass.StatusEffects.enableStatusEffect(character, 'Locked', 1.25)
end

return PostureController
