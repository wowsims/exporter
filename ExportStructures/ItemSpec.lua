-- An ItemSpec is the data representation for an item used by the sim.
-- It differs between sim versions and cannot have unexpected entries.
-- Using this data structure will make sure that only allowed keys are set
-- based on the client version it runs on.
--
-- To use: Create with CreateItemSpec() instead of manually creating a table.
-- It can be used like any normal table, but it will throw errors if setting invalid keys,
-- i.e. keys that are not defined in protobufLayout, which adds the running flavor's itemFields to id and enchant.
--
-- ItemSpecMeta:FillFromItemLink(itemLink) fills everything the item link holds; flavors set the rest
-- (runes, reforges, upgrades) through their item hooks.

local Env = select(2, ...)

-- Protobuf layout used in the sim. Strings are types for some weak type checking (on key creation only!)
local protobufLayout = {
    id = "number",      -- int
    enchant = "number", -- int
}

for field, fieldType in pairs(Env.Flavor.itemFields) do
    protobufLayout[field] = fieldType
end

local ItemSpecMeta = { isItemSpec = true, _structure = protobufLayout }
ItemSpecMeta.__index = ItemSpecMeta

---Prevent adding keys not defined in the chosen layout or with wrong type.
---@param self table
---@param key any The key that is being added.
---@param value any The value that is being added.
function ItemSpecMeta.__newindex(self, key, value)
    assert(self._structure[key], "Tried adding an invalid key \"" .. key .. "\" to ItemSpec!")
    assert(value == nil or type(value) == self._structure[key],
        "Tried adding an invalid value type (" ..
        type(value) .. ") for key \"" .. key .. "\" to ItemSpec! Expected type: " .. self._structure[key])
    rawset(self, key, value)
end

---Fill values from an item link.
---@param itemLink string See https://wowpedia.fandom.com/wiki/ItemLink
function ItemSpecMeta:FillFromItemLink(itemLink)
    local _, itemId, enchantId, gemId1, gemId2, gemId3, gemId4, suffixId = strsplit(":", itemLink)

    self.id = tonumber(itemId)
    self.enchant = tonumber(enchantId)
    if self._structure.gems then
        self.gems = { tonumber(gemId1), tonumber(gemId2), tonumber(gemId3), tonumber(gemId4) }
        
        -- Loop over all filled gems and make sure to backwards fill empty (nil) gem slots with 0.
        for i = 1, #self.gems do
            if i > 1 and self.gems[i] and not self.gems[i - 1] then
                self.gems[i - 1] = 0
            end 
        end
    end
    if self._structure.random_suffix then
        self.random_suffix = tonumber(suffixId)
    end
    if Env.Flavor.FillFromItemLink then
        Env.Flavor.FillFromItemLink(self, itemLink)
    end
end

function ItemSpecMeta:GetEnchant()
    return self.enchant
end

function ItemSpecMeta:GetTinker()
    return self.tinker
end

function ItemSpecMeta:GetGems()
    return self.gems
end

function ItemSpecMeta:GetId()
    return self.id
end

---Create a new ItemSpec table.
local function CreateItemSpec()
    return setmetatable({}, ItemSpecMeta)
end

Env.CreateItemSpec = CreateItemSpec
