--//
export type hitConfig = {
	damage: number,
	stun: boolean,
	stunDuration: number?,
	ignoredHitVariants: { [string]: boolean }?,
	ignoredNoHitVariants: { [string]: boolean }?,
	customData: { any }?,
}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local Combat = require(script.Parent.Combat)
local ServerRemotes = require(ServerStorage.ServerRemotes)
local FXController = require(ReplicatedStorage.Client.FXController)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)
local PostureController = require(script.Parent.PostureController)
local WeaponConfigurations = require(ReplicatedStorage.Shared.Configurations.WeaponConfigurations)
local ClassConfigurations = require(ReplicatedStorage.Shared.Configurations.ClassConfigurations)

--// Variables
local HitProcessor = {}

local ProcessingStates = {
	HitVariants = {
		{
			type = "ParryFrames",
			func = function(attacker: CharacterClassTypes.R6, victim: CharacterClassTypes.R6)
				local heldWeapon = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
				local weaponCategory = WeaponConfigurations[heldWeapon].Category
				local postureDamage = ClassConfigurations[weaponCategory].ParryPostureDamage

				PostureController.changePosture(victim, 0, "multiply")
				PostureController.changePosture(attacker, postureDamage, "add")

				local module = require(script.Parent.Combat.Block)
				module["cancel"](victim)

				CharacterClass.StatusEffects.enableStatusEffect(attacker, "Stun", 0.85)
				CharacterClass.StatusEffects.disableStatusEffect(victim, "Stun")
				FXController.callEffect("Parry", "Parried", { caster = attacker, victim = victim })
			end,
		},
		{
			type = "BlockFrames",
			func = function(attacker: CharacterClassTypes.R6, victim: CharacterClassTypes.R6)
				local heldWeapon = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
				local weaponConfiguration = WeaponConfigurations[heldWeapon]

				local newPosture =
					PostureController.changePosture(victim, weaponConfiguration.M1Data.BasePostureDamage, "add")

				if newPosture < 100 then
					FXController.callEffect(
						"BlockHit",
						"onHit",
						{ caster = attacker, victim = victim, extraData = heldWeapon }
					)
				else
					local blockModule = require(script.Parent.Combat.Block)
					blockModule.cancel(victim)

					FXController.callEffect("BlockHit", "onBlockBreak", { caster = attacker, victim = victim })
				end
			end,
		},
	},
	NoHitVariants = { --// Gets called before HitVariants
		{ type = "IFrames", data = {
			DealDamage = false,
			Stun = false,
		} },
		{ type = "HyperArmor", data = {
			DealDamage = true,
			Stun = false,
		} },
	},
}

function HitProcessor.processHit(attacker: CharacterClassTypes.R6, victim: CharacterClassTypes.R6, hitConfig: hitConfig)
	if not Players:GetPlayerFromCharacter(victim) then
		if
			CharacterClass.Actions.isActionSafe(victim, "Block")
			and not CharacterClass.Actions.isActionActive(victim, "Block")
		then
			local aiType = victim.Name
			local agentsFolder = ServerStorage.Controllers.AIController:FindFirstChild("Agents")
			local agentFolder = agentsFolder:FindFirstChild(aiType)
			if agentsFolder and agentFolder then
				local aiModule = require(agentFolder)
				if aiModule then
					local parryChance = aiModule.Configuration.parryChance
					local doesParry = math.random() <= parryChance

					if doesParry and CharacterClass.Actions.isActionSafe(victim, "Block") then
						CharacterClass.StatusEffects.enableStatusEffect(victim, "ParryFrames", 0.1)
					end
				end
			end
		end
	end

	--// Process NoHitVariants
	for _, variant in ProcessingStates.NoHitVariants do
		local variantType = variant.type
		local variantData = variant.data

		if hitConfig.ignoredNoHitVariants and hitConfig.ignoredNoHitVariants[variantType] then
			continue
		end

		if
			not CharacterClass.Attributes.getAttribute(victim, variantType)
			and not CharacterClass.StatusEffects.isStatusActive(victim, variantType)
		then
			continue
		end

		if variantData.Stun then
			CharacterClass.StatusEffects.enableStatusEffect(victim, "Stun", hitConfig.stunDuration or 0.75)
		end

		if variantData.DealDamage then
			local damageCalculated = hitConfig.damage
			local humanoid = victim:FindFirstChild("Humanoid") :: Humanoid
			humanoid.Health -= damageCalculated

			if hitConfig.customData and hitConfig.customData[1] == "M2" then
				local equippedWeapon: string? = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
				local timeCasted: number? = CharacterClass.Attributes.getAttribute(attacker, "PreviousM2Time")

				ServerRemotes.M2Replication.fireAll({
					caster = attacker,
					timeCasted = timeCasted,
					victim = victim,
					weaponUsed = equippedWeapon,
				})

				local weaponM2Controller =
					require(ReplicatedStorage.Client.InputController.InputStates.M2Client[equippedWeapon])
				if weaponM2Controller and weaponM2Controller["OnHitServer"] then
					weaponM2Controller["OnHitServer"](attacker, victim, equippedWeapon)
				end
			end

			if hitConfig.customData and hitConfig.customData[1] == "M1" then
				local equippedWeapon: string? = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
				local currentCombo: number? = CharacterClass.Attributes.getAttribute(attacker, "ComboCount")

				ServerRemotes.M1Replication.fireAll({
					comboCount = currentCombo,
					timeCasted = 404,
					caster = attacker,
					weaponUsed = equippedWeapon,
					victim = victim,
				})
			end
		end

		return false
	end

	--// Process hit variants
	for _, variant in ProcessingStates.HitVariants do
		local variantType = variant.type
		local variantFunc = variant.func

		if hitConfig.ignoredHitVariants and hitConfig.ignoredHitVariants[variantType] then
			continue
		end

		if
			not CharacterClass.Attributes.getAttribute(victim, variantType)
			and not CharacterClass.StatusEffects.isStatusActive(victim, variantType)
		then
			continue
		end

		variantFunc(attacker, victim)

		return false
	end

	--// Hit Processing
	-- cancel anything active here
	for _, object in script.Parent.Combat:GetChildren() do
		if not CharacterClass.Actions.isActionActive(victim, object.Name) then
			continue
		end

		if hitConfig.ignoredHitVariants and hitConfig.ignoredHitVariants["BlockFrames"] and object.Name == "Block" then
			continue
		end

		for _, animationTrack in victim.Humanoid.Animator:GetPlayingAnimationTracks() do
			if animationTrack.Animation.Name ~= "Idle" then
				continue
			end
			animationTrack:Stop(0.1)
			task.wait(0.15)
			animationTrack:Play(0.25)
		end

		local module = require(object)
		if not module["cancel"] then
			continue
		end

		module["cancel"](victim)
	end

	if hitConfig.stun then
		CharacterClass.StatusEffects.enableStatusEffect(victim, "Stun", hitConfig.stunDuration or 0.75)
	end

	if hitConfig.damage then
		local humanoid = victim:FindFirstChild("Humanoid") :: Humanoid
		humanoid.Health -= hitConfig.damage
	end

	if hitConfig.customData and hitConfig.customData[1] == "M2" then
		local equippedWeapon: string? = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
		local timeCasted: number? = CharacterClass.Attributes.getAttribute(attacker, "PreviousM2Time")

		if CharacterClass.StatusEffects.isStatusActive(victim, "BlockFrames") then
			PostureController.changePosture(victim, 100, "add")
			FXController.callEffect("BlockHit", "onBlockBreak", { caster = attacker, victim = victim })

			local blockModule = require(script.Parent.Combat.Block)
			blockModule.cancel(victim)

			return
		end

		ServerRemotes.M2Replication.fireAll({
			caster = attacker,
			timeCasted = timeCasted,
			victim = victim,
			weaponUsed = equippedWeapon,
		})

		local weaponM2Controller =
			require(ReplicatedStorage.Client.InputController.InputStates.M2Client[equippedWeapon])
		if weaponM2Controller and weaponM2Controller["OnHitServer"] then
			weaponM2Controller["OnHitServer"](attacker, victim, equippedWeapon)
		end
	end

	if hitConfig.customData and hitConfig.customData[1] == "M1" then
		local equippedWeapon: string? = CharacterClass.Attributes.getAttribute(attacker, "EquippedWeapon")
		local currentCombo: number? = CharacterClass.Attributes.getAttribute(attacker, "ComboCount")
		local timeCasted: number? = CharacterClass.Attributes.getAttribute(attacker, "PreviousM1Time")

		ServerRemotes.M1Replication.fireAll({
			comboCount = currentCombo,
			timeCasted = timeCasted,
			caster = attacker,
			weaponUsed = equippedWeapon,
			victim = victim,
		})
	end

	return true
end

return HitProcessor
