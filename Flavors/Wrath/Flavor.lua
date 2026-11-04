local Env = select(2, ...)
if not Env.IS_CLASSIC_WRATH then return end

Env.RegisterFlavor({
    name = "wrath",
    prelink = "https://www.wowsims.com/wotlk/",
    simLayout = "flat",
    -- The sim's pages, from HTML_INDECIES in the makefile of wowsims/wotlk.
    simPages = {
        balance_druid = true,
        feral_druid = true,
        feral_tank_druid = true,
        restoration_druid = true,
        elemental_shaman = true,
        enhancement_shaman = true,
        restoration_shaman = true,
        hunter = true,
        mage = true,
        rogue = true,
        holy_paladin = true,
        protection_paladin = true,
        retribution_paladin = true,
        healing_priest = true,
        shadow_priest = true,
        smite_priest = true,
        warlock = true,
        warrior = true,
        protection_warrior = true,
        deathknight = true,
        tank_deathknight = true,
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
    },
    events = { "GLYPH_ADDED", "GLYPH_REMOVED", "GLYPH_UPDATED" },
    CreateTalentString = Env.CreateClassicTalentString,
    CountPointsPerTree = Env.CountClassicPointsPerTree,
    CreateGlyphEntry = Env.CreateWrathGlyphEntry,
    IsBagUpgradeCandidate = Env.IsBagUpgradeAboveTBC,
})

-- Wrath's client has no trade skill display names for these two.
Env.professionNames[GetSpellInfo(25229)] = { skillLine = 755, engName = "Jewelcrafting" }
Env.professionNames[GetSpellInfo(45357)] = { skillLine = 773, engName = "Inscription" }

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
        and Env.GetTalentRankOrdered(2, 22) < 3 -- https://www.wowhead.com/wotlk/spell=57873/protector-of-the-pack
end)
Env.AddSpec("druid", "feral_bear", function(t)
    return TblMaxValIdx(t) == 2
        and Env.GetTalentRankOrdered(2, 22) == 3 -- https://www.wowhead.com/wotlk/spell=57873/protector-of-the-pack
end)
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

Env.AddSpec("priest", "shadow", function(t) return TblMaxValIdx(t) == 3 end)
-- Smite priests (smite_priest) spend their points like healers, so they link the healing sim.
Env.AddSpec("priest", "holy_disc", function(t) return TblMaxValIdx(t) < 3 end)

local function HasDkTankTanlents()
    -- I guess every tank will have at least a sum of those?
    local anticipation = Env.GetTalentRankOrdered(3, 3) -- https://www.wowhead.com/wotlk/spell=55129/anticipation
    local bladeBarrier = Env.GetTalentRankOrdered(1, 3) -- https://www.wowhead.com/wotlk/spell=55226/blade-barrier
    return anticipation + bladeBarrier > 5
end
Env.AddSpec("deathknight", "blood", function(t)
    return not HasDkTankTanlents()
        and TblMaxValIdx(t) == 1
end)
Env.AddSpec("deathknight", "frost", function(t)
    return not HasDkTankTanlents()
        and TblMaxValIdx(t) == 2
end)
Env.AddSpec("deathknight", "unholy", function(t)
    return not HasDkTankTanlents()
        and TblMaxValIdx(t) == 3
end)
-- Tank blood exports the same spec name as DPS blood; the role picks the tank sim.
Env.AddSpec("deathknight", "blood", function(t)
    return HasDkTankTanlents()
end, nil, "tank")
