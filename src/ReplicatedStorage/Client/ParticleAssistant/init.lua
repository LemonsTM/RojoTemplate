local ParticleAssistant = {
    Math = require(script.MathLibrary)
}

--//Services\\--
local TweenService = game:GetService("TweenService")

--//Main Methods\\--
-- Creates new object and automtically parents it for you
function ParticleAssistant.Setup(OriginalObject: BasePart|MeshPart|Attachment): BasePart|MeshPart|Attachment
    local NewObject = OriginalObject:Clone():: Attachment|BasePart|MeshPart
    NewObject.Parent = workspace:FindFirstChild('Ignore')


    return NewObject
end

-- Emits all particle emitters inside of an object, can also toggle beams
--// Fade out time for beams ONLY
function ParticleAssistant.Emit(ParticleObject: BasePart|Attachment, FadeOutTime: number?): ()
	for _, Object: Instance in ParticleObject:GetDescendants() do
		task.spawn(function()
		if not Object:IsA('ParticleEmitter') and not Object:IsA('Beam') then return end

		if not Object:GetAttribute('EmitDuration') and not Object:IsA('Beam') then
			if Object:GetAttribute('EmitDelay') then
				task.delay(Object:GetAttribute('EmitDelay'), function()
					Object:Emit(Object:GetAttribute('EmitCount'))
				end)
				
				return
			end

			Object:Emit(Object:GetAttribute('EmitCount'))
			return
		end

		if Object:GetAttribute('EmitDelay') then
			task.wait(Object:GetAttribute('EmitDelay'))
		end

		Object.Enabled = true
		if not Object:GetAttribute('EmitDuration') then return end
		task.delay(Object:GetAttribute('EmitDuration'), function()
			ParticleAssistant.TweenValue(Object.Parent, 'Transparency', 1, 0.25 or FadeOutTime, 30)
			task.wait(0.35 or FadeOutTime)
			Object.Enabled = false
		end)
	end)
	end
end

-- Toggles the Enabled property of all ParticleEmitters or beams found in the particle object
function ParticleAssistant.ToggleEmit(ParticleObject: BasePart|Attachment, ForceChange: boolean)
    for _, Object in ParticleObject:GetDescendants() do
		if not Object:IsA('ParticleEmitter') and not Object:IsA('Beam') then continue end
		local particleObject = Object:: ParticleEmitter|Beam

        if ForceChange == nil then
            particleObject.Enabled = not Object.Enabled
            return
        end

        particleObject.Enabled = ForceChange
    end
end

-- Quickly welds two parts together
function ParticleAssistant.EasyWeld(Part0, Part1)
    local Weld = Instance.new('Weld')
    Weld.Part0 = Part0
    Weld.Part1 = Part1
    Weld.Parent = Part1

	local connection; connection = Part1.AncestryChanged:Connect(function(_, parent)
		if not parent then 
			Weld:Destroy()
			connection:Disconnect()
		end
	end)

	local connection1; connection1 = Part0.AncestryChanged:Connect(function(_, parent)
		if not parent then 
			Weld:Destroy()
			connection1:Disconnect()
		end
	end)
end

--//Specific Methods\\--
-- Allows you to tween number sequences and color sequences in objects
function ParticleAssistant.TweenValue(ParticleObject, Property: string, TargetValue: any, TweenDuration: number, Steps: number)
	Steps = Steps or 30
	local StepDuration = TweenDuration / Steps

	for _, Object in ParticleObject:GetDescendants() do
		if not Object:IsA("ParticleEmitter") and not Object:IsA('Beam') then
			continue
		end
		task.spawn(function()
			local InitialValue = Object[Property]

			for i = 0, Steps do
				local Progress: number = i / Steps
				local CurrentValue: NumberSequence|ColorSequence

				if typeof(InitialValue) == "NumberSequence" then
					local InitialKeypoints = InitialValue.Keypoints
					local TargetKeypoints

					if typeof(TargetValue) == "NumberSequence" then
						TargetKeypoints = TargetValue.Keypoints
					else
						TargetKeypoints = {}
						for j = 1, #InitialKeypoints do
							table.insert(
								TargetKeypoints,
								NumberSequenceKeypoint.new(InitialKeypoints[j].Time, TargetValue)
							)
						end
					end

					local InterpolatedKeypoints: {NumberSequenceKeypoint} = {}
					for j = 1, #InitialKeypoints do
						local InitialKeypointValue: number = InitialKeypoints[j].Value
						local TargetKeypointValue: number = TargetKeypoints[j].Value
						local InterpolatedValue: number = InitialKeypointValue
							+ (TargetKeypointValue - InitialKeypointValue) * Progress
						table.insert(
							InterpolatedKeypoints,
							NumberSequenceKeypoint.new(InitialKeypoints[j].Time, InterpolatedValue)
						)
					end
					CurrentValue = NumberSequence.new(InterpolatedKeypoints)
				elseif typeof(InitialValue) == "ColorSequence" then
					local InitialColor = InitialValue.Keypoints[1].Value
					CurrentValue = ColorSequence.new(InitialColor:Lerp(TargetValue, Progress))
				elseif typeof(InitialValue) == "number" then
					CurrentValue = InitialValue + (TargetValue - InitialValue) * Progress
				else
					return
				end

				Object[Property] = CurrentValue
				task.wait(StepDuration)
			end
		end)
	end
end

-- Lets you send an object in a specific direction
function ParticleAssistant.LaunchObject(Object: BasePart|MeshPart, Distance: number, Duration: number): Tween
    local TweenData: TweenInfo = TweenInfo.new(
        Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out,
        0
    )

    local Destination: Vector3 = Object.Position + Vector3.new(0, 0, Distance)

    local LaunchTween: Tween = TweenService:Create(Object, TweenData, {Position = Destination})
    LaunchTween:Play()

    return LaunchTween
end

return ParticleAssistant