local Functions = {}

function Functions.CreateConstraints(character: Model, m)
	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("Motor6D") then
			local a0 = Instance.new("Attachment", v.Part0)
			local a1 = Instance.new("Attachment", v.Part1)
			a0.Name = "RagdollJoint"
			a1.Name = "RagdollJoint"

			a0.CFrame = v.C0
			a1.CFrame = v.C1

			local socket = Instance.new("BallSocketConstraint")
			--socket.Enabled = false
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.Parent = v.Part0
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = m.TwistLimits
			socket.MaxFrictionTorque = m.MaxFrictionTorque
			socket.Restitution = m.Restitution
			socket.UpperAngle = m.UpperLimit
			socket.TwistLowerAngle = m.TwistUpper
			socket.TwistUpperAngle = m.TwistLower
			if v.Name == "Neck" then
				socket.TwistLimitsEnabled = true
				socket.UpperAngle = m.NeckUpper
				socket.TwistLowerAngle = -70
				socket.TwistUpperAngle = 70
			end
		end
	end
end

function Functions.CreateColliders(part: BasePart, collidersize: number, m)
	if not part then return end
	local rp = Instance.new("Part")
	rp.Name = "ColliderPart"
	rp.Size = part.Size*collidersize
	rp.Massless = true			
	rp.CFrame = part.CFrame
	rp.Transparency = 1
	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part

	wc.Parent = rp
	rp.Parent = part
end

function Functions.RecoverJoints(character, m)
	for i,v in pairs(character:GetDescendants()) do
		if v:IsA("Motor6D") then
			v.Enabled = true
		elseif v:IsA("BallSocketConstraint") then
			v.Enabled = false
		end
		if v.Name == "ColliderPart" then
			v:Destroy()
		end
	end
end

return Functions