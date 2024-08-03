-- An EquipmentSpec is the data representation for items used by the sim.
--
-- A table created with CreateEquipmentSpec() will behave much like a normal table,
-- but it will throw errors if doing anything but setting an ItemSpec (see ItemSpec.lua)
-- or nil for numeric keys on the EquipmentSpec.items subtable.
--
-- The helper functions EquipmentSpecMeta:UpdateEquippedItems(unit) and
-- EquipmentSpecMeta:FillFromBagItems() can be used to fill items depending on context.
--
-- When editing EquipmentSpec.items manually ensure that items are at their correct postion.

local Env = select(2, ...)

-- Values are constants for slotIds.
local itemLayout = {
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_SHOULDER,
    INVSLOT_BACK,
    INVSLOT_CHEST,
    INVSLOT_WRIST,
    INVSLOT_HAND,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
    INVSLOT_RANGED,
    -- INVSLOT_AMMO, -- Not supported as item
}



-- Metatable for the base EquipmentSpec table.
local EquipmentSpecMeta = { isEquipmentSpec = true }
EquipmentSpecMeta.__index = EquipmentSpecMeta

---Prevent adding keys for the base table entirely.
---@param self table
---@param key any The key that is being added.
---@param value any The value that is being added.
function EquipmentSpecMeta.__newindex(self, key, value)
    error("Adding keys to EquipmentSpec base is not allowed!")
end

---Clear all items.
function EquipmentSpecMeta:Reset()
    wipe(self.items)
end

---Fill items with currently equipped items.
function EquipmentSpecMeta:UpdateEquippedItems(unit)
    self:Reset()
    for itemIndex, slotId in ipairs(itemLayout) do
        local itemLink = GetInventoryItemLink(unit, slotId)
        if itemLink then
            local itemSpec = Env.CreateItemSpec()
            itemSpec:FillFromItemLink(itemLink)
            if Env.IS_CLASSIC_ERA_SOD then itemSpec:SetRuneSpellFromSlot(slotId) end
            if Env.IS_CLASSIC_CATA then itemSpec:SetReforge(unit, slotId) end
            self.items[itemIndex] = itemSpec
        end
    end
end

---Fill items with items from bag. Valid items are filtered by
---the Env.TreatItemAsPossibleUpgrade(itemLink) function.
function EquipmentSpecMeta:FillFromBagItems()
    local GetContainerNumSlots = C_Container.GetContainerNumSlots
    local GetContainerItemLink = C_Container.GetContainerItemLink
    self:Reset()
    for bagId = 0, NUM_BAG_SLOTS do
        for slotId = 1, GetContainerNumSlots(bagId) do
            local itemLink = GetContainerItemLink(bagId, slotId)
            if itemLink and Env.TreatItemAsPossibleUpgrade(itemLink) then
                local itemSpec = Env.CreateItemSpec()
                itemSpec:FillFromItemLink(itemLink)
                if Env.IS_CLASSIC_ERA_SOD then itemSpec:SetRuneSpellFromSlot(slotId, bagId) end
                table.insert(self.items, itemSpec)
            end
        end
    end
end

-- Metatable for the EquipmentSpec.items table.
local EquipmentSpecItemsMeta = { isEquipmentSpecItems = true }
EquipmentSpecItemsMeta.__index = EquipmentSpecItemsMeta

---Prevent adding keys that are no valid item slot or no ItemSpec table.
---@param self table
---@param key any The key that is being added.
---@param value any The value that is being added.
function EquipmentSpecItemsMeta.__newindex(self, key, value)
    assert(type(key) == "number", "Can't add a non-numeric key " .. key .. " to EquipmentSpec.items!")
    assert(value == nil or value.isItemSpec, "Tried adding a non-ItemSpec value to EquipmentSpec.items!")
    rawset(self, key, value)
end

-- Create a new EquipmentSpec table.
local function CreateEquipmentSpec()
    local items = setmetatable({}, EquipmentSpecItemsMeta)
    local equipment = setmetatable({ items = items, version = Env.VERSION }, EquipmentSpecMeta)
    return equipment
end

Env.CreateEquipmentSpec = CreateEquipmentSpec
