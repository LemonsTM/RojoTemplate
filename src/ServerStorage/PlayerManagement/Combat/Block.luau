--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local ServerRemotes = require(ServerStorage.ServerRemotes)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

--// Variables
local Block = {}

function Block.onRemote(character: CharacterClassTypes.R6, player: Player, state)
    if CharacterClass.Actions.isActionActive(character, 'Block') and state == 'End' then
        CharacterClass.StatusEffects.disableStatusEffect(character, 'BlockFrames')

        CharacterClass.Actions.endAction(character, 'Block')
        CharacterClass.Actions.applyCooldown(character, 'Block', 0.5)
        CharacterClass.Actions.applyCooldown(character, 'M1', 0.15)

        if player then
            ServerRemotes.BlockReplication.fire(player, 'Stop')
        else
            local blockTrack = CharacterClass.Attributes.getAttribute(character, 'BlockTrack')

            blockTrack:Stop(0.25)
            blockTrack:Destroy()
        end
    elseif not CharacterClass.Actions.isActionActive(character, 'Block') and state == 'Begin' then
        if not CharacterClass.Actions.isActionSafe(character, 'Block') then return end 

        if CharacterClass.Actions.isActionActive(character, 'Sprint') then
            local sprintMod = require(script.Parent.Sprint)
            sprintMod.cancel(character)
        end

        CharacterClass.Actions.startAction(character, 'Block', nil)

        local ExtraFrames = 0
        if player then
            local Ping = math.ceil(player:GetNetworkPing() * 2000)
            Ping = math.ceil(Ping)

            local Clamped = math.clamp((Ping - 50) / 200, 0, 1) / 10

            if Clamped > 0.1 then
                ExtraFrames = 0.1
            else
                ExtraFrames = Clamped
            end
        end

        --// we process block after parry in hit processor so we set instantly
        CharacterClass.StatusEffects.enableStatusEffect(character, 'ParryFrames', 0.135 + ExtraFrames)
        CharacterClass.StatusEffects.enableStatusEffect(character, 'BlockFrames', nil)

        if player then
            ServerRemotes.BlockReplication.fire(player, 'Start')
        else
            local equippedWeapon = character:GetAttribute('EquippedWeapon')
    
            local humanoid = character.Humanoid:: Humanoid
            local animator = humanoid:FindFirstChild('Animator'):: Animator
    
            local blockAnimation = ReplicatedStorage.Assets.Weapons[equippedWeapon].Animations.BlockIdle
    
            local blockTrack = animator:LoadAnimation(blockAnimation)
            blockTrack.Looped = true
            blockTrack.Priority = Enum.AnimationPriority.Action4
            blockTrack:Play()

            CharacterClass.Attributes.applyAttribute(character, 'BlockTrack', blockTrack)
        end
    end

    return 'Success'
end

function Block.cancel(character)
    CharacterClass.StatusEffects.disableStatusEffect(character, 'BlockFrames')
    CharacterClass.Actions.endAction(character, 'Block')

    local player = Players:GetPlayerFromCharacter(character) 
    if player then
        ServerRemotes.BlockReplication.fire(player, 'Stop')
    else
        local blockTrack = CharacterClass.Attributes.getAttribute(character, 'BlockTrack')

        blockTrack:Stop(0.25)
        blockTrack:Destroy()
    end
end

return Block
