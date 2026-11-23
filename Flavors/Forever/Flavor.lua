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
    cnPrelink = "https://wowsimscn.com/",
    simLayout = "class_role",
    -- The sim's pages, from ui/specs/<class>/<spec>/spec.ts in wowsims/forever.
    simPages = {
        ["druid/balance"] = true,
        ["druid/feralbear"] = true,
        ["druid/feralcat"] = true,
        ["druid/restoration"] = true,
        ["hunter/dps"] = true,
        ["mage/dps"] = true,
        ["paladin/holy"] = true,
        ["paladin/protection"] = true,
        ["paladin/retribution"] = true,
        ["priest/dps"] = true,
        ["priest/healer"] = true,
        ["rogue/dps"] = true,
        ["shaman/elemental"] = true,
        ["shaman/enhancement"] = true,
        ["shaman/restoration"] = true,
        ["warlock/dps"] = true,
        ["warrior/dps"] = true,
        ["warrior/protection"] = true,
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

Env.AddSpec("shaman", "elemental", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("shaman", "enhancement", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("shaman", "restoration", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("hunter", "beast_mastery", function(t) return TblMaxValIdx(t) == 1 end)
Env.AddSpec("hunter", "marksman", function(t) return TblMaxValIdx(t) == 2 end)
Env.AddSpec("hunter", "survival", function(t) return TblMaxValIdx(t) == 3 end)

Env.AddSpec("druid", "balance", function(t) return TblMaxValIdx(t) == 1 end)
-- The sim's bear preset takes Thick Hide and skips Shredding Attacks; its cat and hybrid presets
-- take Shredding Attacks, so hybrids link the cat sim.
local THICK_HIDE, SHREDDING_ATTACKS = 134403, 134406 -- TraitDefinition IDs
Env.AddSpec("druid", "feral_bear", function(t)
    local ranks = Env.GetForeverTalentRanks()
    return TblMaxValIdx(t) == 2
        and ranks ~= nil
        and (ranks[THICK_HIDE] or 0) > 0
        and (ranks[SHREDDING_ATTACKS] or 0) == 0
end)
Env.AddSpec("druid", "feral", function(t) return TblMaxValIdx(t) == 2 end)
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
Env.AddSpec("priest", "holy_disc", function(t) return TblMaxValIdx(t) < 3 end)
