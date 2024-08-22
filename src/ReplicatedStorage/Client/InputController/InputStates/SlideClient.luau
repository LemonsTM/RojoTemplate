--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Imports
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local Types = require(script.Parent.Parent.Types)
type inpType = Types.inputType

--// Variables
local player = Players.LocalPlayer
local Slide: inpType = {
	name = "Slide",
	binds = { Enum.KeyCode.LeftControl },
	state = { Enum.UserInputState.Begin, Enum.UserInputState.End },
	callback = nil,
}

local slideAnimation = ReplicatedStorage.Assets.Animations.Movement.Slide
local slidingTrack = nil
local slideVfxReference = ReplicatedStorage.Assets.VFX.Movement.Slide
local slideVfx = ReplicatedStorage.Assets.VFX.Movement.Slide
local slidingConnection = nil
local bodyVelocity = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace:FindFirstChild("Map") }
rayParams.RespectCanCollide = true

--// State Input Callback
Slide.callback = function(inputObject: InputObject)
	local character = player.Character
	local humanoid = character.Humanoid :: Humanoid
	local animator = humanoid:FindFirstChild('Animator') :: Animator

	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	local promise = ClientRemotes.Slide.call(inputObject.UserInputState.Name)
	promise:andThen(function(result)
		if result.attempt == "Failure" then
			return
		end

		local initialSpeed = (40 + character.HumanoidRootPart.Velocity.Magnitude) / 2
		local newSpeed = initialSpeed
		local lastTimeCalled = os.clock()
		local previousRayPosition = nil
		local timeElapsed = 0
		local fixedTimeStep = 1 / 60

		if result.status == "Start" then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(0, 0, 2e5)
            bodyVelocity.P = 6000
            bodyVelocity.Parent = character.HumanoidRootPart

			slidingTrack = animator:LoadAnimation(slideAnimation) :: AnimationTrack
			slidingTrack.Looped = true
			slidingTrack.Priority = Enum.AnimationPriority.Action4
			slidingTrack:Play(0.25)

			slideVfx = ParticleAssistant.Setup(slideVfxReference)
			ParticleAssistant.ToggleEmit(slideVfx, true)

			slidingConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
				local currentFloorCheck: RaycastResult? = workspace:Raycast(
					character.HumanoidRootPart.Position,
					Vector3.new(0, -10, 0),
					rayParams
				)
				if not currentFloorCheck then
					ClientRemotes.Slide.call("End")
					slidingConnection:Disconnect()

					slidingTrack:Stop(0.25)
					slidingTrack:Destroy()

					ParticleAssistant.ToggleEmit(slideVfx, false)
					Debris:AddItem(slideVfx, 2.5)

                    bodyVelocity:Destroy()

					return
				end

				if not previousRayPosition then
					previousRayPosition = currentFloorCheck.Position
					timeElapsed += deltaTime
					return
				end
				
				if newSpeed <= 3 then
					ClientRemotes.Slide.call("End")
					slidingConnection:Disconnect()

					slidingTrack:Stop(0.25)
					slidingTrack:Destroy()

					ParticleAssistant.ToggleEmit(slideVfx, false)
					Debris:AddItem(slideVfx, 2.5)

					bodyVelocity:Destroy()

					return
				end

				local wallCheck = workspace:Raycast(
					character.HumanoidRootPart.Position,
					character.HumanoidRootPart.CFrame.LookVector * 3,
					rayParams
				)
				if wallCheck then
					bodyVelocity.Velocity = Vector3.new(0, 0, 0)
					newSpeed -= math.abs(1 * timeElapsed)
					return
				end


				if os.clock() - lastTimeCalled <= 0.01 then
					return
				end

				lastTimeCalled = os.clock()
				timeElapsed += deltaTime

				if timeElapsed < fixedTimeStep then return end

				if currentFloorCheck.Position.Y == previousRayPosition.Y and timeElapsed >= 1.25 then
					ClientRemotes.Slide.call("End")
					slidingConnection:Disconnect()

					slidingTrack:Stop(0.25)
					slidingTrack:Destroy()

					ParticleAssistant.ToggleEmit(slideVfx, false)
					Debris:AddItem(slideVfx, 2.5)

                    bodyVelocity:Destroy()

					return
				end

				if currentFloorCheck.Position.Y == previousRayPosition.Y then
					newSpeed -= math.abs(0.5 * timeElapsed)
				end

				if currentFloorCheck.Position.Y > previousRayPosition.Y and timeElapsed >= 0.15 then
					ClientRemotes.Slide.call("End")
					slidingConnection:Disconnect()

					slidingTrack:Stop(0.25)
					slidingTrack:Destroy()

					ParticleAssistant.ToggleEmit(slideVfx, false)
					Debris:AddItem(slideVfx, 2.5)

                    bodyVelocity:Destroy()

					return
				end

				if currentFloorCheck.Position.Y < previousRayPosition.Y then
					newSpeed += math.abs(2 * timeElapsed)
				end

				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					local jumpCancelAnimation = ReplicatedStorage.Assets.Animations.Movement.FrontDash
					local jumpCancel = animator:LoadAnimation(jumpCancelAnimation)
					jumpCancel.Looped = false
					jumpCancel.Priority = Enum.AnimationPriority.Action4
					jumpCancel:Play()

					character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                    local rootpart = character.HumanoidRootPart:: BasePart
                    local direction = rootpart.CFrame.LookVector * 500
                    rootpart:ApplyImpulse(direction)

					jumpCancel.Ended:Once(function()
						jumpCancel:Destroy()
					end)

					ClientRemotes.Slide.call("End")
					slidingConnection:Disconnect()

					slidingTrack:Stop(0.25)
					slidingTrack:Destroy()

					ParticleAssistant.ToggleEmit(slideVfx, false)
					Debris:AddItem(slideVfx, 2.5)

                    bodyVelocity:Destroy()

					return
				end

				slideVfx.CFrame = character.HumanoidRootPart.CFrame - Vector3.new(0, 3, 0)

				local downRay = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -3, 0), rayParams)
				if downRay and downRay.Instance then
					for _, object in slideVfx:GetDescendants() do
						if object.Name == "ColorChangeSmoke" and object:IsA("ParticleEmitter") then
							local hitColor = downRay.Instance.BrickColor.Color
							object.Color = ColorSequence.new(hitColor)
						end
					end
				end

				local lookVector = character.HumanoidRootPart.CFrame.LookVector
				local velocityDirection = lookVector * newSpeed
				
				bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
				bodyVelocity.Velocity = velocityDirection
				bodyVelocity.P = 6000

				previousRayPosition = currentFloorCheck.Position
			end)
		elseif result.status == "End" then
            ClientRemotes.Slide.call('End')
            slidingConnection:Disconnect()

            slidingTrack:Stop(0.25)
            slidingTrack:Destroy()
            
            ParticleAssistant.ToggleEmit(slideVfx, false)
            Debris:AddItem(slideVfx, 2.5)

            bodyVelocity:Destroy()
		end
	end)
end

ClientRemotes.SlideReplication.setCallback(function(data: { caster: Instance, status: "End" | "Start" })
    if data.status == 'Start' then
        return
    elseif data.status == 'End' then
        if player == Players.LocalPlayer then return end
    end
end)

return Slide
