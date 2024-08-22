--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)

--// Variables
local Sprint = {}
local CharacterStorage = {}

--// Constants
local DOUBLE_TAP_INTERVAL = 0.25

--// Public Methods
function Sprint.onRemote(character: CharacterClassTypes.R6, _: Player, inputState: 'Begin'|'End')
    if not CharacterClass.Actions.isActionSafe(character, 'Sprint') then return end

    local equippedWeapon = CharacterClass.Attributes.getAttribute(character, 'EquippedWeapon')

    local lastTimePressed = CharacterClass.Attributes.getAttribute(character, 'lastTimePressed_W') or 0
    local previousState = CharacterClass.Attributes.getAttribute(character, 'previousSprintState') or 'End'
    
    local currentTime = os.clock()
    local shouldStart = inputState == 'Begin' and previousState == 'End' and currentTime - lastTimePressed <= DOUBLE_TAP_INTERVAL

    if inputState == 'Begin' then
        CharacterClass.Attributes.applyAttribute(character, 'lastTimePressed_W', currentTime)
    end
    CharacterClass.Attributes.applyAttribute(character, 'previousCall', inputState)

    if shouldStart then
        CharacterClass.Actions.startAction(character, 'Sprint')

        local animationObject = ReplicatedStorage.Assets.Animations.Movement.Run
        if equippedWeapon then
            animationObject = ReplicatedStorage.Assets.Weapons[equippedWeapon].Animations.Run
        end

        local animator = character.Humanoid.Animator
        local runningTrack = animator:LoadAnimation(animationObject)
        runningTrack.Priority = Enum.AnimationPriority.Action
        runningTrack.Looped = true
        runningTrack:Play(0.25)

        local equipIdle = CharacterClass.Attributes.getAttribute(character, "EquipIdle")
        if equipIdle then
            equipIdle:Stop(0.15)
        end

        CharacterClass.Attributes.applyAttribute(character, 'SprintingTrack', runningTrack)
        CharacterClass.StatusEffects.enableStatusEffect(character, 'Sprinting')

    elseif not shouldStart and inputState == 'End' and CharacterClass.Actions.isActionActive(character, 'Sprint') then
        CharacterClass.Actions.endAction(character, 'Sprint')
        
        CharacterClass.StatusEffects.disableStatusEffect(character, 'Sprinting')

        local sprintingTrack  = CharacterClass.Attributes.getAttribute(character, 'SprintingTrack')
        sprintingTrack:Stop(0.25)
        sprintingTrack:Destroy()
        CharacterClass.Attributes.removeAttribute(character, 'SprintingTrack')

        local equipIdle = CharacterClass.Attributes.getAttribute(character, "EquipIdle")
        if equipIdle then
            equipIdle:Play(0.25)
        end
    end
end

function Sprint.cancel(character)
    CharacterClass.Actions.endAction(character, 'Sprint')

    local sprintingTrack  = CharacterClass.Attributes.getAttribute(character, 'SprintingTrack')
    sprintingTrack:Stop(0.25)
    sprintingTrack:Destroy()
    CharacterClass.Attributes.removeAttribute(character, 'SprintingTrack')

    CharacterClass.StatusEffects.disableStatusEffect(character, 'Sprinting')

    local equipIdle = CharacterClass.Attributes.getAttribute(character, "EquipIdle")
    if equipIdle then
        equipIdle:Play(0.25)
    end
end

return Sprint
