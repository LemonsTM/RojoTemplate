--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Main
local MovementTrails = require(ReplicatedStorage.Client.Helpers.MovementTrails)
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local Dash: InputType = {
	name = "Dash",
	binds = { Enum.KeyCode.Q },
	state = { Enum.UserInputState.Begin },
	callback = nil,
}
local currentDashTrack = nil
local bodyMover = nil
local connection

--// Imports
local ControlModule = require(player.PlayerScripts.PlayerModule.ControlModule) :: any

--// State Input Callback
Dash.callback = function(inputObject: InputObject)
	local character: Model = player.Character
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local directionMoving = ControlModule:GetMoveVector()

	local direction = "FrontDash" :: "FrontDash" | "BackDash" | "RightDash" | "LeftDash"
	local axis = "Vertical" :: "Vertical" | "Horizontal"

	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		if directionMoving.Z > 0 then
			direction = "BackDash"
		end

		if directionMoving.X > 0 then
			direction = "RightDash"
			axis = "Horizontal"
		elseif directionMoving.X < 0 then
			direction = "LeftDash"
			axis = "Horizontal"
		end
	end

	directionMoving = directionMoving.Unit

	local promise = ClientRemotes.Dash.call(axis)

	promise:andThen(function(result)
		if result == "Failure" then
			return
		end

		--// Animations
		local dashAnimation = ReplicatedStorage.Assets.Animations.Movement[direction]
		local animator = humanoid.Animator :: Animator
		local dashTrack = animator:LoadAnimation(dashAnimation)
		dashTrack.Priority = Enum.AnimationPriority.Action4
		dashTrack.Looped = false
		dashTrack:Play(0.15)

		currentDashTrack = dashTrack

		dashTrack.Ended:Once(function()
			dashTrack:Stop()
			dashTrack:Destroy()
			currentDashTrack = nil
		end)

		--// Body Velocity
		local bodyVelocity = Instance.new("BodyVelocity") :: BodyVelocity
		bodyVelocity.MaxForce = Vector3.new(5e4, 0, 5e4)
		bodyVelocity.P = 1645
		bodyVelocity.Parent = humanoidRootPart
		Debris:AddItem(bodyVelocity, 0.35)

		bodyMover = bodyVelocity

		local timeElapsed = 0

		connection = RunService.RenderStepped:Connect(function(deltaTime)
			local horizontalDirection = Vector3.new(directionMoving.X, 0, directionMoving.Z)
			local relativeDirection = game.Workspace.CurrentCamera.CFrame:VectorToWorldSpace(horizontalDirection)
			local newDirection = Vector3.new(relativeDirection.X, directionMoving.Y, relativeDirection.Z)

			if newDirection ~= newDirection then
				newDirection = Vector3.new(0, 0, -1)
			end

			timeElapsed += deltaTime

			if timeElapsed >= 0.35 then
				connection:Disconnect()
			end

			bodyVelocity.Velocity = newDirection * 45
		end)
	end)
end

ClientRemotes.OnDashCancelled.setCallback(function(data: {caster: Model})  
	if currentDashTrack and data.caster == player.Character then
		currentDashTrack:Stop()
		currentDashTrack:Destroy()

		connection:Disconnect()
		connection = nil

		local currentVelocity = bodyMover.Velocity
		local slowDownFactor = 0.1
		local newVelocity = currentVelocity * slowDownFactor
		
		local slowedBV = TweenService:Create(bodyMover, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = newVelocity})
		slowedBV:Play()
		
		slowedBV.Completed:Once(function()
			bodyMover.Velocity = newVelocity
			bodyMover:Destroy()
			bodyMover = nil
		end)

	end

	local highLight = Instance.new("Highlight")
	highLight.FillColor = Color3.fromRGB(199, 199, 199)
	highLight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highLight.FillTransparency = 0
	highLight.OutlineTransparency = 0
	highLight.Parent = data.caster

	TweenService:Create(
		highLight,
		TweenInfo.new(0.8, Enum.EasingStyle.Back),
		{ ["FillTransparency"] = 1, ["OutlineTransparency"] = 1 }
	):Play()

	Debris:AddItem(highLight, 1)

	local humanoid = data.caster:FindFirstChild("Humanoid") :: Humanoid
	local animator = humanoid:FindFirstChild("Animator") :: Animator

	local direction
	local moveDirection = humanoid.MoveDirection
	if math.round(moveDirection.X) == -1 then
		direction = "LDashCancel"
	elseif math.round(moveDirection.X) == 1 then
		direction = "RDashCancel"
	end

	if not direction then
		direction = "LDashCancel"
	end

	local dashCancelAnimation = ReplicatedStorage.Assets.Animations.Movement:FindFirstChild(direction)
	local dashTrack = animator:LoadAnimation(dashCancelAnimation)
	dashTrack.Looped = false
	dashTrack.Priority = Enum.AnimationPriority.Action4
	dashTrack:AdjustSpeed(5)
	dashTrack:Play(0.1)

	dashTrack.Ended:Once(function()
		dashTrack:Stop()
	end)
end)

return Dash
