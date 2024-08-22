export type weaponConfiguration = {
    Category: 'Light'|'Medium'|'Heavy',

    M1Data: {
        HitboxSize: Vector3,
        HitboxOffset: CFrame,
        BaseDamage: number,
        BasePostureDamage: number,
        StunDuration: number
    },
    M2Data: {
        HitboxSize: Vector3,
        HitboxOffset: CFrame,
        BaseDamage: number,
        StunDuration: number
    },
}

return {
    Fists = {
        Category = 'Light',

        M1Data = {
            HitboxSize = Vector3.new(5, 5, 5),
            HitboxOffset = CFrame.new(0, 0, -3),
            BaseDamage = 6,
            BasePostureDamage = 30, --// amount of posture to deal if theyre blocking
            StunDuration = 1.15
        },
        M2Data = {
            HitboxSize = Vector3.new(5, 5, 5),
            HitboxOffset = CFrame.new(0, 0, -3),
            BaseDamage = 6,
            StunDuration = 1.5
        }
    }
}:: {[string]: weaponConfiguration}