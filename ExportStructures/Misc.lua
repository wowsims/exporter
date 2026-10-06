local Env = select(2, ...)

---Create glyphs table.
---@return table
function Env.CreateGlyphEntry(isInspect)
    local glyphs = {
        prime = {},
        major = {},
        minor = {},
    }

    if Env.IS_FOREVER or not GetNumGlyphSockets then
        return glyphs
    end

    local unit = isInspect and Env.inspectUnit or "player"
    local numGlyphSockets = GetNumGlyphSockets()
    
    if Env.IS_CLASSIC_WRATH then
        for t = 1, numGlyphSockets do
            local enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(t)
            if enabled and glyphSpellID then
                local glyphtable = glyphType == 1 and glyphs.major or glyphs.minor
                table.insert(glyphtable, { spellID = glyphSpellID })
            end
        end
        return glyphs
    elseif (Env.IS_CLASSIC_CATA or Env.IS_CLASSIC_MISTS) then
        local activeSpecGroup = C_SpecializationInfo.GetActiveSpecGroup(isInspect)
        for t = 1, numGlyphSockets do
            local enabled, glyphType, glyphTooltipIndex, glyphID = GetGlyphSocketInfo(t, activeSpecGroup, isInspect, unit)
            if enabled and glyphType and glyphID then
                local glyphtable = glyphType == 1 and glyphs.major or glyphType == 2 and glyphs.minor or glyphs.prime
                table.insert(glyphtable, { spellID = glyphID })
            end
        end
    end
    -- hack? unsure.. seems normal to me, prime shouldn't be shown in the dat if its mists!
    if(Env.IS_CLASSIC_MISTS) then glyphs.prime = nil end 
    return glyphs
end

Env.profInspectTable = Env.profInspectTable or {}
function Env.AddInspectedProfessions(name, entry)
    Env.profInspectTable[name] = entry
end

---Create professions table.
---@param isInspect boolean
function Env.CreateProfessionEntry(isInspect)
    if isInspect then
        local unit = Env.inspectUnit
        return Env.profInspectTable[UnitName(unit)] or {}
    end
    local professionNames = Env.professionNames or {}
    local professions = {}

    local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
    for i = 1, numSkills do
        local name, _, _, skillLevel = GetSkillLineInfo(i)
        if name and professionNames[name] then
            table.insert(professions, {
                name = professionNames[name].engName,
                level = skillLevel,
            })
        end
    end

    return professions
end

---Create a string in the format "000..000-000..000-000..000". Used for Pre-Mists classic
---@return string
function Env.CreateTalentString()
    local GetTalentRank = Env.GetTalentRankOrdered or function(tab, idx)
        if GetTalentInfo then
            local _, _, _, _, rank = GetTalentInfo(tab, idx)
            return rank or 0
        end
        return 0
    end

    local GetNumTalents = Env.GetNumTalentsFixed or function(tab)
        if _G.GetNumTalents then
            return _G.GetNumTalents(tab) or 0
        end
        return 0
    end

    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 3
    local tabs = {}
    for tab = 1, numTabs do
        local talents = {}
        local count = GetNumTalents(tab)
        for i = 1, count do
            local currRank = GetTalentRank(tab, i)
            table.insert(talents, tostring(currRank))
        end
        table.insert(tabs, table.concat(talents))
    end
    return table.concat(tabs, "-")
end

---Create a string in the format "000000". Used for Mists classic
---@return string
function Env.CreateMistsTalentString(isInspect)
    local unit = isInspect and Env.inspectUnit or "player"
    local GetTalentInfo = C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo
    local activeSpecGroup = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup and C_SpecializationInfo.GetActiveSpecGroup(isInspect) or 1
    local talents = {}
    local numTiers = MAX_NUM_TALENT_TIERS or 6
    for row = 1, numTiers do
        local found = false
        for column = 1, 3 do
            local talentInfo = GetTalentInfo and GetTalentInfo({
                isInspect = isInspect,
                target = unit,
                groupIndex = activeSpecGroup,
                tier = row,
                column = column,
            })
            if talentInfo and talentInfo.selected then
                found = true
                table.insert(talents, tostring(column))
                break
            end
        end
        if not found then
            table.insert(talents, tostring(0))
        end
    end
    return table.concat(talents)
end