local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local PlayerClass = require(ServerScriptService.PlayerClass)
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local Equip = {}

function Equip.onRemote(character: Model, player: Player)
	if not character then
		return
	end

	if not CharacterClass.Actions.isActionSafe(character, "Equip") then
		return
	end

	local weaponUsing = nil
	if player then
		local playerObject = PlayerClass.new(player)
		weaponUsing = playerObject:getSlotData('WeaponSlot')
	else
		weaponUsing = character:GetAttribute('WeaponSlot') or 'Fists'
	end

	if not weaponUsing then return end

	if not CharacterClass.Attributes.getAttribute(character, "EquippedWeapon") then
		local weaponFolder = ReplicatedStorage.Assets.Weapons[weaponUsing]
		local weaponModel = weaponFolder:FindFirstChild("Model") :: Model?

		if weaponModel then
			weaponModel:Clone()
			weaponModel.Parent = character

			local rightArm = character:FindFirstChild("Right Arm") :: BasePart
			local handle = rightArm:FindFirstChild("Handle") :: Motor6D
			handle.Part1 = weaponModel:FindFirstChild("Handle", true)
			handle.C0 = CFrame.new(Vector3.new(-0.019, -0.995, -0.016)) * CFrame.Angles(0, math.rad(90), 0)
			handle.CurrentAngle = math.rad(0)
		end

		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		local animator = humanoid:FindFirstChild("Animator") :: Animator

		local equippedIdle: AnimationTrack = animator:LoadAnimation(weaponFolder.Animations.Idle)
		equippedIdle.Looped = true
		equippedIdle.Priority = Enum.AnimationPriority.Action

		if not CharacterClass.Actions.isActionActive(character, "Sprint") then
			equippedIdle:Play(0.25)
		end

		CharacterClass.Attributes.applyAttribute(character, "EquipIdle", equippedIdle)

		local equipAnimation = weaponFolder.Animations:FindFirstChild("Equip")

		if equipAnimation then
			local equipTrack: AnimationTrack = animator:LoadAnimation(equipAnimation)
			equipTrack.Looped = false
			equipTrack.Priority = Enum.AnimationPriority.Action2
			equipTrack:Play()

			CharacterClass.Actions.disableAction(character, "M1", equipTrack.Length)

			equipTrack.Ended:Once(function()
				equipTrack:Stop()
				equipTrack:Destroy()
			end)
		end

		CharacterClass.Attributes.applyAttribute(character, "EquippedWeapon", weaponUsing, nil, true)

		local animateScript = character:FindFirstChild("Animate")
		animateScript.idle.Animation1.AnimationId = ''
		animateScript.idle.Animation2.AnimationId = ''

		ServerRemotes.EquipReplicate.fireAll({status = 'Enable', caster = character})
	else
		CharacterClass.Attributes.removeAttribute(character, "EquippedWeapon", true)

		local weaponModel = character:FindFirstChild("Model")
		if weaponModel then
			weaponModel:Destroy()
		end

		local equipIdle = CharacterClass.Attributes.getAttribute(character, "EquipIdle")
		if equipIdle then
			equipIdle:Stop(0.15)
			equipIdle:Destroy()

			CharacterClass.Attributes.removeAttribute(character, "EquipIdle")
		end

		local animateScript = character:FindFirstChild("Animate")
		animateScript.idle.Animation1.AnimationId = ReplicatedStorage.Assets.Animations.Movement.Idle.AnimationId
		animateScript.idle.Animation2.AnimationId = ReplicatedStorage.Assets.Animations.Movement.Idle.AnimationId

		
		ServerRemotes.EquipReplicate.fireAll({status = 'Disable', caster = character})
	end

	CharacterClass.Actions.applyCooldown(character, "Equip", 1)
end

return Equip
