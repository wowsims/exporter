local Env = select(2, ...)

---Create glyphs table from Wrath's glyph sockets.
---@return table
function Env.CreateWrathGlyphEntry()
    local numGlyphSockets = GetNumGlyphSockets()
    local glyphs = {
        prime = {},
        major = {},
        minor = {},
    }

    for t = 1, numGlyphSockets do
        local enabled, glyphType, glyphSpellID = GetGlyphSocketInfo(t)
        if enabled and glyphSpellID then
            local glyphtable = glyphType == 1 and glyphs.major or glyphs.minor
            table.insert(glyphtable, { spellID = glyphSpellID })
        end
    end
    return glyphs
end

---Create glyphs table from the active spec group's glyph sockets (Cataclysm and later).
---@param isInspect boolean
---@return table
function Env.CreateSpecGroupGlyphEntry(isInspect)
    local unit = isInspect and Env.inspectUnit or "player"
    local numGlyphSockets = GetNumGlyphSockets()
    local glyphs = {
        prime = {},
        major = {},
        minor = {},
    }

    local activeSpecGroup = C_SpecializationInfo.GetActiveSpecGroup(isInspect)
    for t = 1, numGlyphSockets do
        local enabled, glyphType, glyphTooltipIndex, glyphID = GetGlyphSocketInfo(t, activeSpecGroup, isInspect, unit)
        if enabled and glyphType and glyphID then
            local glyphtable = glyphType == 1 and glyphs.major or glyphType == 2 and glyphs.minor or glyphs.prime
            table.insert(glyphtable, { spellID = glyphID })
        end
    end
    return glyphs
end
