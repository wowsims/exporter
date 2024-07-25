local Env = select(2, ...)

Env.VERSION = GetAddOnMetadata(select(1, ...), "Version")

Env.IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Env.IS_CLASSIC_ERA_SOD = Env.IS_CLASSIC_ERA and C_Engraving.IsEngravingEnabled()
Env.IS_CLASSIC_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Env.IS_CLASSIC_CATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
Env.IS_CLIENT_SUPPORTED = Env.IS_CLASSIC_ERA_SOD or Env.IS_CLASSIC_WRATH or Env.IS_CLASSIC_CATA

Env.supportedClientNames = {
    "Classic: Cataclysm",
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

---Determine if an item should be exported on bag item export.
-- TODO(Riotdog-GehennasEU): Is this sufficient? This seems to be what simc uses:
-- https://github.com/simulationcraft/simc-addon/blob/master/core.lua
-- Except we don't need the artifact check for wotlk classic.
---@param itemLink string See https://wowpedia.fandom.com/wiki/ItemLink
---@return boolean exportItem true if item should be exported
function Env.TreatItemAsPossibleUpgrade(itemLink)
    if not IsEquippableItem(itemLink) then return false end

    local itemInfo = { GetItemInfo(itemLink) }
    local itemRarity = itemInfo[3]
    local itemLevel = itemInfo[4]
    local itemClassId = itemInfo[12]

    if Env.IS_CLASSIC_ERA then
        local minIlvl = UnitLevel("player") - 15
        if itemLevel <= minIlvl
            or itemRarity < Enum.ItemQuality.Good then
            return false
        end
    elseif Env.IS_CLASSIC_WRATH or Env.IS_CLASSIC_CATA then
        -- Ignore TBC items like Rocket Boots Xtreme (Lite). The ilvl limit is intentionally set low
        -- to limit accidental filtering.
        if itemLevel <= 112
            or itemRarity < Enum.ItemQuality.Rare then
            return false
        end
    end

    -- Ignore ammunition.
    if itemClassId == Enum.ItemClass.Projectile then
        return false
    end

    return true
end

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

-- Some runes learn multiple spells, i.e. the learnedAbilitySpellIDs array of the
-- rune data returned by C_Engraving.GetRuneForEquipmentSlot and C_Engraving.GetRuneForInventorySlot
-- has multiple entries. The sim uses one of those Ids to indentify runes.
-- Map the first spell Id to the expected spell Id for runes that do not have it at position 1.
local runeSpellRemap = {
    [407993] = 407995, -- Mangle: The bear version is expected.
}

-- Ring Runes don't provide a Spell ID like other runes do. We have to convert the Enchant ID back to the Spell ID manually.
-- Ordered by spell name
local enchantmentIDToSpellID = {
    [7514] = 442893, -- Arcane Specialization
    [7508] = 442876, -- Axe Specialization
    [7510] = 442887, -- Dagger Specialization
    [7555] = 459312, -- Defense Specialization
    [7520] = 453622, -- Feral Combat Specialization
    [7515] = 442894, -- Fire Specialization
    [7511] = 442890, -- Fist Weapon Specialization
    [7516] = 442895, -- Frost Specialization
    [7519] = 442898, -- Holy Specialization
    [7509] = 442881, -- Mace Specialization
    [7517] = 442896, -- Nature Specialization
    [7513] = 442892, -- Pole Weapon Specialization
    [7512] = 442891, -- Ranged Weapon Specialization
    [7518] = 442897, -- Shadow Specialization
    [7507] = 442813, -- Sword Specialization
}

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
        local firstSpellId = runeData.learnedAbilitySpellIDs[1]
        if firstSpellId == nil then
            -- Fall back to re-mapping the enchant ID.
            -- Should only apply to ring specializations for now.
            return enchantmentIDToSpellID[runeData.itemEnchantmentID]
        else
            -- All non-ring runes should have a Spell ID
            if runeSpellRemap[firstSpellId] then
                return runeSpellRemap[firstSpellId]
            end
            return firstSpellId
        end
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
