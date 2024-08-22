--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local HitProcessor = require(ServerStorage.PlayerManagement.HitProcessor)
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)
local WeaponConfigurations = require(ReplicatedStorage.Shared.Configurations.WeaponConfigurations)
local HitboxClass = require(ReplicatedStorage.Shared.HitboxClass)
local HitboxTypes = require(ReplicatedStorage.Shared.HitboxClass.Types)

--// Variables
local M1 = {}

function M1.onRemote(character: CharacterClassTypes.R6, player: Player)
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if humanoid.FloorMaterial == Enum.Material.Air and player then
		return
	end

	if CharacterClass.Actions.isActionActive(character, "M1") then
		return
	end

	if not CharacterClass.Actions.isActionSafe(character, "M1") then
		return
	end

	if
		CharacterClass.Actions.isActionSafe(character, "SprintM1")
		and CharacterClass.Actions.isActionActive(character, "Sprint")
	then
		return
	elseif
		CharacterClass.Actions.isActionActive(character, "Sprint")
		and not CharacterClass.Actions.isActionSafe(character, "SprintM1")
	then
		local sprintMod = require(script.Parent.Sprint)
		sprintMod.cancel(character)
	end

	local currentTime = os.clock()
	local equippedWeapon = CharacterClass.Attributes.getAttribute(character, "EquippedWeapon") or "Fists"

	--// Get previous attack attributes
	local previousM1Time = CharacterClass.Attributes.getAttribute(character, "PreviousM1Time") or currentTime
	local previousComboCount = CharacterClass.Attributes.getAttribute(character, "ComboCount") or 0

	--// Determine new hit combo
	local newCombo
	if ((currentTime - previousM1Time >= 1.75) or (currentTime == previousM1Time)) or previousComboCount == 4 then
		newCombo = 1
	else
		newCombo = previousComboCount + 1
	end

	CharacterClass.Attributes.applyAttribute(character, "PreviousM1Time", currentTime)
	CharacterClass.Attributes.applyAttribute(character, "ComboCount", newCombo)

	--// Perform hitbox
	local weaponFolder = ReplicatedStorage.Assets.Weapons[equippedWeapon]
	local weaponConfiguration = WeaponConfigurations[equippedWeapon]
	local hitAnimation = weaponFolder.Animations.M1s[tostring(newCombo)]

	CharacterClass.Attributes.applyAttribute(character, "FeintFrames", true, hitAnimation:GetAttribute("Length") / 3)
	CharacterClass.Actions.startAction(character, "M1", hitAnimation:GetAttribute("Length") - 0.085)

	local hitboxData = {
		SizeOrPart = weaponConfiguration.M1Data.HitboxSize,
		Blacklist = { character },
		InitialPosition = character.HumanoidRootPart.CFrame,
		SpatialOption = "InBox",
	} :: HitboxTypes.HitboxParams

	local newHitbox = HitboxClass.new(hitboxData)
	newHitbox:SetVelocityPrediction(true)
	newHitbox:WeldTo(character.HumanoidRootPart, weaponConfiguration.M1Data.HitboxOffset)
	newHitbox.HitSomeone:Once(function(hitList: { Model })
		CharacterClass.StatusEffects.enableStatusEffect(
			character,
			"Slowed",
			(hitAnimation:getAttribute("Length") - hitAnimation:GetAttribute("Hit")) + 0.25
		)

		for _, characterHit in hitList do
			local didHit = HitProcessor.processHit(
				character,
				characterHit,
				{
					damage = weaponConfiguration.M1Data.BaseDamage,
					stun = true,
					stunDuration = weaponConfiguration.M1Data.StunDuration,
					customData = { "M1" },
				}
			)

			if didHit and newCombo == 4 then
				local direction = character.HumanoidRootPart.CFrame.LookVector

				--// Start body velocity
				local bodyVelocity = Instance.new("BodyVelocity") :: BodyVelocity
				bodyVelocity.MaxForce = Vector3.new(5e4, 5e4, 5e4)
				bodyVelocity.Velocity = direction * 25
				bodyVelocity.P = 1625
				bodyVelocity.Parent = characterHit.HumanoidRootPart

				--// setup rayparams
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Include
				rayParams.FilterDescendantsInstances = { workspace.Map }
				rayParams.RespectCanCollide = true

				CharacterClass.StatusEffects.enableStatusEffect(characterHit, "Locked")

				characterHit.Humanoid.WalkSpeed = 0
				characterHit.Humanoid.JumpHeight = 0

				--// Raycast every heartbeat for wall detection (unoptimized but idc)
				local timeElapsed = 0
				local connection
				connection = RunService.Heartbeat:Connect(function(deltaTime)
					timeElapsed += deltaTime

					if timeElapsed >= 0.65 then
						connection:Disconnect()
						bodyVelocity:Destroy()

						CharacterClass.StatusEffects.disableStatusEffect(characterHit, "Locked")
						return
					end

					local wallCheck =
						workspace:Raycast(characterHit.HumanoidRootPart.Position, direction * 1.5, rayParams)
					if not wallCheck then
						return
					end

					connection:Disconnect()
					bodyVelocity:Destroy()

					local wallHitAnimation = ReplicatedStorage.Assets.Animations.Combat.WallHit
					local wallHitTrack = characterHit.Humanoid.Animator:LoadAnimation(wallHitAnimation)
					wallHitTrack.Looped = false
					wallHitTrack.Priority = Enum.AnimationPriority.Action4
					wallHitTrack:Play()

					wallHitTrack.Ended:Once(function()
						wallHitTrack:Stop(0.25)
						wallHitTrack:Destroy()
					end)

					task.delay(1.5, function()
						CharacterClass.StatusEffects.disableStatusEffect(characterHit, "Locked")
					end)
				end)
			end
		end
	end)

	local hitDelay = task.delay(hitAnimation:GetAttribute("Hit"), function()
		if not newHitbox then
			return
		end

		local delay = player and 0.1 or 0

		newHitbox:Start()
		task.wait(delay)
		newHitbox:Stop()
		newHitbox:Destroy()

		CharacterClass.Attributes.removeAttribute(character, "M1Hitbox")
		CharacterClass.Attributes.removeAttribute(character, "M1HitTask")
	end)

	CharacterClass.Attributes.applyAttribute(character, "M1Hitbox", newHitbox)
	CharacterClass.Attributes.applyAttribute(character, "M1HitTask", hitDelay)

	local cooldown = newCombo < 4 and hitAnimation:GetAttribute("Length") - 0.085 or 2

	CharacterClass.Actions.applyCooldown(character, "M1", cooldown)
	ServerRemotes.M1Replication.fireAll({
		comboCount = newCombo,
		timeCasted = currentTime,
		caster = character,
		weaponUsed = equippedWeapon,
	})
end

function M1.cancel(character)
	local hitboxObject = CharacterClass.Attributes.getAttribute(character, "M1Hitbox")
	if hitboxObject then
		hitboxObject:Stop()
		hitboxObject:Destroy()
	end

	local hitTask = CharacterClass.Attributes.getAttribute(character, "M1HitTask")
	if hitTask then
		task.cancel(hitTask)
	end

	CharacterClass.Attributes.removeAttribute(character, "M1Hitbox")
	CharacterClass.Attributes.removeAttribute(character, "M1HitTask")
	CharacterClass.Actions.endAction(character, "M1")

	ServerRemotes.OnM1Cancelled.fireAll({
		isFeint = true,
		caster = character,
		comboCancelling = CharacterClass.Attributes.getAttribute(character, "ComboCount"),
	})
end

return M1
