--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local SprintM1 = {}

function SprintM1.onRemote(character: CharacterClassTypes.R6, player: Player)
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if humanoid.FloorMaterial == Enum.Material.Air and player then
		return
	end

	if CharacterClass.Actions.isActionActive(character, "SprintM1") then
		return
	end

	if not CharacterClass.Actions.isActionSafe(character, "SprintM1") then
		return
	end

	local equippedWeapon = CharacterClass.Attributes.getAttribute(character, "EquippedWeapon") or "Fists"
	
    ServerRemotes.SprintM1Replication.fireAll({caster = character, status = 'Start', weaponUsed = equippedWeapon})

	--// Perform hitbox
	local weaponFolder = ReplicatedStorage.Assets.Weapons[equippedWeapon]
	local weaponConfiguration = WeaponConfigurations[equippedWeapon]
	local hitAnimation = weaponFolder.Animations.SprintM1
	
	CharacterClass.Actions.startAction(character, "SprintM1", hitAnimation:GetAttribute("Length") + 0.085)

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

		for _, characterHit in hitList do
			local didHit = HitProcessor.processHit(
				character,
				characterHit,
				{ damage = weaponConfiguration.M1Data.BaseDamage, stun = true, stunDuration = weaponConfiguration.M1Data.StunDuration, customData = {} }
			)

            if didHit then
				ServerRemotes.M1Replication.fireAll({
					comboCount = 1,
					timeCasted = os.clock(),
					caster = character,
					weaponUsed = equippedWeapon,
					victim = characterHit,
				})
            end
		end
	end)

	local hitDelay = task.delay(hitAnimation:GetAttribute("Hit"), function()
		if not newHitbox then
			return
		end

		newHitbox:Start()
		task.wait(0.1)
		newHitbox:Stop()
		newHitbox:Destroy()

		CharacterClass.Attributes.removeAttribute(character, "SprintM1Hitbox")
		CharacterClass.Attributes.removeAttribute(character, "SprintM1HitTask")
	end)

	

	CharacterClass.Attributes.applyAttribute(character, "SprintM1Hitbox", newHitbox)
	CharacterClass.Attributes.applyAttribute(character, "SprintM1HitTask", hitDelay)


	CharacterClass.Actions.applyCooldown(character, "SprintM1", 4.5)
end

function SprintM1.cancel(character)
	-- local hitboxObject = CharacterClass.Attributes.getAttribute(character, "SprintM1Hitbox")
	-- if hitboxObject then
	-- 	hitboxObject:Stop()
	-- 	hitboxObject:Destroy()
	-- end

	-- local hitTask = CharacterClass.Attributes.getAttribute(character, "SprintM1HitTask")
	-- if hitTask then
	-- 	task.cancel(hitTask)
	-- end

	-- CharacterClass.Attributes.removeAttribute(character, "SprintM1Hitbox")
	-- CharacterClass.Attributes.removeAttribute(character, "SprintM1HitTask")
	-- CharacterClass.Actions.endAction(character, 'SprintM1')

	--ServerRemotes.OnSprintM1Cancelled.fireAll({isFeint = true, caster = character, comboCancelling = CharacterClass.Attributes.getAttribute(character, 'ComboCount')})
end

return SprintM1
