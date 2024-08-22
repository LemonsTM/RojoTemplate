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
local Feint: InputType = {
	name = "Feint",
	binds = {Enum.UserInputType.MouseButton2},
	state = {Enum.UserInputState.Begin},
	callback = nil,
}

--// State Input Callback
Feint.callback = function(inputObject: InputObject)
	local character: Model = player.Character

    ClientRemotes.Feint.fire()
end

return Feint
