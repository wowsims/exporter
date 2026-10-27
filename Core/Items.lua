local Env = select(2, ...)

-- The retail client (WoW Forever) only has the C_Item versions of these.
local GetItemInfo = GetItemInfo or C_Item.GetItemInfo
local IsEquippableItem = IsEquippableItem or C_Item.IsEquippableItem

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

    -- Item data isn't cached yet.
    if not itemLevel then return false end

    local IsBagUpgradeCandidate = Env.Flavor.IsBagUpgradeCandidate
    if IsBagUpgradeCandidate and not IsBagUpgradeCandidate(itemLevel, itemRarity) then
        return false
    end

    -- Ignore ammunition.
    if itemClassId == Enum.ItemClass.Projectile then
        return false
    end

    return true
end

---Bag export filter for leveling flavors: skip items far below the player's level and below Good quality.
---@param itemLevel number
---@param itemRarity number
---@return boolean
function Env.IsBagUpgradeNearPlayerLevel(itemLevel, itemRarity)
    local minIlvl = UnitLevel("player") - 15
    return itemLevel > minIlvl and itemRarity >= Enum.ItemQuality.Good
end

---Bag export filter for Wrath and Cataclysm: skip TBC items like Rocket Boots Xtreme (Lite) and
---anything below Rare. The ilvl limit is intentionally set low to limit accidental filtering.
---@param itemLevel number
---@param itemRarity number
---@return boolean
function Env.IsBagUpgradeAboveTBC(itemLevel, itemRarity)
    return itemLevel > 112 and itemRarity >= Enum.ItemQuality.Rare
end
