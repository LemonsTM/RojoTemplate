--// Services
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local ServerRemotes = require(ServerStorage.ServerRemotes)
local Functions = require(script.Functions)

--// Variables
local RagdollController = {}

--// Config
RagdollController.UpperLimit = 90
RagdollController.TwistLimits = true
RagdollController.TwistUpper = 90
RagdollController.TwistLower = -90
RagdollController.NeckUpper = 60
RagdollController.MaxFrictionTorque = 0
RagdollController.Restitution = 0.15
RagdollController.ColliderSize = 0.6
RagdollController.AutoGetup = true

function RagdollController.RigPlayer(character: Model)
	local hum = character:FindFirstChild('Humanoid')
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	Functions.CreateConstraints(character, RagdollController)
end

function RagdollController.Ragdoll(character: Model)
	local plr = game.Players:GetPlayerFromCharacter(character)
	if plr then
        ServerRemotes.ReplicateRagdoll.fire(plr, true)
	else
		for _, object in character:GetDescendants() do
			if not object:IsA('BasePart') then continue end
			if object.Anchored == true then continue end

			pcall(function()
				object:SetNetworkOwner(nil)
			end)
		end

		local hum = character:FindFirstChild('Humanoid')
		hum.AutoRotate = false
		hum.PlatformStand = true

		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end
	
	for _,v in character:GetChildren() do
		if v:IsA("BasePart") then
			if v.Name ~= "HumanoidRootPart" then
				Functions.CreateColliders(v, 0.6, RagdollController)
			end
		end
	end

	for _,v in character:GetDescendants() do
		if v:IsA("Motor6D") and v.Name ~= "RootJoint" then
			v.Enabled = false
		elseif v:IsA("BallSocketConstraint") then
			v.Enabled = true
		end
	end
end

function RagdollController.Unragdoll(character: Model)
	local plr = game.Players:GetPlayerFromCharacter(character)
	if plr then
		ServerRemotes.ReplicateRagdoll.fire(plr, false)
	else
		local hum = character:FindFirstChild('Humanoid')

		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		
		for _, object in character:GetDescendants() do
			if not object:IsA('BasePart') then continue end
			if object.Anchored == true then continue end

			pcall(function()
				object:SetNetworkOwner(nil)
			end)
		end

		hum.AutoRotate = true
		hum.PlatformStand = false
	end
	Functions.RecoverJoints(character, RagdollController)
end

function RagdollController.TempRagdoll(character: Model, delay: number)
	RagdollController.Ragdoll(character)
	task.wait(delay)
	RagdollController.Unragdoll(character)
end

function RagdollController.AddImpulse(character: Model, direction: Vector3, force: number, duration: number)
	local hrp = character:FindFirstChild('HumanoidRootPart')

	local knock = Instance.new("AlignPosition")
	knock.Name = "Knockback"
	knock.Mode = Enum.PositionAlignmentMode.OneAttachment

	local att = Instance.new("Attachment")
	knock.Attachment0=att
	knock.ApplyAtCenterOfMass=true
	knock.MaxForce=force*1000
	knock.MaxAxesForce = Vector3.one*1000*force
	knock.MaxVelocity=math.huge
	knock.Position = hrp.Position+direction
	knock.Parent = hrp

	game:GetService("Debris"):AddItem(knock, duration)
	game:GetService("Debris"):AddItem(att, duration)
end

return RagdollController
