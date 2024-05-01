local Env = select(2, ...)
if not Env.IS_CLASSIC_CATA then return end

Env.prelink = "https://wowsims.github.io/cata/"

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


local TblMaxValIdx = Env.TableMaxValIndex

Env.AddSpec("shaman", "elemental", "elemental_shaman", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "enhancement_shaman", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("hunter", "beast_mastery", "hunter", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "hunter", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "hunter", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "balance_druid", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("druid", "feral", "feral_druid", function(t)
    return TblMaxValIdx(t) == 2
        and Env.GetTalentRankOrdered(2, 1) < 3 -- https://www.wowhead.com/cata/spell=16929/thick-hide
end)
Env.AddSpec("druid", "feral_bear", "feral_tank_druid", function(t)
    return TblMaxValIdx(t) == 2
        and Env.GetTalentRankOrdered(2, 1) == 3 -- https://www.wowhead.com/cata/spell=16929/thick-hide
end)

Env.AddSpec("warlock", "affliction", "warlock", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", "warlock", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", "warlock", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("rogue", "assassination", "rogue", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", "rogue", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", "rogue", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", "mage", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", "mage", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", "mage", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", "warrior", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", "warrior", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warrior", "protection", "protection_warrior", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("paladin", "protection", "protection_paladin", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("paladin", "retribution", "retribution_paladin", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("priest", "shadow", "shadow_priest", function(t) return TblMaxValIdx(t) == 3 end)
Env.AddSpec("priest", "holy_disc", "healing_priest", function(t) return TblMaxValIdx(t) < 3 end)

Env.AddSpec("deathknight", "blood", "deathknight", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("deathknight", "frost", "deathknight", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("deathknight", "unholy", "deathknight", function(t) return TblMaxValIdx(t) == 3 end)
