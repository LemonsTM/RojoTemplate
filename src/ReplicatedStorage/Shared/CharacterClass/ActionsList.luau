--[[
    Template = {
        BlacklistedActions = {},
        BlacklistedStatusEffects = {},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
    }
]]

--// Types
local Types = require(script.Parent.Types)

return {
	M1 = {
		BlacklistedActions = {'M2', 'Dash', 'Block', 'DownSlam', 'SprintM1', 'Slide', 'Climb', 'DoubleJump'},
		BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll'},

		RequiredActions = {},
		RequiredAttributes = {
			['EquippedWeapon'] = 'NaN',
		},
		RequiredStatusEffects = {}
	},

	Equip = {
		BlacklistedActions = { 'M1', 'M2', 'Block', 'DownSlam', 'Climb', 'DoubleJump'},
		BlacklistedStatusEffects = {'Locked'},

		RequiredActions = {},
		RequiredAttributes = {},
		RequiredStatusEffects = {}
	},

    Dash = {
        BlacklistedActions = {'M1', 'Block', 'DownSlam', 'SprintM1', 'Slide', 'Climb', 'M2'},
        BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
    },

	Block = {
		BlacklistedActions = {'Dash', 'M1', 'DownSlam', 'SprintM1', 'M2', 'Slide', 'Climb', 'DoubleJump'},
        BlacklistedStatusEffects = {'Locked', 'Ragdoll'},

        RequiredActions = {},
        RequiredAttributes = {
			['EquippedWeapon'] = 'NaN'
		},
        RequiredStatusEffects = {}
	},

	Sprint = {
		BlacklistedActions = {'M1', 'Block', 'M2', 'Slide'},
        BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll', 'BlockFrames'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
	},

	M2 = {
		BlacklistedActions = {'M1', 'Dash', 'Block', 'Feint', 'DownSlam', 'SprintM1', 'Slide', 'Climb', 'DoubleJump'},
		BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll'},

		RequiredActions = {},
		RequiredAttributes = {
			['EquippedWeapon'] = 'NaN',
		},
		RequiredStatusEffects = {}
	},

	Feint = {
		BlacklistedActions = {},
        BlacklistedStatusEffects = {},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
	},

	DownSlam = {
		BlacklistedActions = {'M1', 'M2', 'Dash', 'Block', 'Feint', 'SprintM1', 'Slide', 'Climb', 'DoubleJump'},
		BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll'},

		RequiredActions = {},
		RequiredAttributes = {
			['EquippedWeapon'] = 'NaN',
		},
		RequiredStatusEffects = {}
	},

	SprintM1 = {
		BlacklistedActions = {'M2', 'Dash', 'Block', 'DownSlam', 'Slide', 'Climb', 'DoubleJump'},
        BlacklistedStatusEffects = {'Stun', 'Locked', 'Ragdoll'},

        RequiredActions = {'Sprint'},
        RequiredAttributes = {
			['EquippedWeapon'] = 'NaN',
		},
        RequiredStatusEffects = {}
	},

	Slide = {
		BlacklistedActions = {'M1', 'Block', 'Dash', 'SprintM1', 'M2', 'Climb', 'DoubleJump'},
        BlacklistedStatusEffects = {'Locked', 'Ragdoll', 'Stun'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
	},

	Climb = {
		BlacklistedActions = {'M1', 'Block', 'Dash', 'SprintM1', 'M2'},
        BlacklistedStatusEffects = {'Locked', 'Ragdoll', 'Stun'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
	},

	DoubleJump = {
		BlacklistedActions = {'M1', 'Block', 'Dash', 'SprintM1', 'M2', 'Climb'},
        BlacklistedStatusEffects = {'Locked', 'Ragdoll', 'Stun'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
	},

	Skill = {
        BlacklistedActions = {'M1', 'Block', 'SprintM1', 'M2', 'DownSlam', 'Climb', 'Slide', 'Dash'},
        BlacklistedStatusEffects = {'Locked', 'Ragdoll', 'Stun'},

        RequiredActions = {},
        RequiredAttributes = {},
        RequiredStatusEffects = {}
    }
} :: { [string]: Types.ActionsList }
