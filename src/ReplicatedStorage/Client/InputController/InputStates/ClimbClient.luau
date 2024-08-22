--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Imports
-- Main
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)
local Types = require(script.Parent.Parent.Types)
type inpType = Types.inputType

-- Skills

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local Climb: inpType = {
	name = "Climb",
	binds = { Enum.KeyCode.Space },
	state = { Enum.UserInputState.Begin },
	callback = nil,
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace:FindFirstChild("Map") }
rayParams.RespectCanCollide = true

--// State Input Callback
Climb.callback = function(inputObject: InputObject)
	local character = player.Character:: CharacterClassTypes.R6
	local humanoid = character.Humanoid :: Humanoid
	local animator = humanoid:FindFirstChild("Animator") :: Animator

	if character.Humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end

	local forwardRaycast: RaycastResult? = workspace:Raycast(
		character.HumanoidRootPart.Position,
		character.HumanoidRootPart.CFrame.LookVector * 3.5,
		rayParams
	)
	if not forwardRaycast then
        local promise = ClientRemotes.DoubleJump.call()

        promise:andThen(function(result)
            if result == 'Failure' then return end

            local jumpTrack = character.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Movement.DoubleJump)
            jumpTrack.Looped = false
            jumpTrack.Priority = Enum.AnimationPriority.Action2
            jumpTrack:Play(0.1)

            jumpTrack.Ended:Once(function()
                jumpTrack:Stop(0.25)
                jumpTrack:Destroy()
            end)

            character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)

		return
	end

	ClientRemotes.Climb.fire()
end

ClientRemotes.ClimbReplication.setCallback(function()
	local character = player.Character :: CharacterClassTypes.R6
	local rootPart = character.HumanoidRootPart

	local animation = ReplicatedStorage.Assets.Animations.Movement.Climb
	local climbTrack = character.Humanoid.Animator:LoadAnimation(animation) :: AnimationTrack
	climbTrack.Looped = false
	climbTrack.Priority = Enum.AnimationPriority.Action4
	climbTrack:Play(0.1)

	climbTrack.Ended:Once(function()
		climbTrack:Stop(0.25)
		climbTrack:Destroy()
	end)

	local bodyVelocity = Instance.new("BodyVelocity") :: BodyVelocity
	bodyVelocity.Velocity = Vector3.new(0, 20, 0)
	bodyVelocity.MaxForce = Vector3.new(5e4, 5e4, 5e4)
	bodyVelocity.P = 6000
	bodyVelocity.Parent = rootPart

	local timeElapsed = 0

	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if timeElapsed > climbTrack.Length then
			connection:Disconnect()
			bodyVelocity:Destroy()

            ClientRemotes.NotifyClimb.fire()

			return
		end

		timeElapsed += deltaTime

		local legsCheck = workspace:Raycast(rootPart.Position - Vector3.new(0, rootPart.Size.Y / 2 + 1, 0), rootPart.CFrame.LookVector * 4.5, rayParams)
        local headCheck = workspace:Raycast(character.Head.Position, rootPart.CFrame.LookVector * 3.5, rayParams)

        if not legsCheck then
            connection:Disconnect()
			bodyVelocity:Destroy()
        end

		if legsCheck and not headCheck then
            connection:Disconnect()
            bodyVelocity:Destroy()

            ClientRemotes.NotifyClimb.fire()

            local vaultTrack = character.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Movement.Vault):: AnimationTrack
            vaultTrack.Looped = false
            vaultTrack.Priority = Enum.AnimationPriority.Action4
            vaultTrack:Play()

            vaultTrack.Ended:Once(function()
                vaultTrack:Stop(0.25)
                vaultTrack:Destroy()
            end)

            rootPart:ApplyImpulse(Vector3.new(0, 500, 0))
		end
	end)
end)

return Climb
