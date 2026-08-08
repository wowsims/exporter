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

Env.AddSpec("shaman", "elemental", "shaman/elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "shaman/enhancement", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("hunter", "beast_mastery", "hunter/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "hunter/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "hunter/dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "druid/balance", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("druid", "feral", "druid/feralcat", function(t) return TblMaxValIdx(t) == 2 end)

Env.AddSpec("warlock", "affliction", "warlock/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warlock", "demonology", "warlock/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warlock", "destruction", "warlock/dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("rogue", "assassination", "rogue/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("rogue", "combat", "rogue/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("rogue", "subtlety", "rogue/dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("mage", "arcane", "mage/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("mage", "fire", "mage/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("mage", "frost", "mage/dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("warrior", "arms", "warrior/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("warrior", "fury", "warrior/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("warrior", "protection", "warrior/protection", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("paladin", "protection", "paladin/protection", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("paladin", "retribution", "paladin/retribution", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("priest", "shadow", "priest/shadow", function(t) return TblMaxValIdx(t) == 3 end)
