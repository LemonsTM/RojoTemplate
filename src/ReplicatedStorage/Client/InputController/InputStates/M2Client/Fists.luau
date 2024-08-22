local Debris = game:GetService('Debris')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

local Fists = {}

function Fists.onCast(caster: CharacterClassTypes.R6, weaponUsed: string, timeCasted: number)
	local weaponFolder = ReplicatedStorage.Assets.Weapons[weaponUsed]
	local castAnimation = weaponFolder.Animations.M2

	local humanoid: Humanoid = caster:FindFirstChild('Humanoid') :: Humanoid
	local animator: Animator = humanoid:FindFirstChild('Animator') :: Animator

	if caster == Players.LocalPlayer.Character then
		task.spawn(function()
			humanoid.WalkSpeed = 7
			humanoid.JumpHeight = 0
			task.wait(castAnimation:GetAttribute('Length'))
			humanoid.JumpHeight = 7.2
			humanoid.WalkSpeed = 16
		end)
	end

	--// SFX
	local m2Sound = weaponFolder.SFX:FindFirstChild('M2Startup'):Clone()
	m2Sound.Looped = false
	m2Sound.Parent = caster:FindFirstChild('HumanoidRootPart')
	m2Sound:Play()

	m2Sound.Ended:Once(function()
		m2Sound:Destroy()
	end)

	--// Animation
	local m2Track = animator:LoadAnimation(castAnimation)
	m2Track.Priority = Enum.AnimationPriority.Action4
	m2Track:AdjustWeight(10)
	m2Track.Looped = false
	m2Track:Play(0.25)

	--// Reconcile with server cast time
	local skippedFrames = os.clock() - timeCasted
	skippedFrames = math.clamp(skippedFrames, 0, 0.1)

	m2Track.TimePosition += skippedFrames

	m2Track.Ended:Once(function()
		m2Track:Stop(0.25)
		m2Track:Destroy()
	end)

	--// VFX
	local heavyFX = ReplicatedStorage.Assets.VFX.Combat.M2Windup:Clone()
	heavyFX = ParticleAssistant.Setup(heavyFX)
	ParticleAssistant.EasyWeld(heavyFX, caster:FindFirstChild('HumanoidRootPart'))
	ParticleAssistant.Emit(heavyFX)

	Debris:AddItem(heavyFX, 3)
end

function Fists.onHit(caster: CharacterClassTypes.R6, victim: CharacterClassTypes.R6, weaponUsed: string)
	--// SFX
	local hitSound = ReplicatedStorage.Assets.Weapons[weaponUsed].SFX.Hit_1:Clone()
	hitSound.Looped = false
	hitSound.Parent = victim.HumanoidRootPart
	hitSound:Play()

	hitSound.Ended:Once(function()
		hitSound:Destroy()
	end)

	--// Animations
	local knockbackTypes = {
		[1] = ReplicatedStorage.Assets.Animations.Combat.Knockback,
		[2] = ReplicatedStorage.Assets.Animations.Combat.Knockback2,
	}

	local knockbackAnimation = knockbackTypes[math.random(1, #knockbackTypes)]
	local knockbackTrack = victim.Humanoid.Animator:LoadAnimation(knockbackAnimation)
	knockbackTrack.Looped = false
	knockbackTrack.Priority = Enum.AnimationPriority.Action3
	knockbackTrack:Play(0.25)

	knockbackTrack.Ended:Once(function()
		knockbackTrack:Stop(0.15)
		knockbackTrack:Destroy()
	end)

	--// VFX
	local hitVFX = ReplicatedStorage.Assets.Weapons[weaponUsed].VFX.M2Hit
	hitVFX = ParticleAssistant.Setup(hitVFX)
	hitVFX.CFrame = caster.HumanoidRootPart.CFrame

	ParticleAssistant.Emit(hitVFX)
	Debris:AddItem(hitVFX, 1.5)
end

function Fists.OnHitServer(caster: CharacterClassTypes.R6, victim: CharacterClassTypes.R6, weaponUsed: string)
	local direction = caster.HumanoidRootPart.CFrame.LookVector
	
	--// Start body velocity
	local bodyVelocity = Instance.new('BodyVelocity') :: BodyVelocity
	bodyVelocity.MaxForce = Vector3.new(5e4, 5e4, 5e4)
	bodyVelocity.Velocity = direction * 25
	bodyVelocity.P = 1625
	bodyVelocity.Parent = victim.HumanoidRootPart
	
	--// setup rayparams
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { workspace.Map }
	rayParams.RespectCanCollide = true
	
	CharacterClass.StatusEffects.enableStatusEffect(victim, 'Locked')
	
	victim.Humanoid.WalkSpeed = 0
	victim.Humanoid.JumpHeight = 0
	
	--// Raycast every heartbeat for wall detection (unoptimized but idc)
	local timeElapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		timeElapsed += deltaTime

		if timeElapsed >= 0.65 then
			connection:Disconnect()
			bodyVelocity:Destroy()

			CharacterClass.StatusEffects.disableStatusEffect(victim, 'Locked')
			return
		end

		local wallCheck = workspace:Raycast(victim.HumanoidRootPart.Position, direction * 1.5, rayParams)
		if not wallCheck then
			return
		end

		connection:Disconnect()
		bodyVelocity:Destroy()

		local wallHitAnimation = ReplicatedStorage.Assets.Animations.Combat.WallHit
		local wallHitTrack = victim.Humanoid.Animator:LoadAnimation(wallHitAnimation)
		wallHitTrack.Looped = false
		wallHitTrack.Priority = Enum.AnimationPriority.Action4
		wallHitTrack:Play()

		wallHitTrack.Ended:Once(function()
			wallHitTrack:Stop(0.25)
			wallHitTrack:Destroy()
		end)

		task.delay(1.5, function()
			CharacterClass.StatusEffects.disableStatusEffect(victim, 'Locked')
		end)
	end)
end

return Fists
