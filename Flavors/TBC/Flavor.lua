local Env = select(2, ...)
if not Env.IS_CLASSIC_TBC then return end

Env.RegisterFlavor({
    name = "tbc",
    prelink = "https://www.wowsims.com/tbc/",
    simLayout = "class_role",
    -- The sim's pages, from ui/specs/<class>/<spec>/spec.ts in wowsims/tbc-new.
    simPages = {
        ["druid/balance"] = true,
        ["druid/feralbear"] = true,
        ["druid/feralcat"] = true,
        ["druid/restoration"] = true,
        ["hunter/dps"] = true,
        ["mage/dps"] = true,
        ["paladin/holy"] = true,
        ["paladin/protection"] = true,
        ["paladin/retribution"] = true,
        ["priest/dps"] = true,
        ["priest/healer"] = true,
        ["rogue/dps"] = true,
        ["shaman/elemental"] = true,
        ["shaman/enhancement"] = true,
        ["shaman/restoration"] = true,
        ["warlock/dps"] = true,
        ["warrior/dps"] = true,
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
    },
    itemFields = {
        random_suffix = "number",
        gems = "table",
    },
    characterButtonPoint = { "TOPLEFT", "CharacterFrameTab5", "TOPRIGHT", 0, 0 },
    CreateTalentString = Env.CreateClassicTalentString,
    CountPointsPerTree = Env.CountClassicPointsPerTree,
})

local TblMaxValIdx = Env.TableMaxValIndex

Env.AddSpec("shaman", "elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("shaman", "restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("hunter", "beast_mastery", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", function(t) return TblMaxValIdx(t) == 1 end)
-- Not split into feral_bear: the sim's default cat and bear presets share one talent build.
Env.AddSpec("druid", "feral", function(t) return TblMaxValIdx(t) == 2 end)
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

Env.AddSpec("priest", "holy_disc", function(t) return TblMaxValIdx(t) < 3 end)
Env.AddSpec("priest", "shadow", function(t) return TblMaxValIdx(t) == 3 end)
