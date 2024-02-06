local Env = select(2, ...)
if not Env.IS_CLASSIC_ERA then return end

Env.prelink = "https://wowsims.github.io/sod/"

Env.supportedClasses = {
    "hunter",
    -- "mage",
    -- "shaman",
    -- "priest",
    -- "rogue",
    "druid",
    "warrior",
    "warlock",
    -- "paladin",
}

--Env.AddSpec("shaman", "elemental", "elemental_shaman", function(t) return t[1] > t[2] and t[1] > t[3] end)
--Env.AddSpec("shaman", "enhancement", "enhancement_shaman", function(t) return t[2] > t[1] and t[2] > t[3] end)

Env.AddSpec("hunter", "beast_mastery", "hunter", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("hunter", "marksman", "hunter", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("hunter", "survival", "hunter", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("druid", "balance", "balance_druid", function(t)
    -- feral may have more points in balance too, so check int stat too
    return t[1] > t[2] and t[1] > t[3]
        and Env.StatBiggerThanStat("int", "agi")
end)
Env.AddSpec("druid", "feral", "feral_druid", function(t)
    -- Currently feral may have more points in other trees, check stats too
    return (t[2] > t[1] and t[2] > t[3])
        or Env.StatBiggerThanStat("agi", "int")
        or Env.StatBiggerThanStat("str", "int")
end)
--Env.AddSpec("druid", "feral_bear", "feral_tank_druid", function(t) return t[2] > t[1] and t[2] > t[3] end)

local function HasMetamorphRune()
    return Env.GetEngravedRuneSpell(10) == 403789
end
Env.AddSpec("warlock", "affliction", "warlock", function(t)
    return not HasMetamorphRune() and t[1] > t[1] and t[2] > t[3]
end)
Env.AddSpec("warlock", "demonology", "warlock", function(t)
    return not HasMetamorphRune() and t[2] > t[1] and t[2] > t[3]
end)
Env.AddSpec("warlock", "destruction", "warlock", function(t)
    return not HasMetamorphRune() and t[3] > t[1] and t[3] > t[2]
end)
Env.AddSpec("warlock", "warlocktank", "tank_warlock", function(t) return HasMetamorphRune() end)

--Env.AddSpec("rogue", "assassination", "rogue", function(t) return t[1] > t[2] and t[1] > t[3] end)
--Env.AddSpec("rogue", "combat", "rogue", function(t) return t[2] > t[1] and t[2] > t[3] end)
--Env.AddSpec("rogue", "subtlety", "rogue", function(t) return t[3] > t[1] and t[3] > t[2] end)

--Env.AddSpec("mage", "arcane", "mage", function(t) return t[1] > t[2] and t[1] > t[3] end)
--Env.AddSpec("mage", "fire", "mage", function(t) return t[2] > t[1] and t[2] > t[3] end)
--Env.AddSpec("mage", "frost", "mage", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("warrior", "arms", "warrior", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("warrior", "fury", "warrior", function(t) return t[2] > t[1] and t[2] > t[3] end)
--Env.AddSpec("warrior", "protection", "protection_warrior", function(t) return t[3] > t[1] and t[3] > t[2] end)

--Env.AddSpec("paladin", "protection", "retribution_paladin", function(t) return t[2] > t[1] and t[2] > t[3] end)
--Env.AddSpec("paladin", "retribution", "protection_paladin", function(t) return t[3] > t[1] and t[3] > t[2] end)

--Env.AddSpec("priest", "shadow", "shadow_priest", function(t) return t[3] > t[1] and t[3] > t[2] end)
--Env.AddSpec("priest", "holy_disc", "healing_priest", function(t) return t[3] < t[1] or t[3] < t[2] end)
