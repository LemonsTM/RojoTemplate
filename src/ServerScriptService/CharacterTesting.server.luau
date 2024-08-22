-- -- Replace Humanoid physics with a ControllerManager when a character loads into the workspace

-- local Players = game:GetService("Players")

-- function initialize(character)

-- 	local humanoid = character:WaitForChild('Humanoid'):: Humanoid
-- 	local cm = humanoid:WaitForChild('ControllerManager')
-- 	local gc = cm:WaitForChild('GroundController')

-- 	cm.RootPart = humanoid.RootPart
-- 	gc.GroundOffset = 2
-- 	cm.FacingDirection = cm.RootPart.CFrame.LookVector

-- 	local floorSensor = Instance.new("ControllerPartSensor")
-- 	floorSensor.SensorMode = Enum.SensorMode.Floor
-- 	floorSensor.SearchDistance = gc.GroundOffset + 0.5
-- 	floorSensor.Name = "GroundSensor"

-- 	local ladderSensor = Instance.new("ControllerPartSensor")
-- 	ladderSensor.SensorMode = Enum.SensorMode.Ladder
-- 	ladderSensor.SearchDistance = 1.5
-- 	ladderSensor.Name = "ClimbSensor"

-- 	local waterSensor = Instance.new("BuoyancySensor")

-- 	cm.GroundSensor = floorSensor
-- 	cm.ClimbSensor = ladderSensor

-- 	waterSensor.Parent = cm.RootPart
-- 	floorSensor.Parent = cm.RootPart
-- 	ladderSensor.Parent = cm.RootPart
-- 	cm.Parent = character


--     humanoid:GetPropertyChangedSignal('WalkSpeed'):Connect(function()
--         local newWalkspeed = humanoid.WalkSpeed
--         cm.BaseMoveSpeed = newWalkspeed
--     end)

--     humanoid:GetPropertyChangedSignal('JumpHeight'):Connect(function()
--         local newJumpHeight = humanoid.JumpHeight
--         cm:SetAttribute("JumpImpulse", Vector3.new(0, newJumpHeight, 0))
--     end)
-- end

-- Players.PlayerAdded:Connect(function(player)
-- 	player.CharacterAdded:Connect(function(character)
-- 		character.Humanoid.EvaluateStateMachine = false -- Disable Humanoid state machine and physics
-- 		task.wait() -- ensure post-load Humanoid computations are complete (such as hip height)
-- 		initialize(character)
-- 	end)	
-- end)