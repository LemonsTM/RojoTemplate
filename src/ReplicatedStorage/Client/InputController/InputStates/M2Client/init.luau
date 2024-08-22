--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Imports
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)

-- Main
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local M2: InputType = {
	name = "M2",
	binds = {Enum.KeyCode.R},
	state = {Enum.UserInputState.Begin},
	callback = nil,
}

--// State Input Callback
M2.callback = function(inputObject: InputObject)
	local character: Model = player.Character
    local humanoid = character:FindFirstChild('Humanoid'):: Humanoid

    if humanoid.FloorMaterial == Enum.Material.Air then return end

    ClientRemotes.M2.fire()
end

ClientRemotes.M2Replication.setCallback(function(data:{ caster: Instance, timeCasted: number, victim: Instance?, weaponUsed: string })
	local weaponModule = require(script:FindFirstChild(data.weaponUsed))
	if not weaponModule then return end

	if data.victim then
		weaponModule.onHit(data.caster, data.victim, data.weaponUsed)
		return
	end
	
	weaponModule.onCast(data.caster, data.weaponUsed, data.timeCasted)
end)

return M2
