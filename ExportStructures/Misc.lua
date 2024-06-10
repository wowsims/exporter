local Env = select(2, ...)

---Create glyphs table.
---@return table
function Env.CreateGlyphEntry()
    local numGlyphSockets = GetNumGlyphSockets();
    local glyphs = {
        prime = {},
        major = {},
        minor = {},
    }
    
    if Env.IS_CLASSIC_WRATH then
        for t = 1, numGlyphSockets do
            local enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(t)
            if enabled and glyphSpellID then
                local glyphtable = glyphType == 1 and glyphs.major or glyphs.minor
                table.insert(glyphtable, { spellID = glyphSpellID })
            end
        end
        return glyphs
    elseif (Env.IS_CLASSIC_CATA) then
        for t = 1, numGlyphSockets do
            local enabled, glyphType, glyphTooltipIndex, glyphID = GetGlyphSocketInfo(t)
            if enabled and glyphType and glyphID then
                local glyphtable = glyphType == 1 and glyphs.major or glyphType == 2 and glyphs.minor or glyphs.prime
                table.insert(glyphtable, { spellID = glyphID })
            end
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
    local GetNumTalents = Env.GetNumTalentsFixed
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
