local Env = select(2, ...)
if not Env.IS_CLASSIC_ERA then return end

-- Classic Era and Season of Discovery. Era links the Classic sim (wowsims/classic) and SoD the SoD
-- sim (wowsims/sod); SoD adds runes.
local isSoD = Env.IS_CLASSIC_ERA_SOD

-- The sims' pages, from HTML_INDECIES in the makefile of wowsims/classic and wowsims/sod.
local classicPages = {
    balance_druid = true,
    feral_druid = true,
    feral_tank_druid = true,
    restoration_druid = true,
    elemental_shaman = true,
    enhancement_shaman = true,
    restoration_shaman = true,
    warden_shaman = true,
    hunter = true,
    mage = true,
    rogue = true,
    holy_paladin = true,
    protection_paladin = true,
    retribution_paladin = true,
    healing_priest = true,
    shadow_priest = true,
    warlock = true,
    warrior = true,
    tank_warrior = true,
}
local sodPages = {
    tank_rogue = true,
    tank_warlock = true,
}
for page in pairs(classicPages) do
    sodPages[page] = true
end

Env.RegisterFlavor({
    name = Env.IS_CLASSIC_ERA_VANILLA and "era" or "sod",
    prelink = Env.IS_CLASSIC_ERA_VANILLA and "https://www.wowsims.com/classic/" or "https://www.wowsims.com/sod/",
    simLayout = "flat",
    simPages = Env.IS_CLASSIC_ERA_VANILLA and classicPages or sodPages,
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
        rune = isSoD and "number" or nil,
    },
    events = isSoD and { "RUNE_UPDATED" } or {},
    CreateTalentString = Env.CreateClassicTalentString,
    CountPointsPerTree = Env.CountClassicPointsPerTree,
    IsBagUpgradeCandidate = Env.IsBagUpgradeNearPlayerLevel,
    DecorateEquippedItem = isSoD and function(itemSpec, unit, slotId)
        itemSpec.rune = Env.GetEngravedRuneSpell(slotId)
    end or nil,
    DecorateBagItem = isSoD and function(itemSpec, bagId, slotId)
        itemSpec.rune = Env.GetEngravedRuneSpell(slotId, bagId)
    end or nil,
})

local TblMaxValIdx = Env.TableMaxValIndex

---Whether most points are in the tree and there are any at all, for specs that can't be the
---fallback of a character without talents.
local function IsTree(t, tree)
    return TblMaxValIdx(t) == tree and (t[tree] or 0) > 0
end

---Whether the item in the slot has the rune engraved. The rune specs are only added on SoD.
local function HasRune(slotId, runeSpellId)
    return Env.GetEngravedRuneSpell(slotId) == runeSpellId
end

if isSoD then
    Env.AddSpec("shaman", "warden", function(t) return HasRune(INVSLOT_LEGS, 408531) end) -- Way of Earth
end
Env.AddSpec("shaman", "elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("shaman", "restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("hunter", "beast_mastery", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", function(t)
    -- feral may have more points in balance too, so check int stat too
    return TblMaxValIdx(t) == 1
        and Env.StatBiggerThanStat("int", "agi")
end)
Env.AddSpec("druid", "restoration", function(t)
    return TblMaxValIdx(t) == 3
        and Env.StatBiggerThanStat("int", "agi")
end)
local function IsFeral(t)
    -- Currently feral may have more points in other trees, check stats too
    return (TblMaxValIdx(t) == 2)
        or Env.StatBiggerThanStat("agi", "int")
        or Env.StatBiggerThanStat("str", "int")
end
Env.AddSpec("druid", "feral_bear", function(t)
    -- The sims' bear presets take Feral Instinct, their cat presets skip it.
    return IsFeral(t)
        and Env.GetTalentRankOrdered(2, 3) >= 3 -- https://www.wowhead.com/classic/spell=16947/feral-instinct
end)
Env.AddSpec("druid", "feral", IsFeral)

if isSoD then
    Env.AddSpec("warlock", "warlocktank", function(t) return HasRune(INVSLOT_HAND, 403789) end) -- Metamorphosis
end
Env.AddSpec("warlock", "affliction", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", function(t) return TblMaxValIdx(t) == 3 end)

if isSoD then
    Env.AddSpec("rogue", "tank", function(t) return HasRune(INVSLOT_CHEST, 400014) end) -- Just a Flesh Wound
end
Env.AddSpec("rogue", "assassination", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warrior", "protection", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("paladin", "holy", function(t) return IsTree(t, 1) end)
Env.AddSpec("paladin", "protection", function(t) return IsTree(t, 2) end)
Env.AddSpec("paladin", "retribution", function(t) return true end)

Env.AddSpec("priest", "holy_disc", function(t) return IsTree(t, 1) or IsTree(t, 2) end)
Env.AddSpec("priest", "shadow", function(t) return true end)
