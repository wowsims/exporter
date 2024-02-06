-- A Character is the base table that gets exported and holds all neede data.

local Env = select(2, ...)

-- The metatable for a Character.
local CharacterMeta = {
    unit        = "",
    name        = "",
    realm       = "",
    race        = "",
    class       = "",
    level       = 0,
    talents     = "",
    professions = nil,
    spec        = "",
    gear        = nil,
    glyphs      = nil
}
CharacterMeta.__index = CharacterMeta

---Fill all data for unit.
-- TODO: This doesn't actually work for anything but "player"
---@param unit string Target unit. "player" or "target" for inspect (not implemented).
function CharacterMeta:SetUnit(unit)
    local name, realm = UnitFullName(unit)
    local _, englishClass, _, englishRace = GetPlayerInfoByGUID(UnitGUID(unit))

    self.unit = unit
    self.name = name
    self.realm = realm
    self.race = englishRace:gsub("Scourge", "Undead") -- hack? lol
    self.class = englishClass:lower()
    self.level = UnitLevel(unit)
    self.spec = Env.CheckCharacterSpec(self.class)
end

---Fill remaining data needed for export.
function CharacterMeta:FillForExport()
    assert(self.unit, "Unit was not yet set!")

    self.talents = Env.CreateTalentString()
    self.professions = Env.CreateProfessionEntry()

    local equipmentSet = Env.CreateEquipmentSpec()
    equipmentSet:UpdateEquippedItems(self.unit)
    self.gear = equipmentSet

    if not Env.IS_CLASSIC_ERA then
        self.glyphs = Env.CreateGlyphEntry()
    end
end

local function CreateCharacter()
    local character = setmetatable({}, CharacterMeta)
    return character
end

Env.CreateCharacter = CreateCharacter
