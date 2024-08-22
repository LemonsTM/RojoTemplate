local Debris = game:GetService('Debris')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')

local BehaviorTree = require(ServerStorage.Controllers.AIController.BehaviorTree)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local RagdollController = require(ServerStorage.Controllers.RagdollController)
local Combat = require(ServerStorage.PlayerManagement.Combat)
local PostureController = require(ServerStorage.PlayerManagement.PostureController)
local SimplePath = require(ServerStorage.Services.SimplePath)

local Bandit = {}

Bandit.Configuration = {
	parryChance = 0.65, --// 35%
}

function Bandit.new(entity, specificTarget)
	local blackboard = {
		entity = entity,
		target = specificTarget,
		pathfinding = SimplePath.new(entity),
		tooClose = false,

		currentState = 'Aggressive',
		passiveOffset = Vector3.new(0, 0, 0),
		exhaustion = 0,
	}

	-- Temporary setup until main AI loader
	CharacterClass.Construct(entity)
	Combat.setupCharacter(entity)
	Combat.manualCall(entity, nil, nil, 'Equip', 'onRemote')
	RagdollController.RigPlayer(entity)

	local function isTargetAttacking(target, ignoredActions: { string }?)
		local attackingActions = { 'M1', 'M2', 'DownSlam', 'SprintM1', 'Skill' }

		for _, action in attackingActions do
			if ignoredActions and table.find(ignoredActions, action) then
				continue
			end

			if CharacterClass.Actions.isActionActive(target, action) then
				return true
			end
		end

		return false
	end

	local function isCloseEnough(entity, target, maxDistance)
		return (entity.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude <= maxDistance
	end

	local function shouldRunAction()
		local currentExhaustion = blackboard.exhaustion

		local shouldRun = math.random(0, 100) > currentExhaustion

		if shouldRun then
			return true
		end

		return false
	end

	local function executeTask(taskName)
		local tasks = {
			['Dash'] = function()
				if
					shouldRunAction()
					and not CharacterClass.Actions.isActionActive(entity, 'Dash')
					and CharacterClass.Actions.isActionSafe(entity, 'Dash')
				then
					if isTargetAttacking(blackboard.target) or not isCloseEnough(entity, blackboard.target, 20) then
						Bandit.Dash(blackboard)
						blackboard.exhaustion += math.clamp(5, 0, 100)
						return 'Success'
					end
				end
				return 'Failure'
			end,

			['Block'] = function()
				if
					
					isTargetAttacking(blackboard.target, { 'M2', 'DownSlam' })
					and not CharacterClass.Actions.isActionActive(entity, 'Block')
					and PostureController.getPosture(entity) < 75
				then
					Bandit.Block(blackboard)
					return 'Success'
				end

				return 'Failure'
			end,

			['Unblock'] = function()
				if
					(not isTargetAttacking(blackboard.target)
					and CharacterClass.Actions.isActionActive(entity, 'Block'))
					or PostureController.getPosture(entity) > 75
				then
					Bandit.Unblock(blackboard)
					return 'Success'
				end

				return 'Failure'
			end,

			['M1'] = function()
				if
					shouldRunAction()
					and not CharacterClass.Actions.isActionActive(entity, 'M1')
					and CharacterClass.Actions.isActionSafe(entity, 'M1')
				then
					if not isTargetAttacking(blackboard.target) and isCloseEnough(entity, blackboard.target, 20) then
						Bandit.M1(blackboard)
						blackboard.exhaustion += math.clamp(15, 0, 100)
						return 'Success'
					end
				end
				return 'Failure'
			end,

			['M2'] = function()
				if
					shouldRunAction()
					and not CharacterClass.Actions.isActionActive(entity, 'M2')
					and CharacterClass.Actions.isActionSafe(entity, 'M2')
				then
					if not isTargetAttacking(entity) and isCloseEnough(entity, blackboard.target, 20) then
						Bandit.M2(blackboard)
						blackboard.exhaustion += math.clamp(30, 0, 100)
						return 'Success'
					end
				end
				return 'Failure'
			end,

			['DownSlam'] = function()
				if
					shouldRunAction()
					and not CharacterClass.Actions.isActionActive(entity, 'DownSlam')
					and CharacterClass.Actions.isActionSafe(entity, 'DownSlam')
				then
					if not isTargetAttacking(entity) and isCloseEnough(entity, blackboard.target, 10) then
						Bandit.DownSlam(blackboard)
						blackboard.exhaustion += math.clamp(50, 0, 100)
						return 'Success'
					end
				end
				return 'Failure'
			end,
		}

		return tasks[taskName]()
	end

	local NormalAttackTree = {
		Type = 'Selector',
		Name = 'NormalAttackTree',
		Children = {
			{
				Type = 'Task',
				Name = 'M1',
				Func = function(entity, blackboard)
					return executeTask('M1')
				end,
			},
			{
				Type = 'Task',
				Name = 'Skill',
				Func = function(entity, blackboard)
					return 'Failure'
				end,
			},
			{
				Type = 'Task',
				Name = 'Unblock',
				Func = function(entity, blackboard)
					return executeTask('Unblock')
				end,
			}
		}
	}

	local DefensiveTree = {
		Type = 'Sequence',
		Name = 'Defensive',
		Children = {
			{
				Type = 'Task',
				Name = 'Is Target Attacking?',
				Func = function(entity, blackboard)
					return isTargetAttacking(blackboard.target) and 'Success' or 'Failure'
				end,
			},
			{
				Type = 'Selector',
				Name = 'Defensive Action',
				Children = {
					{
						Type = 'Task',
						Name = 'Dash',
						Func = function(entity, blackboard)
							return executeTask('Dash')
						end,
					},
					{
						Type = 'Task',
						Name = 'Unblock',
						Func = function(entity, blackboard)
							return executeTask('Unblock')
						end,
					},
					{
						Type = 'Task',
						Name = 'Block',
						Func = function(entity, blackboard)
							return executeTask('Block')
						end,
					}
				}
			}
		}
	}

	local CounteringTree = {
		Type = 'Sequence',
		Name = 'Blocking Punishment',
		Children = {
			{
				Type = 'Task',
				Name = 'Is Target Blocking?',
				Func = function(entity, blackboard)
					return CharacterClass.Actions.isActionActive(blackboard.target, 'Block') and 'Success' or 'Failure'
				end,
			},
			{
				Type = 'Selector',
				Name = 'Counter Action',
				Children = {
					{
						Type = 'Task',
						Name = 'M2',
						Func = function(entity, blackboard)
							return executeTask('M2')
						end,
					},
					{
						Type = 'Task',
						Name = 'DownSlam',
						Func = function(entity, blackboard)
							return executeTask('DownSlam')
						end,
					}
				}
			}
		}
	}

	local MovementTypeTree = {
		Type = 'Selector',
		Name = 'Movement Type',
		Children = {
			{
				Type = 'Task',
				Name = 'Aggressive',
				Func = function(entity, blackboard)
					local target = blackboard.target
					local distance = (target.HumanoidRootPart.Position - entity.HumanoidRootPart.Position).Magnitude
					local healthPercentage = (entity.Humanoid.Health / entity.Humanoid.MaxHealth) * 100
					local targetHealthPercentage = (target.Humanoid.Health / target.Humanoid.MaxHealth) * 100

					if
						(distance < 10 and healthPercentage > 20 and targetHealthPercentage < 50)
						or (distance < 15 and healthPercentage < 30)
					then
						blackboard.currentState = 'Aggressive'
						return 'Success'
					end

					return 'Failure'
				end,
			},
			{
				Type = 'Task',
				Name = 'Passive',
				Func = function(entity, blackboard)
					local target = blackboard.target
					local distance = (target.HumanoidRootPart.Position - entity.HumanoidRootPart.Position).Magnitude
					local healthPercentage = (entity.Humanoid.Health / entity.Humanoid.MaxHealth) * 100

					if distance > 20 and healthPercentage > 50 then
						blackboard.currentState = 'Passive'

						local offset = entity.HumanoidRootPart.Position - target.HumanoidRootPart.Position
						if offset.Magnitude > 35 then
							offset /= 4
						end

						blackboard.passiveOffset = offset

						return 'Success'
					end

					return 'Success'
				end,
			}
		}
	}

	local CombatTree = {
		Type = 'Selector',
		Name = 'Combat Tree',
		Children = {
			DefensiveTree,
			CounteringTree,
			NormalAttackTree,
		}
	}

	local CombatStateTree = {
		Type = 'Sequence',
		Name = 'Combat State',
		Children = {
			{
				Type = 'Task',
				Name = 'Has Target?',
				Func = function(entity, blackboard)
					return blackboard.target and 'Success' or 'Failure'
				end,
			},

			MovementTypeTree,
			CombatTree,
		}
	}

	local HumanoidTree = {
		Type = 'Root',
		Name = 'HumanoidRoot',
		Children = { CombatStateTree },
	}

	local behaviorTree = BehaviorTree.buildTree({ HumanoidTree })

	-- Main AI Loop
	local tickRate = 60
	local currentTick = 0
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not blackboard.target or blackboard.target.Humanoid.Health <= 10 then
			connection:Disconnect()
			return
		end

		if blackboard.entity.Humanoid.Health <= 5 then
			connection:Disconnect()
			blackboard.entity:Destroy()

			return
		end

		if currentTick < tickRate then
			currentTick += 1
			return
		elseif currentTick > tickRate then
			currentTick = 0
			return
		end

		behaviorTree:run(blackboard.entity, blackboard)
		blackboard.exhaustion -= math.clamp(0.1, 0, 100)
		blackboard.exhaustion = math.clamp(blackboard.exhaustion, 0, 100)

		if blackboard.target then
			local distance = (blackboard.entity.HumanoidRootPart.Position - blackboard.target.HumanoidRootPart.Position).Magnitude
			if distance < 5 and not blackboard.tooClose then
				blackboard.tooClose = true
				blackboard.pathfinding:Stop()
				return
			elseif distance > 5 and blackboard.tooClose then
				blackboard.tooClose = false
			elseif blackboard.tooClose then
				return
			end

			local goal = nil
			if blackboard.currentState == 'Aggressive' then
				goal = blackboard.target.HumanoidRootPart.Position
			elseif blackboard.currentState == 'Passive' then
				goal = blackboard.target.HumanoidRootPart.Position
				--goal = blackboard.passiveOffset + blackboard.target.HumanoidRootPart.Position
			end

			blackboard.pathfinding:Run(goal)
		end
	end)

	game:BindToClose(function(...: any): ...any
		connection:Disconnect()
	end)
end

function Bandit.M1(blackboard)
	Combat.manualCall(blackboard.entity, nil, nil, 'M1', 'onRemote')
end

function Bandit.Dash(blackboard)
	local function getMovementDirection(object)
		local humanoidRootPart = object:FindFirstChild('HumanoidRootPart')
		if not humanoidRootPart then
			warn('HumanoidRootPart not found on object.')
			return nil
		end

		local velocity = humanoidRootPart.Velocity
		local lookVector = humanoidRootPart.CFrame.LookVector
		local rightVector = humanoidRootPart.CFrame.RightVector

		lookVector = lookVector.Unit
		rightVector = rightVector.Unit

		local forwardDot = velocity:Dot(lookVector)
		local rightDot = velocity:Dot(rightVector)

		local direction
		if math.abs(forwardDot) > math.abs(rightDot) then
			if forwardDot > 0 then
				direction = 'FrontDash'
			else
				direction = 'BackDash'
			end
		else
			if rightDot > 0 then
				direction = 'RightDash'
			else
				direction = 'LeftDash'
			end
		end

		return direction
	end

	local relation = {
		FrontDash = Vector3.new(0, 0, 1),
		BackDash = Vector3.new(0, 0, -1),
		RightDash = Vector3.new(1, 0, 0),
		LeftDash = Vector3.new(-1, 0, 0)
	}

	local direction = getMovementDirection(blackboard.entity)
	local relativeDirection = relation[direction]

	local humanoidRootPart = blackboard.entity:FindFirstChild('HumanoidRootPart')
	if not humanoidRootPart then
		warn('HumanoidRootPart not found on entity.')
		return
	end

	local lookVector = humanoidRootPart.CFrame.LookVector
	local rightVector = humanoidRootPart.CFrame.RightVector

	local dashDirection = (relativeDirection.Z * lookVector + relativeDirection.X * rightVector).Unit
	local axis

	if direction ~= 'FrontDash' and direction ~= 'BackDash' then
		axis = 'Horizontal'
	else
		axis = 'Vertical'
	end

	local result = Combat.manualCall(blackboard.entity, nil, axis, 'Dash', 'onRemote')
	if not result or result == 'Failure' then
		return
	end

	local dashAnimation = ReplicatedStorage.Assets.Animations.Movement[direction]
	local animator = blackboard.entity.Humanoid.Animator :: Animator
	local dashTrack = animator:LoadAnimation(dashAnimation)
	dashTrack.Priority = Enum.AnimationPriority.Action4
	dashTrack.Looped = false
	dashTrack:Play(0.15)

	dashTrack.Ended:Once(function()
		dashTrack:Stop()
		dashTrack:Destroy()
	end)

	--// Body Velocity
	local bodyVelocity = Instance.new('BodyVelocity') :: BodyVelocity
	bodyVelocity.MaxForce = Vector3.new(5e4, 0, 5e4)
	bodyVelocity.P = 1645
	bodyVelocity.Velocity = dashDirection * 45
	bodyVelocity.Parent = blackboard.entity.HumanoidRootPart
	Debris:AddItem(bodyVelocity, 0.35)
end

function Bandit.M2(blackboard)
	Combat.manualCall(blackboard.entity, nil, nil, 'M2', 'onRemote')
end

function Bandit.Block(blackboard)
	Combat.manualCall(blackboard.entity, nil, 'Begin', 'Block', 'onRemote')
end

function Bandit.Unblock(blackboard)
	Combat.manualCall(blackboard.entity, nil, 'End', 'Block', 'onRemote')
end

function Bandit.DownSlam(blackboard)
	local humanoid = blackboard.entity.Humanoid :: Humanoid
	task.wait(0.1)
	local result = Combat.manualCall(blackboard.entity, nil, nil, 'DownSlam', 'onRemote')

	if result then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

return Bandit
