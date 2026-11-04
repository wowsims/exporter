local Env = select(2, ...)
if not Env.IS_CLASSIC_CATA then return end

Env.RegisterFlavor({
    name = "cata",
    prelink = "https://www.wowsims.com/cata/",
    simLayout = "class_spec",
    -- The sim's pages, from PAGE_INDECES in the makefile of wowsims/cata.
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
    },
    itemFields = {
        gems = "table",
        random_suffix = "number",
        reforging = "number",
    },
    events = { "GLYPH_ADDED", "GLYPH_REMOVED", "GLYPH_UPDATED" },
    CreateTalentString = Env.CreateClassicTalentString,
    CountPointsPerTree = Env.CountClassicPointsPerTree,
    CreateGlyphEntry = Env.CreateSpecGroupGlyphEntry,
    IsBagUpgradeCandidate = Env.IsBagUpgradeAboveTBC,
    DecorateEquippedItem = function(itemSpec, unit, slotId)
        itemSpec.reforging = Env.GetReforgeId(unit, slotId)
    end,
})

local TblMaxValIdx = Env.TableMaxValIndex

Env.AddSpec("shaman", "elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("shaman", "restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("hunter", "beast_mastery", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("druid", "feral", function(t)
    return TblMaxValIdx(t) == 2
        -- and Env.GetTalentRankOrdered(2, 1) < 3 -- https://www.wowhead.com/cata/spell=16929/thick-hide
end)
--[[ 
Env.AddSpec("druid", "guardian", function(t)
    return TblMaxValIdx(t) == 2
        and Env.GetTalentRankOrdered(2, 1) == 3 -- https://www.wowhead.com/cata/spell=16929/thick-hide
end) 
]]
Env.AddSpec("druid", "restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warlock", "affliction", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("rogue", "assassination", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warrior", "protection", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("paladin", "holy", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("paladin", "protection", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("paladin", "retribution", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("priest", "disc", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("priest", "holy", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("priest", "shadow", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("deathknight", "blood", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("deathknight", "frost", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("deathknight", "unholy", function(t) return TblMaxValIdx(t) == 3 end)
