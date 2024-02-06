local Env = select(2, ...)

Env.VERSION = GetAddOnMetadata(select(1, ...), "Version")

Env.IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Env.IS_CLASSIC_ERA_SOD = Env.IS_CLASSIC_ERA and C_Engraving.IsEngravingEnabled()
Env.IS_CLASSIC_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Env.IS_CLIENT_SUPPORTED = Env.IS_CLASSIC_ERA_SOD or Env.IS_CLASSIC_WRATH

Env.supportedClientNames = {
    "Classic: WotLK",
    "Classic: SoD (Export may work for Era, but sim is made for SoD only!)",
}

-- This is needed because classic has no way to get Ids for professions.
-- GetSkillLineInfo() only returns localized values. GetSpellInfo() also does.
-- These spells are NOT the skill line, but have the same name in english,
-- So they should probably end up with the same translation.
-- engName is what the sim uses.
Env.professionNames = {
    [GetSpellInfo(2018)] = { skillLine = 164, engName = "Blacksmithing" },
    [GetSpellInfo(3104)] = { skillLine = 165, engName = "Leatherworking" },
    [GetSpellInfo(2259)] = { skillLine = 171, engName = "Alchemy" },
    [GetSpellInfo(9134)] = { skillLine = 182, engName = "Herbalism" },
    [GetSpellInfo(2575)] = { skillLine = 186, engName = "Mining" },
    [GetSpellInfo(3908)] = { skillLine = 197, engName = "Tailoring" },
    [GetSpellInfo(12656)] = { skillLine = 202, engName = "Engineering" },
    [GetSpellInfo(7412)] = { skillLine = 333, engName = "Enchanting" },
    [GetSpellInfo(8617)] = { skillLine = 393, engName = "Skinning" },
}

local statToStatId = {
    str = 1,
    strength = 1,
    agi = 2,
    agility = 2,
    stam = 3,
    stm = 3,
    stamina = 3,
    int = 4,
    intellect = 4,
    spi = 5,
    spirit = 5,
}

---Check if stat1 is bigger than stat2.
---Accepts short (agi) or full stat names (agility)
---@param stat1 string
---@param stat2 string
---@return boolean
function Env.StatBiggerThanStat(stat1, stat2)
    local statId1 = statToStatId[stat1:lower()]
    local statId2 = statToStatId[stat2:lower()]
    assert(statId1 and statId2, "Invalid stat identifiers provided!")
    return select(2, UnitStat("player", statId1)) > select(2, UnitStat("player", statId2))
end

---Get rune spell from an item in a slot, if item has a rune engraved.
---@param slotId integer
---@param bagId integer|nil If not nil check bag items instead of equipped items.
---@return integer|nil abilitySpellId The first spell id granted by the rune, or nil if no rune engraved.
function Env.GetEngravedRuneSpell(slotId, bagId)
    -- After first login the whole engraving stuff may not be loaded yet!
    -- GetNumRunesKnown will return 0 for maximum runes available in that case.
    if select(2, C_Engraving.GetNumRunesKnown()) == 0 then
        LoadAddOn("Blizzard_EngravingUI")
        C_Engraving.RefreshRunesList()
    end

    local runeData
    if bagId == nil then
        runeData = C_Engraving.GetRuneForEquipmentSlot(slotId)
    else
        runeData = C_Engraving.GetRuneForInventorySlot(bagId, slotId)
    end

    if runeData then
        return runeData.learnedAbilitySpellIDs[1]
    end
end

---Counts spent talent points per tree.
---@param isInspect boolean If true use inspect target.
---@return table pointsPerTreeTable { tree1Count, tree2Count, tree3Count }
local function CountSpentTalentsPerTree(isInspect)
    local trees = {}

    for tab = 1, GetNumTalentTabs(isInspect) do
        trees[tab] = 0
        for i = 1, GetNumTalents(tab, isInspect) do
            local _, _, _, _, currentRank = GetTalentInfo(tab, i, isInspect)
            trees[tab] = trees[tab] + currentRank
        end
    end

    return trees
end

local specializations = {}

---Try to find spec. Returns empty strings if spec could not be found.
---@param unit "player"|"target"
---@return string specName The name of the spec, e.g. "feral".
---@return string specUrl The URL part of the spec, e.g. "feral_druid"
function Env.GetSpec(unit)
    local playerClass = select(2, UnitClass(unit))

    if specializations[playerClass] then
        local spentTalentPoints = CountSpentTalentsPerTree(unit == "target")

        for _, specData in pairs(specializations[playerClass]) do
            if specData.isCurrentSpec(spentTalentPoints) then
                return specData.spec, specData.url
            end
        end
    end

    return "", ""
end

---Add spec to detection list.
---@param playerClass string
---@param spec string The name of the spec, e.g. "feral".
---@param url string The URL part of the spec, e.g. "feral_druid"
---@param checkFunc fun(spentTanlents:number[]):boolean
function Env.AddSpec(playerClass, spec, url, checkFunc)
    playerClass = playerClass:upper()
    specializations[playerClass] = specializations[playerClass] or {}
    table.insert(specializations[playerClass], {
        spec = spec,
        url = url,
        isCurrentSpec = checkFunc,
    })
end
