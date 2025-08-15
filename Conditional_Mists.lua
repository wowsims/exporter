local Env = select(2, ...)
if not Env.IS_CLASSIC_MISTS then return end

Env.prelink = "https://wowsims.github.io/mop/"

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
    "monk",
}

local GetSpecialization = C_SpecializationInfo.GetSpecialization

Env.AddSpec("shaman", "elemental", "shaman/elemental", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("shaman", "enhancement", "shaman/enhancement", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("shaman", "restoration", "shaman/restoration", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("hunter", "beast_mastery", "hunter/beast_mastery", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("hunter", "marksman", "hunter/marksmanship", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("hunter", "survival", "hunter/survival", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("druid", "balance", "druid/balance", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("druid", "feral", "druid/feral", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("druid", "guardian", "druid/guardian", function(t) return GetSpecialization() == 3 end)
Env.AddSpec("druid", "restoration", "druid/restoration", function(t) return GetSpecialization() == 4 end)

Env.AddSpec("warlock", "affliction", "warlock/affliction", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("warlock", "demonology", "warlock/demonology", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("warlock", "destruction", "warlock/destruction", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("rogue", "assassination", "rogue/assassination", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("rogue", "combat", "rogue/combat", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("rogue", "subtlety", "rogue/subtlety", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("mage", "arcane", "mage/arcane", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("mage", "fire", "mage/fire", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("mage", "frost", "mage/frost", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("warrior", "arms", "warrior/arms", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("warrior", "fury", "warrior/fury", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("warrior", "protection", "warrior/protection", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("paladin", "holy", "paladin/holy", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("paladin", "protection", "paladin/protection", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("paladin", "retribution", "paladin/retribution", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("priest", "disc", "priest/discipline", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("priest", "holy", "priest/holy", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("priest", "shadow", "priest/shadow", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("deathknight", "blood", "death_knight/blood", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("deathknight", "frost", "death_knight/frost", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("deathknight", "unholy", "death_knight/unholy", function(t) return GetSpecialization() == 3 end)

Env.AddSpec("monk", "brewmaster", "monk/brewmaster", function(t) return GetSpecialization() == 1 end)
Env.AddSpec("monk", "mistweaver", "monk/mistweaver", function(t) return GetSpecialization() == 2 end)
Env.AddSpec("monk", "windwalker", "monk/windwalker", function(t) return GetSpecialization() == 3 end)

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end