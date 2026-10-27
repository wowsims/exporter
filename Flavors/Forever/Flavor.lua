local Env = select(2, ...)
if not Env.IS_FOREVER then return end

-- The retail client has no skill line list, only the profession API.
local function GetProfessionsFromProfessionAPI()
    local professions = {}
    local prof1, prof2 = GetProfessions()
    for _, index in pairs({ prof1, prof2 }) do
        local _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(index)
        local engName = Env.professionEngNameBySkillLine[skillLine]
        if engName then
            table.insert(professions, {
                name = engName,
                level = skillLevel,
            })
        end
    end
    return professions
end

Env.RegisterFlavor({
    name = "forever",
    prelink = "https://www.wowsims.com/forever/",
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
    },
    events = { "TRAIT_CONFIG_UPDATED", "ACTIVE_COMBAT_CONFIG_CHANGED" },
    CreateTalentString = Env.CreateForeverTalentString,
    CountPointsPerTree = Env.CountForeverPointsPerTree,
    GetProfessions = GetProfessionsFromProfessionAPI,
    IsBagUpgradeCandidate = Env.IsBagUpgradeNearPlayerLevel,
})

local TblMaxValIdx = Env.TableMaxValIndex

Env.AddSpec("shaman", "elemental", "shaman/elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", "shaman/enhancement", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("shaman", "restoration", "shaman/restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("hunter", "beast_mastery", "hunter/dps", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", "hunter/dps", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", "hunter/dps", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", "druid/balance", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("druid", "feral", "druid/feralcat", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("druid", "restoration", "druid/restoration", function(t) return TblMaxValIdx(t) == 3 end)

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

Env.AddSpec("paladin", "holy", "paladin/holy", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("paladin", "protection", "paladin/protection", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("paladin", "retribution", "paladin/retribution", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("priest", "shadow", "priest/dps", function(t) return TblMaxValIdx(t) == 3 end)
Env.AddSpec("priest", "holy_disc", "priest/healer", function(t) return TblMaxValIdx(t) < 3 end)
