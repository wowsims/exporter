local Env = select(2, ...)
if not Env.IS_CLASSIC_MISTS then return end

Env.RegisterFlavor({
    name = "mists",
    prelink = "https://www.wowsims.com/mop/",
    simLayout = "class_spec",
    -- The sim's pages, from ui/specs/<class>/<spec>/spec.ts in wowsims/mop.
    simPages = {
        ["death_knight/blood"] = true,
        ["death_knight/frost"] = true,
        ["death_knight/unholy"] = true,
        ["druid/balance"] = true,
        ["druid/feral"] = true,
        ["druid/guardian"] = true,
        ["druid/restoration"] = true,
        ["hunter/beast_mastery"] = true,
        ["hunter/marksmanship"] = true,
        ["hunter/survival"] = true,
        ["mage/arcane"] = true,
        ["mage/fire"] = true,
        ["mage/frost"] = true,
        ["monk/brewmaster"] = true,
        ["monk/mistweaver"] = true,
        ["monk/windwalker"] = true,
        ["paladin/holy"] = true,
        ["paladin/protection"] = true,
        ["paladin/retribution"] = true,
        ["priest/discipline"] = true,
        ["priest/holy"] = true,
        ["priest/shadow"] = true,
        ["rogue/assassination"] = true,
        ["rogue/combat"] = true,
        ["rogue/subtlety"] = true,
        ["shaman/elemental"] = true,
        ["shaman/enhancement"] = true,
        ["shaman/restoration"] = true,
        ["warlock/affliction"] = true,
        ["warlock/demonology"] = true,
        ["warlock/destruction"] = true,
        ["warrior/arms"] = true,
        ["warrior/fury"] = true,
        ["warrior/protection"] = true,
    },
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
Env.AddSpec("shaman", "elemental", nil, 262)
Env.AddSpec("shaman", "enhancement", nil, 263)
Env.AddSpec("shaman", "restoration", nil, 264)

Env.AddSpec("hunter", "beast_mastery", nil, 253)
Env.AddSpec("hunter", "marksman", nil, 254)
Env.AddSpec("hunter", "survival", nil, 255)

Env.AddSpec("druid", "balance", nil, 102)
Env.AddSpec("druid", "feral", nil, 103)
Env.AddSpec("druid", "guardian", nil, 104)
Env.AddSpec("druid", "restoration", nil, 105)

Env.AddSpec("warlock", "affliction", nil, 265)
Env.AddSpec("warlock", "demonology", nil, 266)
Env.AddSpec("warlock", "destruction", nil, 267)

Env.AddSpec("rogue", "assassination", nil, 259)
Env.AddSpec("rogue", "combat", nil, 260)
Env.AddSpec("rogue", "subtlety", nil, 261)

Env.AddSpec("mage", "arcane", nil, 62)
Env.AddSpec("mage", "fire", nil, 63)
Env.AddSpec("mage", "frost", nil, 64)

Env.AddSpec("warrior", "arms", nil, 71)
Env.AddSpec("warrior", "fury", nil, 72)
Env.AddSpec("warrior", "protection", nil, 73)

Env.AddSpec("paladin", "holy", nil, 65)
Env.AddSpec("paladin", "protection", nil, 66)
Env.AddSpec("paladin", "retribution", nil, 70)

Env.AddSpec("priest", "disc", nil, 256)
Env.AddSpec("priest", "holy", nil, 257)
Env.AddSpec("priest", "shadow", nil, 258)

Env.AddSpec("deathknight", "blood", nil, 250)
Env.AddSpec("deathknight", "frost", nil, 251)
Env.AddSpec("deathknight", "unholy", nil, 252)

Env.AddSpec("monk", "brewmaster", nil, 268)
Env.AddSpec("monk", "mistweaver", nil, 270)
Env.AddSpec("monk", "windwalker", nil, 269)
