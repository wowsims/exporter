local Env = select(2, ...)

---Create glyphs table.
---@return table
function Env.CreateGlyphEntry()
    local glyphs = {
        major = {},
        minor = {},
    }

    for t = 1, 6 do
        local enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(t)
        if enabled and glyphSpellID then
            local glyphtable = glyphType == 1 and glyphs.major or glyphs.minor
            table.insert(glyphtable, { spellID = glyphSpellID })
        end
    end

    return glyphs
end

do
    local professionNames = {
        [GetSpellInfo(2018)] = { skillLine = 164, engName = "Blacksmithing" },
        [GetSpellInfo(3104)] = { skillLine = 165, engName = "Leatherworking" },
        [GetSpellInfo(2259)] = { skillLine = 171, engName = "Alchemy" },
        [GetSpellInfo(9134)] = { skillLine = 182, engName = "Herbalism" },
        [GetSpellInfo(2575)] = { skillLine = 186, engName = "Mining" },
        [GetSpellInfo(3908)] = { skillLine = 197, engName = "Tailoring" },
        [GetSpellInfo(12656)] = { skillLine = 202, engName = "Engineering" },
        [GetSpellInfo(7412)] = { skillLine = 333, engName = "Enchanting" },
        [GetSpellInfo(8617)] = { skillLine = 393, engName = "Skinning" },
    }
    if not Env.IS_CLASSIC_ERA then
        professionNames[GetSpellInfo(25229)] = { skillLine = 755, engName = "Jewelcrafting" }
        professionNames[GetSpellInfo(45357)] = { skillLine = 773, engName = "Inscription" }
    end

    ---Create professions table.
    function Env.CreateProfessionEntry()
        local professions = {}

        for i = 1, GetNumSkillLines() do
            local name, _, _, skillLevel = GetSkillLineInfo(i)
            if professionNames[name] then
                table.insert(professions, {
                    name = professionNames[name].engName,
                    level = skillLevel,
                })
            end
        end

        return professions
    end
end

-- TODO: this
function Env.CheckCharacterSpec(class)
    local specs = WowSimsExporter.specializations

    T1 = GetNumTalents(1)
    T2 = GetNumTalents(2)
    T3 = GetNumTalents(3)

    local spec = ""

    for i, character in ipairs(specs) do
        if character then
            if (character.class == class) then
                if character.comparator(T1, T2, T3) then
                    spec = character.spec
                    break
                end
            end
        end
    end
    return spec
end
