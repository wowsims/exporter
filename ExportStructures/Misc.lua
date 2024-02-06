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

---Create professions table.
function Env.CreateProfessionEntry()
    local professionNames = Env.professionNames
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

---Create a string in the format "000..000-000..000-000..000".
---@return string
function Env.CreateTalentString()
    local GetTalentRank = Env.GetTalentRankOrdered
    local tabs = {}
    for tab = 1, GetNumTalentTabs() do
        local talents = {}
        for i = 1, GetNumTalents(tab) do
            local currRank = GetTalentRank(tab, i)
            table.insert(talents, tostring(currRank))
        end
        table.insert(tabs, table.concat(talents))
    end
    return table.concat(tabs, "-")
end
