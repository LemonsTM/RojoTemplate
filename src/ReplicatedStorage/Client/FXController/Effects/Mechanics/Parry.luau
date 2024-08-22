local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ParticleAssistant = require(ReplicatedStorage.Client.ParticleAssistant)
local Parry = {}

function Parry.Parried(data: { caster: Model, victim: Model })
	--// Main Variables
	local parryAnimation = ReplicatedStorage.Assets.Animations.Combat.Parry
	local parriedAnimation = ReplicatedStorage.Assets.Animations.Combat.Parried

	--// SFX Management
	local parrySounds = { "Parry1", "Parry2", "Parry3", "Parry4" }
	local sfxFolder = ReplicatedStorage.Assets.SFX
	local sound = sfxFolder:FindFirstChild(parrySounds[math.random(1, #parrySounds)]):Clone() :: Sound
	sound.Parent = data.victim:FindFirstChild("HumanoidRootPart")
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)

        -- VFX Management
        local hitVFX = ReplicatedStorage.Assets.VFX.Combat.Combat.Parry:Clone()
        hitVFX.Parent = data.victim:FindFirstChild('HumanoidRootPart')
    
        ParticleAssistant.Emit(hitVFX)
    
        hitVFX.PointLight.Enabled = true
        TweenService:Create(hitVFX.PointLight, TweenInfo.new(0.355, Enum.EasingStyle.Linear), { ["Brightness"] = 0 }):Play()
        Debris:AddItem(hitVFX, 2.5)
    
        if data.caster == Players.LocalPlayer.Character then
            local casterHumanoid = data.caster:FindFirstChild('Humanoid'):: Humanoid
            local animator = casterHumanoid:FindFirstChild('Animator'):: Animator
    
            --// Stop some animations :p
            for _, animationTrack in animator:GetPlayingAnimationTracks() do
                if tonumber(animationTrack.Animation.Name) ~= nil or animationTrack.Animation.Name == 'M2' then
                    animationTrack:Stop(0.1)
                    animationTrack:Destroy()
                end
            end
            
            --// Parried Animation            
            local parriedTrack = animator:LoadAnimation(parriedAnimation)
            parriedTrack.Looped = false
            parriedTrack.Priority = Enum.AnimationPriority.Action4
            parriedTrack:Play(0.15)
    
            parriedTrack.Ended:Once(function()
                parriedTrack:Stop(0.25)
                parriedTrack:Destroy()
            end)
        end
    
        if data.victim == Players.LocalPlayer.Character then
            --// Parry Animation
            local victimHumanoid = data.victim:FindFirstChild('Humanoid'):: Humanoid
            local animator = victimHumanoid:FindFirstChild('Animator'):: Animator
            local parryTrack = animator:LoadAnimation(parryAnimation)
            parryTrack.Looped = false
            parryTrack.Priority = Enum.AnimationPriority.Action2
            parryTrack:Play()
    
            parryTrack.Ended:Once(function()
                parryTrack:Destroy()
            end)
        end
end

return Parry
