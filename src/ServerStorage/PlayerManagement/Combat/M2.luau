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
local M2 = {}

function M2.onRemote(character: CharacterClassTypes.R6, player: Player)
	if CharacterClass.Actions.isActionActive(character, "M2") then
		return
	end
	if not CharacterClass.Actions.isActionSafe(character, "M2") then
		return
	end

	if CharacterClass.Actions.isActionActive(character, 'Sprint') then
		local sprintMod = require(script.Parent.Sprint)
		sprintMod.cancel(character)
	end

	local previousHitTask: thread? = CharacterClass.Attributes.getAttribute(character, 'M2HitTask')
	if previousHitTask then
		task.cancel(previousHitTask)
	end

	--// Variables
	local equippedWeapon = CharacterClass.Attributes.getAttribute(character, "EquippedWeapon"):: string
	local weaponConfiguration = WeaponConfigurations[equippedWeapon]

	local weaponFolder = ReplicatedStorage.Assets.Weapons[equippedWeapon]
	local m2Animation = weaponFolder.Animations.M2

	--// Action Management
	CharacterClass.Actions.startAction(character, "M2", m2Animation:GetAttribute("Length"))
	CharacterClass.Actions.applyCooldown(character, "M2", m2Animation:GetAttribute("Length") + 3)
    CharacterClass.Attributes.applyAttribute(character, 'PreviousM2Time', os.clock())
	CharacterClass.StatusEffects.enableStatusEffect(character, 'HyperArmor', m2Animation:GetAttribute('Length'))

	ServerRemotes.M2Replication.fireAll({ caster = character, weaponUsed = equippedWeapon, timeCasted = os.clock() })

	--// Hitbox Management
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
			HitProcessor.processHit(
				character,
				characterHit,
				{
					damage = weaponConfiguration.M2Data.BaseDamage,
					stun = true,
					stunDuration = weaponConfiguration.M2Data.StunDuration,
					ignoredHitVariants = {['BlockFrames'] = true},
					customData = { "M2" },
				}
			)
		end
	end)

	local hitTask = task.delay(m2Animation:GetAttribute("Hit"), function()
        if not newHitbox then
			return
		end

		newHitbox:Start()
		task.wait()
		newHitbox:Stop()
		newHitbox:Destroy()

		CharacterClass.Attributes.removeAttribute(character, "M2Hitbox")
		CharacterClass.Attributes.removeAttribute(character, "M2HitTask")

	end)

    CharacterClass.Attributes.applyAttribute(character, "M2Hitbox", newHitbox)
    CharacterClass.Attributes.applyAttribute(character, 'M2HitTask', hitTask)
end

function M2.cancel(character: CharacterClassTypes.R6) end

return M2
