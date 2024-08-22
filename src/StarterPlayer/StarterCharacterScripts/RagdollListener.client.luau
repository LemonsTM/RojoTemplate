local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientRemotes = require(ReplicatedStorage.ClientRemotes)
local plr = game.Players.LocalPlayer
local char = plr.Character
local hum: Humanoid = char:WaitForChild("Humanoid", math.huge)

ClientRemotes.ReplicateRagdoll.setCallback(function(toggle: boolean)  
    if toggle then
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
		hum.AutoRotate = false
		hum.PlatformStand = true
    elseif toggle == false then
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		hum.AutoRotate = true
		hum.PlatformStand = false
    end
end)