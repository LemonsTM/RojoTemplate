--// Services
local Debris = game:GetService("Debris")
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
local DownSlam = {}

function DownSlam.onRemote(character: CharacterClassTypes.R6, player: Player)
	if CharacterClass.Actions.isActionActive(character, "DownSlam") then
		return
	end
	if not CharacterClass.Actions.isActionSafe(character, "DownSlam") then
		return
	end

	if CharacterClass.Actions.isActionActive(character, 'Sprint') then
		local sprintMod = require(script.Parent.Sprint)
		sprintMod.cancel(character)
	end

	--// Variables
	local equippedWeapon = CharacterClass.Attributes.getAttribute(character, "EquippedWeapon"):: string

	local weaponFolder = ReplicatedStorage.Assets.Weapons[equippedWeapon]
	local DownSlamAnimation = weaponFolder.Animations.DownSlam

	--// Action Management
	CharacterClass.Actions.startAction(character, "DownSlam")
	CharacterClass.StatusEffects.enableStatusEffect(character, 'HyperArmor')
    CharacterClass.StatusEffects.enableStatusEffect(character, 'Stun')

    character.Humanoid.WalkSpeed = 0
    character.Humanoid.JumpHeight = 0

    --// Replicate startup
    ServerRemotes.DownSlamReplication.fireAll({caster = character, status = 'Cast', weaponUsed = equippedWeapon})

    --// Move character upwards to initiate downslam
    local upwardsVelocity = Instance.new('BodyVelocity'):: BodyVelocity
    upwardsVelocity.Velocity = Vector3.new(0, 35, 0)
    upwardsVelocity.MaxForce = Vector3.new(0, 5e4, 0)
    upwardsVelocity.P = 17.2
    upwardsVelocity.Parent = character.HumanoidRootPart

    Debris:AddItem(upwardsVelocity, DownSlamAnimation:GetAttribute('Length') / 4)
    task.wait(DownSlamAnimation:GetAttribute('Length') / 4 + 0.1)

    local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { workspace.Map }

    local downVelocity = Instance.new('BodyVelocity'):: BodyVelocity
    downVelocity.Velocity = Vector3.new(0, -150, 0)
    downVelocity.MaxForce = Vector3.new(0, 5e4, 0)
    downVelocity.P = 17.2
    downVelocity.Parent = character.HumanoidRootPart

    local connection; connection = RunService.Heartbeat:Connect(function()
        local groundRay: RaycastResult? = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -10, 0), rayParams)
        if not groundRay then return end

        connection:Disconnect()
        downVelocity:Destroy()

        --// Plays ground hit vfx
        ServerRemotes.DownSlamReplication.fireAll({caster = character, status = 'Hit', weaponUsed = equippedWeapon})

        --// Hitbox Management
        local hitboxData = {
            SizeOrPart = WeaponConfigurations[equippedWeapon].M2Data.HitboxSize * 1.75,
            Blacklist = {character},
            InitialPosition = character.HumanoidRootPart.CFrame,
            SpatialOption = "InBox",
        } :: HitboxTypes.HitboxParams
    
        local newHitbox = HitboxClass.new(hitboxData)
        newHitbox:SetVelocityPrediction(true)
        newHitbox:WeldTo(character.HumanoidRootPart, CFrame.new(0, 0, 0))
        newHitbox.HitSomeone:Once(function(hitList: { Model })
            character.Humanoid.WalkSpeed = 16
            character.Humanoid.JumpHeight = 7.2

            newHitbox:Stop()
            newHitbox:Destroy()
            newHitbox = nil

            for _, characterHit in hitList do
                local didHit = HitProcessor.processHit(
                    character,
                    characterHit,
                    {
                        damage = WeaponConfigurations[equippedWeapon].M2Data.BaseDamage,
                        stun = true,
                        stunDuration = WeaponConfigurations[equippedWeapon].M2Data.StunDuration,
                        ignoredHitVariants = {['BlockFrames'] = true}
                    }
                )

                if didHit then
                    CharacterClass.StatusEffects.enableStatusEffect(characterHit, 'Ragdoll', 1)
                    
                    local knockUp = Instance.new('BodyVelocity'):: BodyVelocity
                    knockUp.Velocity = Vector3.new(0, 15, 0)
                    knockUp.MaxForce = Vector3.new(0, 5e4, 0)
                    knockUp.P = 17.2
                    knockUp.Parent = characterHit.HumanoidRootPart

                    Debris:AddItem(knockUp, 0.35)
                end
            end
        end)

        newHitbox:Start()
        task.delay(0.1, function()
            if not newHitbox then return end
            newHitbox:Stop()
            newHitbox:Destroy()
            newHitbox = nil
        end)

        task.delay(0.5, function()
            character.Humanoid.WalkSpeed = 16
            character.Humanoid.JumpHeight = 7.2

            CharacterClass.StatusEffects.disableStatusEffect(character, 'Stun')
        end)

        --// End Action
        CharacterClass.Actions.endAction(character, 'DownSlam')
        CharacterClass.Actions.applyCooldown(character, 'DownSlam', 3.5)
        CharacterClass.StatusEffects.disableStatusEffect(character, 'HyperArmor')

        return true
    end)
end

function DownSlam.cancel(character: CharacterClassTypes.R6) end

return DownSlam
