local SkillTemplate = {}

function SkillTemplate.onStart(data: {caster: Model})
    print('Skill started on client!')
end

return SkillTemplate