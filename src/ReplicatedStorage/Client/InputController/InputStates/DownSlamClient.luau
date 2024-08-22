--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Imports
-- Main
local MovementTrails = require(ReplicatedStorage.Client.Helpers.MovementTrails)
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local DownSlam: InputType = {
	name = "DownSlam",
	binds = { Enum.UserInputType.MouseButton2 },
	state = { Enum.UserInputState.Begin },
	callback = nil,
}

--// State Input Callback
DownSlam.callback = function(inputObject: InputObject)
	local character: Model = player.Character
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end

	ClientRemotes.DownSlam.fire()
end

ClientRemotes.DownSlamReplication.setCallback(
	function(data: { caster: Instance, status: "Cast" | "Hit", weaponUsed: string })
		local humanoid = data.caster:FindFirstChild("Humanoid") :: Humanoid
		local animator = humanoid:FindFirstChild("Animator") :: Animator
		local casterRootPart = data.caster:FindFirstChild("HumanoidRootPart")

		local weaponFolder = ReplicatedStorage.Assets.Weapons[data.weaponUsed]
		local hitAnimation = weaponFolder.Animations.DownSlam

		if data.status == "Cast" then
			--// Manage Animations
			local slamTrack = animator:LoadAnimation(hitAnimation)
			slamTrack.Priority = Enum.AnimationPriority.Action4
			slamTrack:Play(0.15)
			slamTrack.Looped = false

			slamTrack.Ended:Once(function()
				slamTrack:Stop(0.15)
			end)

			--// Manage VFX
			MovementTrails.applyTrails(data.caster)

			local highLight = Instance.new("Highlight")
			highLight.FillColor = Color3.fromRGB(255, 65, 68)
			highLight.OutlineColor = Color3.fromRGB(255, 234, 234)
			highLight.FillTransparency = 0.2
			highLight.DepthMode = Enum.HighlightDepthMode.Occluded
			highLight.Parent = data.caster

			TweenService:Create(
				highLight,
				TweenInfo.new(1, Enum.EasingStyle.Quad),
				{ ["FillTransparency"] = 1, ["OutlineTransparency"] = 1 }
			):Play()

			local m2Windup = ReplicatedStorage.Assets.VFX.Combat.DownSlamWindup:Clone()
			m2Windup.Parent = workspace:FindFirstChild("Ignore")

			ParticleAssistant.EasyWeld(m2Windup, casterRootPart)
			ParticleAssistant.Emit(m2Windup)

			Debris:AddItem(m2Windup, 1.5)
			Debris:AddItem(highLight, 1.5)

			--// Manage SFX
			local sound = weaponFolder.SFX:FindFirstChild("M2Startup"):Clone() :: Sound
			sound.Parent = casterRootPart
			sound:Play()

			sound.Ended:Once(function()
				sound:Destroy()
			end)
        elseif data.status == 'Hit' then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Include
            rayParams.FilterDescendantsInstances = { workspace.Map }
            
            local downRay = workspace:Raycast(casterRootPart.Position, Vector3.new(0, -5, 0), rayParams)
			if not downRay then
				downRay = workspace:Raycast(casterRootPart.Position, Vector3.new(0, -500, 0), rayParams)
			end

            if downRay and downRay.Instance then
                local downSlamVFX = ReplicatedStorage.Assets.VFX.Combat.DownSlamVFX
                downSlamVFX = ParticleAssistant.Setup(downSlamVFX)
                downSlamVFX.Position = downRay.Position

                for _, object in downSlamVFX:GetDescendants() do
					if object.Name == "ColorChangeSmoke" and object:IsA("ParticleEmitter") then
						local hitColor = downRay.Instance.BrickColor.Color
						object.Color = ColorSequence.new(hitColor)
					end
				end

                Debris:AddItem(downSlamVFX, 2.25)
                ParticleAssistant.Emit(downSlamVFX)
            end

            local downSlamSFX = ReplicatedStorage.Assets.SFX.GroundSlam_Hit:Clone()
			downSlamSFX.Parent = casterRootPart
			downSlamSFX:Play()

            downSlamSFX.Ended:Once(function()
                downSlamSFX:Destroy()
            end)

            MovementTrails.removeTrails(data.caster)
		end
	end
)

return DownSlam
