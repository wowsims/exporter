-- A Character is the base table that gets exported and holds all needed data.

local Env = select(2, ...)

-- The metatable for a Character.
local CharacterMeta = {
    version     = "",
    unit        = "",
    name        = "",
    realm       = "",
    race        = "",
    class       = "",
    level       = 0,
    talents     = "",
    professions = {},
    spec        = "",
    gear        = {},
    glyphs      = {},
}
CharacterMeta.__index = CharacterMeta

local function getRace(unit, englishRace)
    if englishRace == "Pandaren" then
        local englishFaction, _ = UnitFactionGroup(unit)
        return englishRace.." ("..englishFaction:sub(1,1)..")"
    end
    return englishRace:gsub("Scourge", "Undead") -- hack? lol
end

---Prevent adding keys that are not defined in the metatable.
---@param self table
---@param key any The key that is being added.
---@param value any The value that is being added.
function CharacterMeta.__newindex(self, key, value)
    assert(self[key], "Tried to add invalid key to Character!")
    rawset(self, key, value)
end

---Fill all data for unit.
---@param unit "player"|"target" Target unit. "target" would need to be inspect target.
function CharacterMeta:SetUnit(unit)
    local name, realm = UnitFullName(unit)
    local _, englishClass, _, englishRace = GetPlayerInfoByGUID(UnitGUID(unit))

    self.version = Env.VERSION
    self.unit = unit
    self.name = name
    self.realm = realm
    self.race = getRace(unit, englishRace)
    self.class = englishClass:lower()
    self.level = UnitLevel(unit)
    self.spec = Env.GetSpec(unit)
end

---Fill remaining data needed for export.
function CharacterMeta:FillForExport(isInspect)
    assert(self.unit, "Unit was not yet set!")
    if Env.IS_CLASSIC_MISTS then
        self.talents = Env.CreateMistsTalentString(isInspect)
    else
        self.talents = Env.CreateTalentString()
    end
    self.professions = Env.CreateProfessionEntry(isInspect)

    local equipmentSet = Env.CreateEquipmentSpec()
    equipmentSet:UpdateEquippedItems(self.unit)
    self.gear = equipmentSet

    if not Env.IS_CLASSIC_ERA then
        self.glyphs = Env.CreateGlyphEntry(isInspect)
    end
end

local function CreateCharacter()
    local character = setmetatable({}, CharacterMeta)
    return character
end

Env.CreateCharacter = CreateCharacter
