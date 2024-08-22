local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ServerRemotes = require(ServerStorage.ServerRemotes)
local FXController = require(ReplicatedStorage.Client.FXController)
local CharacterClass = require(ReplicatedStorage.Shared.CharacterClass)
local Dash = {}

function Dash.onRemote(character: Model, player: Player, axis)
    if not character then return 'Failure' end

    if CharacterClass.Actions.isActionActive(character, 'Dash') then return 'Failure' end
    if not CharacterClass.Actions.isActionSafe(character, 'Dash') then return 'Failure' end
    if CharacterClass.Attributes.getAttribute(character, axis.. 'CD') then return 'Failure' end

    CharacterClass.Actions.startAction(character, 'Dash', 0.35)
    CharacterClass.StatusEffects.enableStatusEffect(character, 'IFrames', 0.15)
    CharacterClass.Attributes.applyAttribute(character, 'DashCancelFrames', true, 0.15)
    CharacterClass.Attributes.applyAttribute(character, axis.. 'CD')

    task.delay(1.5, function()
        CharacterClass.Attributes.removeAttribute(character, axis.. 'CD')
    end)

    FXController.callEffect('DashEffects', 'onDashStart', {caster = character})

    return 'Success'
end

function Dash.cancel(character)
    ServerRemotes.OnDashCancelled.fireAll({caster = character})
end

return Dash