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
local Equip: InputType = {
	name = "Equip",
	binds = { Enum.KeyCode.E },
	state = { Enum.UserInputState.Begin },
	callback = nil,
}

--// State Input Callback
Equip.callback = function(inputObject: InputObject)
	local character: Model = player.Character

	ClientRemotes.Equip.fire()
end

ClientRemotes.EquipReplicate.setCallback(function(data: { caster: Instance, status: "Disable" | "Enable" })  
	if data.status == "Disable" then
		local animateScript = data.caster:FindFirstChild("Animate")
		animateScript.idle.Animation1.AnimationId = ReplicatedStorage.Assets.Animations.Movement.Idle.AnimationId
		animateScript.idle.Animation2.AnimationId = ReplicatedStorage.Assets.Animations.Movement.Idle.AnimationId
	elseif data.status == 'Enable' then
		local animateScript = data.caster:FindFirstChild("Animate")
		animateScript.idle.Animation1.AnimationId = ""
		animateScript.idle.Animation2.AnimationId = ""

		for _, animationTrack in data.caster.Humanoid.Animator:GetPlayingAnimationTracks() do
			if animationTrack.Animation.AnimationId ~= 'rbxassetid://17551980413' then continue end
			animationTrack:Stop(0.25)
			animationTrack:Destroy()
		end
	end
end)

return Equip
