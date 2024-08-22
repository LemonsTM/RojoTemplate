--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Imports
-- Main
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local M1: InputType = {
	name = "M1",
	binds = { Enum.UserInputType.MouseButton1 },
	state = { Enum.UserInputState.Begin },
	callback = nil,
}

--// State Input Callback
M1.callback = function(inputObject: InputObject)
	local character: Model = player.Character

	while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		ClientRemotes.SprintM1.fire()
		ClientRemotes.M1.fire()
		
		task.wait(0.1)
	end
end

ClientRemotes.M1Replication.setCallback(function(data: {caster: Instance, victim: Instance?, weaponUsed: string, comboCount: number, timeCasted: number })
	local weaponModule = require(script:FindFirstChild(data.weaponUsed))
	if not weaponModule then return end

	if data.victim then
		weaponModule.onHit(data.caster, data.victim, data.comboCount, data.timeCasted)
		return
	end
	
	weaponModule.onSwing(data.caster, data.comboCount, data.timeCasted)
end)

ClientRemotes.OnM1Cancelled.setCallback(function(data: {isFeint: boolean, caster: Instance, comboCancelling: number })  
	local weapon = data.caster:GetAttribute('EquippedWeapon')
	if not weapon then return end

	local weaponModule = require(script:FindFirstChild(weapon))
	if not weaponModule then return end

	weaponModule.onCancel(data.caster, data.comboCancelling, data.isFeint)
end)

return M1