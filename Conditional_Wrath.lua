local Env = select(2, ...)
if not Env.IS_CLASSIC_WRATH then return end

Env.prelink = "https://wowsims.github.io/wotlk/"

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
    "deathknight",
}

Env.professionNames[GetSpellInfo(25229)] = { skillLine = 755, engName = "Jewelcrafting" }
Env.professionNames[GetSpellInfo(45357)] = { skillLine = 773, engName = "Inscription" }

Env.AddSpec("shaman", "elemental", "elemental_shaman", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("shaman", "enhancement", "enhancement_shaman", function(t) return t[2] > t[1] and t[2] > t[3] end)

Env.AddSpec("hunter", "beast_mastery", "hunter", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("hunter", "marksman", "hunter", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("hunter", "survival", "hunter", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("druid", "balance", "balance_druid", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("druid", "feral", "feral_druid", function(t)
    return t[2] > t[1] and t[2] > t[3]
        and Env.GetTalentRankOrdered(2, 22) < 3 -- https://www.wowhead.com/wotlk/spell=57873/protector-of-the-pack
end)
Env.AddSpec("druid", "feral_bear", "feral_tank_druid", function(t)
    return t[2] > t[1] and t[2] > t[3]
        and Env.GetTalentRankOrdered(2, 22) == 3 -- https://www.wowhead.com/wotlk/spell=57873/protector-of-the-pack
end)

Env.AddSpec("warlock", "affliction", "warlock", function(t) return t[1] > t[1] and t[2] > t[3] end)
Env.AddSpec("warlock", "demonology", "warlock", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("warlock", "destruction", "warlock", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("rogue", "assassination", "rogue", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("rogue", "combat", "rogue", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("rogue", "subtlety", "rogue", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("mage", "arcane", "mage", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("mage", "fire", "mage", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("mage", "frost", "mage", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("warrior", "arms", "warrior", function(t) return t[1] > t[2] and t[1] > t[3] end)
Env.AddSpec("warrior", "fury", "warrior", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("warrior", "protection", "protection_warrior", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("paladin", "protection", "retribution_paladin", function(t) return t[2] > t[1] and t[2] > t[3] end)
Env.AddSpec("paladin", "retribution", "protection_paladin", function(t) return t[3] > t[1] and t[3] > t[2] end)

Env.AddSpec("priest", "shadow", "shadow_priest", function(t) return t[3] > t[1] and t[3] > t[2] end)
Env.AddSpec("priest", "holy_disc", "healing_priest", function(t) return t[3] < t[1] or t[3] < t[2] end)

local function HasDkTankTanlents()
    -- I guess every tank will have at least a sum of those?
    local anticipation = Env.GetTalentRankOrdered(3, 3) -- https://www.wowhead.com/wotlk/spell=55129/anticipation
    local bladeBarrier = Env.GetTalentRankOrdered(1, 3) -- https://www.wowhead.com/wotlk/spell=55226/blade-barrier
    return anticipation + bladeBarrier > 5
end
Env.AddSpec("deathknight", "blood", "deathknight", function(t)
    return not HasDkTankTanlents()
        and t[1] > t[2] and t[1] > t[3]
end)
Env.AddSpec("deathknight", "frost", "deathknight", function(t)
    return not HasDkTankTanlents()
        and t[2] > t[1] and t[2] > t[3]
end)
Env.AddSpec("deathknight", "unholy", "deathknight", function(t)
    return not HasDkTankTanlents()
        and t[3] > t[1] and t[3] > t[2]
end)
Env.AddSpec("deathknight", "blood", "tank_deathknight", function(t)
    return HasDkTankTanlents()
end)
