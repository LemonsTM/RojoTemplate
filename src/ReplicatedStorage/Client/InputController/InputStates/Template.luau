--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
-- Main
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local Template: InputType = {
	name = "Template",
	binds = {},
	state = {},
	callback = nil,
}

--// State Input Callback
Template.callback = function(inputObject: InputObject)
	local character: Model = player.Character
end

return Template
