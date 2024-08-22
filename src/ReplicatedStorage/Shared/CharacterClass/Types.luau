--// Character Systems
export type Action = {
	IsDisabled: boolean,
	IsActive: boolean,
	CooldownInfo: {
		StartedAt: number?,
		ReleaseTime: number?
	},
}

export type StatusEffect = {
	IsActive: boolean,
	Priority: number?,
	OnStart: (Character, duration: number?) -> ()?,
	OnEnd: (Character, any?) -> ()?
}

export type Attribute = {
	Value: any?
}

--// Character Setup
export type R6 = Model &  {
	Humanoid: Humanoid & {
		HumanoidDescription: HumanoidDescription,
		Animator: Animator
	},
	HumanoidRootPart: BasePart & {
		RootAttachment: Attachment,
		RootJoint: Motor6D	
	},

	Head: BasePart & {
		FaceCenterAttachment: Attachment,
		FaceFrontAttachment: Attachment,
		HairAttachment: Attachment,
		HatAttachment: Attachment,
		Mesh: SpecialMesh,
		face: Decal,
	},
	Torso: BasePart & {
		BodyBackAttachment: Attachment,
		BodyFrontAttachment: Attachment,
		LeftCollarAttachment: Attachment,
		NeckAttachment: Attachment,
		RightCollarAttachment: Attachment,
		WaistBackAttachment: Attachment,
		WaistCenterAttachment: Attachment,
		WaistFrontAttachment: Attachment,
		['Left Hip']: Motor6D,
		['Left Shoulder']: Motor6D,
		['Neck']: Motor6D,
		['Right Hip']: Motor6D,
		['Right Right Shoulder']: Motor6D,
	},
	['Left Arm']: BasePart & {
		LeftGripAttachment: Attachment,
		LeftShoulderAttachment: Attachment,
	},
	['Left Leg']: BasePart & {
		LeftFootAttachment: Attachment,
	},
	['Right Arm']: BasePart & {
		RightGripAttachment: Attachment,
		RightShoulderAttachment: Attachment,
	},
	['Right Leg']: BasePart & {
		RightFootAttachment: Attachment,
	},
}

export type Character = {
	Actions: {[string]: Action},
	StatusEffects: {[string]: boolean},
	Attributes: {[string]: Attribute},
	Connections: {[string]: RBXScriptConnection},
    Threads: {[string]: thread},
	
	Instance: R6
}

--// Character Class
export type CharacterClass = {
    Construct: (Model) -> (Character),
	Actions: ActionsManagement,
	StatusEffects: StatusEffects,
	Attributes: AttributesCache
}

--// Actions Management
export type ActionsManagement = {
    giveAction: (characterModel: Model, actionName: string) -> (),
    removeAction: (characterModel: Model, actionName: string) -> (),
    startAction: (characterModel: Model, actionName: string, duration: number?) -> (),
    endAction: (characterModel: Model, actionName: string) -> (),
    disableAction: (characterModel: Model, actionName: string, duration: number?) -> (),
    enableAction: (characterModel: Model, actionName: string) -> (),
    applyCooldown: (characterModel: Model, actionName: string, duration: number) -> (),
    removeCooldown: (characterModel: Model, actionName: string) -> (),
    isActionSafe: (characterModel: Model, actionName: string) -> boolean,
	isActionActive: (characterMode: Model, actionName: string) -> boolean,
}

--// Status Effects
export type StatusEffects = {
    enableStatusEffect: (characterModel: Model, statusEffect: string, duration: number?) -> (),
    disableStatusEffect: (characterModel: Model, statusEffect: string) -> (),
	isStatusActive: (characterModel: Model, statusEffect: string) -> (boolean),
}

export type ActionsList = {
	BlacklistedActions: {string}?,
	BlacklistedStatusEffects: {string}?,

	RequiredActions: {string}?,
	RequiredAttributes: {[string]: any}?,
	RequiredStatusEffects: {string}?,
}

--// Character Cache
export type CharacterCache = {
    createCharacter: (R6) -> Character,
    getCharacterCache: (characterModel: Character) -> Character,
    getActionCache: (characterModel: Model, actionName: string) -> (Character, Action),
    getStatusCache: (characterModel: Model, statusEffect: string) -> (Character, StatusEffect),
}

--// Attributes Cache
export type AttributesCache = {
    applyAttribute: (characterModel: Model, attributeName: string, value: any, duration: number?, doReplicate: boolean?) -> (),
    removeAttribute: (characterModel: Model, attributeName: string, doReplicate: boolean?) -> (),
    getAttribute: (characterModel: Model, attributeName: string) -> (any?)
}

return nil
