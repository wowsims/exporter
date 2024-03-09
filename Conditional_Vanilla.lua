local Env = select(2, ...)
if not Env.IS_CLASSIC_ERA then return end

Env.prelink = "https://wowsims.github.io/sod/"

Env.supportedClasses = {
    "hunter",
    "mage",
    "shaman",
    "priest",
    "rogue",
    "druid",
    "warrior",
    "warlock",
    "paladin",
}

local TblMaxValIdx = Env.TableMaxValIndex

Env.AddSpec("shaman", "elemental", "elemental_shaman", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "enhancement_shaman", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("hunter", "beast_mastery", "hunter", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "hunter", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "hunter", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "balance_druid", function(t)
    -- feral may have more points in balance too, so check int stat too
    return TblMaxValIdx(t) == 1
        and Env.StatBiggerThanStat("int", "agi")
end)
Env.AddSpec("druid", "feral", "feral_druid", function(t)
    -- Currently feral may have more points in other trees, check stats too
    return (TblMaxValIdx(t) == 2)
        or Env.StatBiggerThanStat("agi", "int")
        or Env.StatBiggerThanStat("str", "int")
end)

local function HasMetamorphRune()
    return Env.GetEngravedRuneSpell(10) == 403789
end
Env.AddSpec("warlock", "affliction", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", "warlock", function(t) return not HasMetamorphRune() and TblMaxValIdx(t) == 3 end)
Env.AddSpec("warlock", "warlocktank", "tank_warlock", function(t) return HasMetamorphRune() end)

Env.AddSpec("rogue", "assassination", "rogue", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", "rogue", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", "rogue", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", "mage", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", "mage", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", "mage", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", "warrior", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", "warrior", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("paladin", "retribution", "retribution_paladin", function(t) return true end)

Env.AddSpec("priest", "shadow", "shadow_priest", function(t) return true end)
