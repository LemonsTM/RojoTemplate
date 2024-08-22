export type PassedData = {
	caster: Model,
	victim: Model?,
	MousePosition: Vector3?,
}

export type SkillData = PassedData & {
	skillName: string,
	stage: string?, --// Defaults to onStart
}

return {}