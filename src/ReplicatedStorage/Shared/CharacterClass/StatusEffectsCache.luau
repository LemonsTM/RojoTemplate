--[[
	Template
	IFrames = {
		OverrideOver = {OtherStatesToBlock}

		OnStart = function(characterClass)
		
	end,
	
	OnEnd = function(characterClass)
	
end
},
}
]]

--// Services
local ServerStorage = game:GetService("ServerStorage")


--// Types
local Types = require(script.Parent.Types)

return {
	Stun = { --// Gets applied during basic hits, applies a slowed effect and locks actions
		Priority = 0,

		OnStart = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 2
			characterClass.Instance.Humanoid.JumpHeight = 0
		end,

		OnEnd = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 16
			characterClass.Instance.Humanoid.JumpHeight = 7.2
		end
	},

	Locked = { --// Gets applied during things like posture breaks, completely locks actions and movement
		Priority = 10, --// Always #1 priority

		OnStart = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 0
			characterClass.Instance.Humanoid.JumpHeight = 0
		end,

		OnEnd = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 16
			characterClass.Instance.Humanoid.JumpHeight = 7.2
		end
	},

	Slowed = {
		Priority = 2,

		OnStart = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 6
		end,
		
		OnEnd = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 16
		end
	},

	HyperArmor = {

		OnStart = function(characterClass)

		end,

		OnEnd = function(characterClass)

		end
	},

	IFrames = {

		OnStart = function(characterClass)

		end,

		OnEnd = function(characterClass)

		end
	},

	ParryFrames = {

		OnStart = function(characterClass)
			
		end,

		OnEnd = function(characterClass)
			
		end
	},

	BlockFrames = {
		Priority = 1,

		OnStart = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 8
			characterClass.Instance.Humanoid.JumpHeight = 0
		end,

		OnEnd = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 16
			characterClass.Instance.Humanoid.JumpHeight = 7.2
		end
	},

	Sprinting = {

		OnStart = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 24
		end,
		
		OnEnd = function(characterClass)
			characterClass.Instance.Humanoid.WalkSpeed = 16
		end
	},

	Ragdoll = {
		Priority = 10,

		OnStart = function(characterClass)
			local RagdollController = require(ServerStorage.Controllers.RagdollController)
			
			RagdollController.Ragdoll(characterClass.Instance)

			characterClass.Instance.Humanoid.WalkSpeed = 0
			characterClass.Instance.Humanoid.JumpHeight = 0
		end,
		
		OnEnd = function(characterClass)
			local RagdollController = require(ServerStorage.Controllers.RagdollController)

			RagdollController.Unragdoll(characterClass.Instance)

			characterClass.Instance.Humanoid.WalkSpeed = 16
			characterClass.Instance.Humanoid.JumpHeight = 7.2
		end
	}
}:: {[string]: Types.StatusEffect}