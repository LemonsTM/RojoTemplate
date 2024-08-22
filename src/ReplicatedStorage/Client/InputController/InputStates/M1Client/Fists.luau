local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local Fists = {}

function Fists.onSwing(character: Model, comboCount: number, timeCasted: number)
	local weaponFolder = ReplicatedStorage.Assets.Weapons[character:GetAttribute("EquippedWeapon")]
	local hitAnimation = weaponFolder.Animations.M1s[tostring(comboCount)]

	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator

	--// SFX
	local swingSound = weaponFolder.SFX:FindFirstChild("Swing" .. tostring(comboCount)):Clone()
	swingSound.Parent = character:FindFirstChild("HumanoidRootPart")
	swingSound:Play()

	swingSound.Ended:Once(function()
		swingSound:Destroy()
	end)

	--// Animations
	if character == game.Players.LocalPlayer.Character or not game.Players:GetPlayerFromCharacter(character) then
		local swingTrack = animator:LoadAnimation(hitAnimation)
		swingTrack.Looped = false
		swingTrack.Priority = Enum.AnimationPriority.Action4
		swingTrack:Play(0.15)

		--// Reconcile with server cast time
		local skippedFrames = os.clock() - timeCasted
		skippedFrames = math.clamp(skippedFrames, 0, 0.1)

		swingTrack.TimePosition += skippedFrames

		swingTrack.Ended:Once(function()
			swingTrack:Stop(0.15)
		end)
	end
end

function Fists.onHit(attacker: Model, victim: Model, comboCount: number, timeCasted)
	local weaponFolder = ReplicatedStorage.Assets.Weapons["Fists"]

	--// Play hit animation
	if timeCasted ~= 404 then
		local humanoid: Humanoid = victim:FindFirstChild("Humanoid") :: Humanoid
		local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator
		
		if comboCount == 4 then
			local knockbackTypes = {
				[1] = ReplicatedStorage.Assets.Animations.Combat.Knockback,
				[2] = ReplicatedStorage.Assets.Animations.Combat.Knockback2,
			}
		
			local knockbackAnimation = knockbackTypes[math.random(1, #knockbackTypes)]
			local knockbackTrack = animator:LoadAnimation(knockbackAnimation)
			knockbackTrack.Looped = false
			knockbackTrack.Priority = Enum.AnimationPriority.Action3
			knockbackTrack:Play(0.25)
		
			knockbackTrack.Ended:Once(function()
				knockbackTrack:Stop(0.15)
				knockbackTrack:Destroy()
			end)
		else
			local hitAnimations = {
				ReplicatedStorage.Assets.Animations.Combat.HitReact1,
				ReplicatedStorage.Assets.Animations.Combat.HitReact2,
			}
	
	
			local hitTrack = animator:LoadAnimation(hitAnimations[math.random(1, #hitAnimations)])
			hitTrack.Priority = Enum.AnimationPriority.Action4
			hitTrack.Looped = false
			hitTrack:Play(0.1)
	
			hitTrack.Ended:Once(function()
				hitTrack:Destroy()
			end)
		end
	end

	--// Play hit vfx
	local hitVFX = weaponFolder.VFX.Hit
	hitVFX = ParticleAssistant.Setup(hitVFX)
	ParticleAssistant.EasyWeld(hitVFX, victim:FindFirstChild("HumanoidRootPart"))
	ParticleAssistant.Emit(hitVFX)

	Debris:AddItem(hitVFX, 2.5)

	--// Play hit sound
	local hitSounds = {
		weaponFolder.SFX.Hit_1,
		weaponFolder.SFX.Hit_2,
		weaponFolder.SFX.Hit_3,
		weaponFolder.SFX.Hit_4,
	}

	local hitSound = hitSounds[math.random(1, #hitSounds)]:Clone()
	hitSound.Parent = victim:FindFirstChild("HumanoidRootPart")
	hitSound:Play()

	hitSound.Ended:Once(function()
		hitSound:Destroy()
	end)
end

function Fists.onCancel(caster, currentCombo, isFeint)
	local humanoid: Humanoid = caster:FindFirstChild("Humanoid") :: Humanoid
	local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator

	for _, animationTrack in animator:GetPlayingAnimationTracks() do
		if animationTrack.Animation.Name == tostring(currentCombo) then
			animationTrack:Stop(0.1)
			animationTrack:Destroy()
		end
	end

	if isFeint then
		local highLight = Instance.new("Highlight")
		highLight.FillColor = Color3.fromRGB(199, 199, 199)
		highLight.OutlineColor = Color3.fromRGB(199, 199, 199)
		highLight.FillTransparency = 0
		highLight.Parent = caster

		TweenService:Create(
			highLight,
			TweenInfo.new(0.8, Enum.EasingStyle.Back),
			{ ["FillTransparency"] = 1, ["OutlineTransparency"] = 1 }
		):Play()

		Debris:AddItem(highLight, 1)
	end
end

return Fists
