--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--// Imports
local ServerRemotes = nil
local ClientRemotes = nil
if RunService:IsServer() then
	ServerRemotes = require(ServerStorage:FindFirstChild("ServerRemotes"))
else
	ClientRemotes = require(ReplicatedStorage:FindFirstChild("ClientRemotes"))
end

--// Variables
local FXController = {}

--// Public Methods
function FXController.callEffect(
	effectName: string,
	stage: string,
	data: { caster: Instance, extraData: unknown, victim: Instance? }
)
	if RunService:IsClient() then
		local effectModule = require(script.Effects:FindFirstChild(effectName, true))
		if not effectModule then
			return
		end

		effectModule[stage](data)
	end

	if RunService:IsServer() then
		ServerRemotes.CallFX.fireAll({ effectName = effectName, stage = stage, miscData = data })
	end
end

--// Setup networking
function FXController.preLoad()
	ClientRemotes.CallFX.setCallback(
		function(data: {
			effectName: string,
			miscData: { caster: Instance, extraData: unknown, victim: Instance? },
			stage: string,
		})
			FXController.callEffect(data.effectName, data.stage, data.miscData)
		end
	)
end

return FXController
