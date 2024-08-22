--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
-- Main
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local SprintM1: InputType = {
	name = "SprintM1",
	binds = { },
	state = { },
	callback = nil,
}

--// State Input Callback
SprintM1.callback = function(inputObject: InputObject)
	local character: Model = player.Character

end

ClientRemotes.SprintM1Replication.setCallback(
	function(data: { caster: Instance, status: "Hit" | "Start", victim: Instance?, weaponUsed: string })
	local casterRootPart = data.caster:FindFirstChild("HumanoidRootPart") :: BasePart
	local casterHumanoid = data.caster:FindFirstChildOfClass("Humanoid") :: Humanoid

	local weaponFolder = ReplicatedStorage.Assets.Weapons[data.weaponUsed]

	--// Play Animation
	local sprintM1Track = casterHumanoid.Animator:LoadAnimation(weaponFolder.Animations.SprintM1) :: AnimationTrack
	sprintM1Track.Looped = false
	sprintM1Track.Priority = Enum.AnimationPriority.Action4
	sprintM1Track:Play(0.25)
        
    sprintM1Track.Ended:Once(function()
		sprintM1Track:Stop(0.25)
		sprintM1Track:Destroy()
	end)

    --// Handle VFX
    local sprintM1VFX = ReplicatedStorage.Assets.VFX.Combat.SprintM1Indicator
    sprintM1VFX = ParticleAssistant.Setup(sprintM1VFX)
    ParticleAssistant.EasyWeld(sprintM1VFX, casterRootPart)

    ParticleAssistant.Emit(sprintM1VFX)

	Debris:AddItem(sprintM1VFX, 3)
end)

return SprintM1
