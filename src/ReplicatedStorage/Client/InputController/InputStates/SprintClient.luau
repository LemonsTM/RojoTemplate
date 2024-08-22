--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
-- Main
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local Sprint: InputType = {
	name = "Sprint",
	binds = {Enum.KeyCode.W},
	state = {Enum.UserInputState.Begin, Enum.UserInputState.End},
	callback = nil,
}

--// State Input Callback
Sprint.callback = function(inputObject: InputObject)
	local character: Model = player.Character

    ClientRemotes.Sprint.fire(inputObject.UserInputState.Name)
end

return Sprint
