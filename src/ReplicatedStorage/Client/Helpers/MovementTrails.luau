local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementTrails = {}

local trailPath = ReplicatedStorage.Assets.VFX.Movement.Trails

function MovementTrails.applyTrails(character)
    for _, TrailObject in trailPath:GetChildren() do
        local newObject = TrailObject:Clone()
        local respectiveLimb = character:FindFirstChild(newObject.Name)
        newObject.Parent = respectiveLimb


        local trailWeld = Instance.new('Weld')
        trailWeld.Part0 = newObject
        trailWeld.Part1 = respectiveLimb
        trailWeld.Name = 'TrailWeld'
        trailWeld.Parent = respectiveLimb
    end
end

function MovementTrails.removeTrails(character)
    for _, Object in character:GetDescendants() do
        if not Object:IsA('Part') and not Object:IsA('Weld') then continue end
        if Object.Name == Object.Parent.Name then
            for _, TrailObject in Object:GetDescendants() do
                if not TrailObject:IsA('Trail') then continue end
                TrailObject.Enabled = false
            end

            Debris:AddItem(Object, 1.5)
        end

        if Object.Name == 'TrailWeld' then
            Debris:AddItem(Object, 1.5)
        end
    end
end

return MovementTrails