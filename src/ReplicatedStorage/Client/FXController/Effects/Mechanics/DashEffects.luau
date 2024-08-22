--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Imports
local MovementTrails = require(ReplicatedStorage.Client.Helpers.MovementTrails)
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)

--// Variables
local DashEffects = {}

--// Stages
function DashEffects.onDashStart(data: {})
    local caster = data['caster']
	local casterRootPart = caster:FindFirstChild("HumanoidRootPart") :: BasePart

	--// RayParams
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true
	rayParams.FilterDescendantsInstances = { caster, workspace:FindFirstChild("Ignore") }

	--// SFX
	local SFX = ReplicatedStorage.Assets.SFX
	local sound = SFX:FindFirstChild("Dash"):Clone() :: Sound
	sound.Parent = casterRootPart
	sound.PlaybackSpeed = 1.5
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)

	--// VFX
	MovementTrails.applyTrails(caster)

	local dashFX = ReplicatedStorage.Assets.VFX.Movement.GroundDash
	dashFX = ParticleAssistant.Setup(dashFX)

	local downRay = workspace:Raycast(casterRootPart.Position, Vector3.new(0, -10, 0), rayParams)
	if downRay and downRay.Instance then
		for _, object in dashFX:GetDescendants() do
			if object.Name == "ColorChangeSmoke" and object:IsA("ParticleEmitter") then
				local hitColor = downRay.Instance.BrickColor.Color
				object.Color = ColorSequence.new(hitColor)
			end
		end
	end

    --// Main Loop  
    local timeElapsed = 0

    local connection; connection = RunService.RenderStepped:Connect(function(deltaTime)
        timeElapsed += deltaTime

        ParticleAssistant.ToggleEmit(dashFX, true)
        
        local groundCheck = workspace:Raycast(casterRootPart.Position, Vector3.new(0, -7.5, 0), rayParams)
        if not groundCheck then
            ParticleAssistant.ToggleEmit(dashFX, false)
        end

        local lookVector = casterRootPart.CFrame.LookVector
        dashFX.CFrame = CFrame.new(
            casterRootPart.Position - Vector3.new(0, 2.5, 0),
            (casterRootPart.Position - Vector3.new(0, 2.5, 0)) - lookVector
        )

        if timeElapsed >= 0.35 then
            connection:Disconnect()
            connection:Disconnect()
            ParticleAssistant.ToggleEmit(dashFX, false)
            MovementTrails.removeTrails(caster)
            task.wait(1)
            dashFX:Destroy()
        end
    end)
end

return DashEffects
