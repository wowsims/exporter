local Env = select(2, ...)
if not Env.IS_CLASSIC_TBC then return end

Env.prelink = "https://www.wowsims.com/tbc/"

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

Env.AddSpec("shaman", "elemental", "elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "enhancement", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("hunter", "beast_mastery", "dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "balance", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("druid", "feral", "feralcat", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("warlock", "affliction", "dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", "dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", "dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("rogue", "assassination", "dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", "dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", "dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", "dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", "dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", "dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", "dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", "dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warrior", "protection", "protection", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("paladin", "protection", "protection", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("paladin", "retribution", "retribution", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("priest", "shadow", "shadow", function(t) return TblMaxValIdx(t) == 3 end)
