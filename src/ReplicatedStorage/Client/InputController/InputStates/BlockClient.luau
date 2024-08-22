--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local ClientRemotes = require(ReplicatedStorage.ClientRemotes)

-- Main
local Types = require(script.Parent.Parent.Types)
type InputType = Types.inputType

--// Variables
local player = Players.LocalPlayer -- We dont add character as a variable since it wont update if the character dies.
local Block: InputType = {
    name = "Block",
	binds = {Enum.KeyCode.F},
	state = {Enum.UserInputState.Begin, Enum.UserInputState.End},
	callback = nil,
}
local blockTrack = nil

--// State Input Callback
Block.callback = function(inputObject: InputObject)
	local character: Model = player.Character

    local state = inputObject.UserInputState.Name

    ClientRemotes.Block.fire(state)
end

ClientRemotes.BlockReplication.setCallback(function(type: "Start" | "Stop")  
    if type == "Start" then
        local equippedWeapon = player.Character:GetAttribute('EquippedWeapon')
    
        local humanoid = player.Character.Humanoid:: Humanoid
        local animator = humanoid:FindFirstChild('Animator'):: Animator

        local blockAnimation = ReplicatedStorage.Assets.Weapons[equippedWeapon].Animations.BlockIdle

        blockTrack = animator:LoadAnimation(blockAnimation)
        blockTrack.Looped = true
        blockTrack.Priority = Enum.AnimationPriority.Action4
        blockTrack:Play()
    elseif type == 'Stop' then
        blockTrack:Stop(0.25)
        blockTrack:Destroy()
    end
end)

return Block
