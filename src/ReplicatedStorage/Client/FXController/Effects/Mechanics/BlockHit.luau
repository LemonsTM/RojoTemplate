--// Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local CharacterClassTypes = require(ReplicatedStorage.Shared.CharacterClass.Types)


local BlockHit = {}

function BlockHit.onHit(data: {caster: CharacterClassTypes.R6, victim: CharacterClassTypes.R6, extraData: string})
    local weaponFolder = ReplicatedStorage.Assets.Weapons[data.extraData]

    --// VFX
    local blockHit = ReplicatedStorage.Assets.VFX.Combat.Combat.BlockHit:Clone()
    blockHit.Parent = data.victim.HumanoidRootPart
    
    ParticleAssistant.Emit(blockHit)
    Debris:AddItem(blockHit, 2.5)

    --// SFX
    local blockSounds = {
        [1] = weaponFolder.SFX.block_1,
        [2] = weaponFolder.SFX.block_2,
    }

    local blockSound = blockSounds[math.random(1, #blockSounds)]:Clone()
    blockSound.Parent = data.victim.HumanoidRootPart
    blockSound:Play()

    blockSound.Ended:Once(function()
        blockSound:Destroy()
    end)
end

function BlockHit.onBlockBreak(data: {caster: CharacterClassTypes.R6, victim: CharacterClassTypes.R6})
    --// VFX
    local blockBreak = ReplicatedStorage.Assets.VFX.Combat.Combat.GuardBreak:Clone()
    blockBreak.Parent = data.victim.HumanoidRootPart

    ParticleAssistant.Emit(blockBreak)
    Debris:AddItem(blockBreak, 5)

    --// SFX

end

return BlockHit