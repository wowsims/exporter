local Env = select(2, ...)
if not Env.IS_CLASSIC_MISTS then return end

Env.RegisterFlavor({
    name = "mists",
    prelink = "https://www.wowsims.com/mop/",
    classes = {
        "hunter",
        "mage",
        "shaman",
        "priest",
        "rogue",
        "druid",
        "warrior",
        "warlock",
        "paladin",
        "deathknight",
        "monk",
    },
    itemFields = {
        gems = "table",
        random_suffix = "number",
        reforging = "number",
        upgrade_step = "number",
        tinker = "number",
    },
    events = { "GLYPH_ADDED", "GLYPH_REMOVED", "GLYPH_UPDATED" },
    supportsInspect = true,
    CreateTalentString = Env.CreateMistsTalentString,
    GetSpecializationID = function(unit)
        if unit == "player" then
            local activeSpec = C_SpecializationInfo.GetSpecialization()
            return (C_SpecializationInfo.GetSpecializationInfo(activeSpec))
        end
        return GetInspectSpecialization(unit)
    end,
    CreateGlyphEntry = function(isInspect)
        local glyphs = Env.CreateSpecGroupGlyphEntry(isInspect)
        -- Mists has no prime glyphs.
        glyphs.prime = nil
        return glyphs
    end,
    FillFromItemLink = function(itemSpec, itemLink)
        local reforgeId = select(11, strsplit(":", itemLink))
        itemSpec.reforging = tonumber(reforgeId)
    end,
    DecorateEquippedItem = function(itemSpec, unit, slotId)
        local upgradeStep = Env.GetItemUpgradeLevel(unit, slotId)
        if upgradeStep ~= -1 then itemSpec.upgrade_step = upgradeStep end
        if slotId == INVSLOT_HAND then
            local tinkerID = Env.GetHandTinker(unit)
            if tinkerID ~= 0 then itemSpec.tinker = tinkerID end
        end
    end,
    InferProfessions = Env.InferProfessionsFromGear,
})

-- Mists matches specs by specialization ID (GetSpecializationID above), so no check functions.
Env.AddSpec("shaman", "elemental", "shaman/elemental", nil, 262)
Env.AddSpec("shaman", "enhancement", "shaman/enhancement", nil, 263)
Env.AddSpec("shaman", "restoration", "shaman/restoration", nil, 264)

Env.AddSpec("hunter", "beast_mastery", "hunter/beast_mastery", nil, 253)
Env.AddSpec("hunter", "marksman", "hunter/marksmanship", nil, 254)
Env.AddSpec("hunter", "survival", "hunter/survival", nil, 255)

Env.AddSpec("druid", "balance", "druid/balance", nil, 102)
Env.AddSpec("druid", "feral", "druid/feral", nil, 103)
Env.AddSpec("druid", "guardian", "druid/guardian", nil, 104)
Env.AddSpec("druid", "restoration", "druid/restoration", nil, 105)

Env.AddSpec("warlock", "affliction", "warlock/affliction", nil, 265)
Env.AddSpec("warlock", "demonology", "warlock/demonology", nil, 266)
Env.AddSpec("warlock", "destruction", "warlock/destruction", nil, 267)

Env.AddSpec("rogue", "assassination", "rogue/assassination", nil, 259)
Env.AddSpec("rogue", "combat", "rogue/combat", nil, 260)
Env.AddSpec("rogue", "subtlety", "rogue/subtlety", nil, 261)

Env.AddSpec("mage", "arcane", "mage/arcane", nil, 62)
Env.AddSpec("mage", "fire", "mage/fire", nil, 63)
Env.AddSpec("mage", "frost", "mage/frost", nil, 64)

Env.AddSpec("warrior", "arms", "warrior/arms", nil, 71)
Env.AddSpec("warrior", "fury", "warrior/fury", nil, 72)
Env.AddSpec("warrior", "protection", "warrior/protection", nil, 73)

Env.AddSpec("paladin", "holy", "paladin/holy", nil, 65)
Env.AddSpec("paladin", "protection", "paladin/protection", nil, 66)
Env.AddSpec("paladin", "retribution", "paladin/retribution", nil, 70)

Env.AddSpec("priest", "disc", "priest/discipline", nil, 256)
Env.AddSpec("priest", "holy", "priest/holy", nil, 257)
Env.AddSpec("priest", "shadow", "priest/shadow", nil, 258)

Env.AddSpec("deathknight", "blood", "death_knight/blood", nil, 250)
Env.AddSpec("deathknight", "frost", "death_knight/frost", nil, 251)
Env.AddSpec("deathknight", "unholy", "death_knight/unholy", nil, 252)

Env.AddSpec("monk", "brewmaster", "monk/brewmaster", nil, 268)
Env.AddSpec("monk", "mistweaver", "monk/mistweaver", nil, 270)
Env.AddSpec("monk", "windwalker", "monk/windwalker", nil, 269)
