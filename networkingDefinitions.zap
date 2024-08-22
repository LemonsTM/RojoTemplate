-- Configuration
opt server_output = "src/ServerStorage/ServerRemotes.luau"
opt client_output = "src/ReplicatedStorage/ClientRemotes.luau"

opt async_lib = "require(game:GetService('ReplicatedStorage').Packages['_Index']['evaera_promise@4.0.0'].promise)"
opt yield_type = "promise"

opt remote_scope = "Anti_Skid_9000"
opt casing = "camelCase"
opt write_checks = true -- Disable during production

--//FX Replication\\--
event CallFX = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		effectName: string(0..50),
		stage: string(0..25),
		miscData: struct {
			caster: Instance,
			victim: Instance?,
			extraData: unknown
		}
	}
}

--//Combat Remotes\\--

-- M1
event M1 = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
}

event M1Replication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance,
		victim: Instance?,
		weaponUsed: string(..45),
		comboCount: u8(..4),
		timeCasted: f64,
	}
}

event OnM1Cancelled = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance,
		comboCancelling: u8,
		isFeint: boolean?
	}
}

-- Equip
event Equip = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
}

event EquipReplicate = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		status: enum {Enable, Disable},
		caster: Instance
	}
}

-- Dash
funct Dash = {
	call: Async,
	args: enum {Horizontal, Vertical},
	rets: enum {Success, Failure}
}

event OnDashCancelled = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance
	}
}

-- Block
event Block = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: enum {Begin, End}
}

event BlockReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: enum {Start, Stop}
}

-- Sprint
event Sprint = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: enum {Begin, End}
}

-- M2
event M2 = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
}

event M2Replication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance,
		victim: Instance?,
		weaponUsed: string(..45),
		timeCasted: f64
	}
}

-- Feint
event Feint = {
	from: Client,
	type: Reliable,
	call: SingleAsync
}

-- Down Slam
event DownSlam = {
	from: Client,
	type: Reliable,
	call: SingleAsync
}

event DownSlamReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		status: enum {Cast, Hit},
		weaponUsed: string(..50),
		caster: Instance,
	}
}

-- Ragdoll
event ReplicateRagdoll = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: boolean
}

-- Sprint M1
event SprintM1 = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
}

event SprintM1Replication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance,
		victim: Instance?,
		weaponUsed: string(..50),
		status: enum {Start, Hit}
	}
}

-- Slide
funct Slide = {
	call: Async,
	args: enum {Begin, End},
	rets: struct {
		attempt: enum {Success, Failure},
		status: enum {Start, End}?
	}
}

event SlideReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		caster: Instance,
		status: enum {Start, End}
	}
}

-- Climb
event Climb = {
	from: Client,
	type: Unreliable,
	call: SingleAsync,
}

event ClimbReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync
}

event NotifyClimb = {
	from: Client,
	type: Unreliable,
	call: SingleAsync
}

-- Double Jump
funct DoubleJump = {
	call: Async,
	rets: enum {Success, Failure}
}