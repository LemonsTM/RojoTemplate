local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Bandit = require(ServerStorage.Controllers.AIController.Agents.Bandit)
local RagdollController = require(ServerStorage.Controllers.RagdollController)
local Combat = require(ServerStorage.PlayerManagement.Combat)
local Lithium = require(ReplicatedStorage.Lithium)

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character)
		--// Setup their character class
		Combat.setupCharacter(character)
		RagdollController.RigPlayer(character)

		for _, object in character:GetDescendants() do
			pcall(function()
				object:SetNetworkOwner(player)
			end)
		end

		--// Create handle for weapons
		local handle = Instance.new("Motor6D") :: Motor6D
		handle.C0 = CFrame.new(Vector3.new(-0.019, -0.995, -0.016), Vector3.new(0, 90, 0))
		handle.Name = "Handle"
		handle.Part0 = character:WaitForChild("Right Arm")
		handle.Part1 = nil --// Should be set to the weapon handle

		handle.Parent = character:WaitForChild("Right Arm")
	end)

	player.Chatted:Connect(function(message: string)  
		local character = player.Character

		if message:find('!spawnAi') then
			local newBanditAI = workspace:WaitForChild('Bandit'):Clone()
			newBanditAI.Parent = workspace.Alive
			newBanditAI.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(0, 5, -12)

			Bandit.new(newBanditAI, character)
		end
	end)
end)
--
Lithium.Server.loadLithium()
require(script.Parent.PlayerClass)