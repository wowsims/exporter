local Env = select(2, ...)

Env.IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Env.IS_CLASSIC_ERA_SOD = Env.IS_CLASSIC_ERA and C_Engraving.IsEngravingEnabled()
Env.IS_CLASSIC_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Env.IS_CLASSIC_CATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
Env.IS_CLASSIC_MISTS = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
Env.IS_CLASSIC_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
-- WoW Forever runs on the retail client. WOW_PROJECT_CAMELOT only exists there, and the nil check
-- keeps nil == nil from matching on clients that define neither.
Env.IS_FOREVER = WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
Env.IS_CLIENT_SUPPORTED = Env.IS_CLASSIC_ERA or Env.IS_CLASSIC_ERA_SOD or Env.IS_CLASSIC_TBC or Env.IS_CLASSIC_WRATH or Env.IS_CLASSIC_CATA or Env.IS_CLASSIC_MISTS or Env.IS_FOREVER

Env.VERSION = C_AddOns.GetAddOnMetadata(select(1, ...), "Version")
Env.AUTHORS = C_AddOns.GetAddOnMetadata(select(1, ...), "Author")

Env.supportedClientNames = {
    "Classic: Mists of Pandaria",
    "Classic: Cataclysm",
    "Classic: WotLK",
    "Classic: TBC",
    "Classic: SoD",
    "Classic: Era/Anniversary",
    "WoW Forever",
}

-- A flavor describes everything about one game version that the shared code needs. Each
-- Flavors/<Version>/Flavor.lua registers one with Env.RegisterFlavor, and the shared code reads it
-- from Env.Flavor instead of checking which client it runs on. Fields a flavor leaves out fall back
-- to these defaults; optional hooks default to nil and are skipped.
---@class Flavor
---@field name string Short name of the game version, exported as the character's flavor so a sim can tell where an export came from: era, sod, tbc, wrath, cata, mists or forever.
---@field prelink string Base URL of the sim, e.g. "https://www.wowsims.com/tbc/".
---@field classes string[] Lowercase class names the sim supports.
---@field itemFields table<string, string> ItemSpec fields the sim reads, besides id and enchant, with their Lua type.
---@field events string[] Events besides the common ones that mean the character changed.
---@field characterButtonPoint table SetPoint arguments for the character pane button; the relative frame by global name.
---@field supportsInspect boolean Whether inspected players can be exported.
---@field CreateTalentString fun(isInspect:boolean):string
---@field CountPointsPerTree (fun(unit:string):number[])|nil Points spent per talent tree, for AddSpec checks.
---@field GetSpecializationID (fun(unit:string):integer)|nil Used instead of CountPointsPerTree to match AddSpec spec IDs.
---@field CreateGlyphEntry (fun(isInspect:boolean):table)|nil
---@field GetProfessions (fun():table[])|nil Replaces reading professions from the skill lines.
---@field IsBagUpgradeCandidate (fun(itemLevel:number, itemRarity:number):boolean)|nil Extra bag export filter.
---@field FillFromItemLink (fun(itemSpec:table, itemLink:string))|nil Extra fields read from an item link.
---@field DecorateEquippedItem (fun(itemSpec:table, unit:string, slotId:integer))|nil
---@field DecorateBagItem (fun(itemSpec:table, bagId:integer, slotId:integer))|nil
---@field InferProfessions (fun(equipmentSpec:table):table[])|nil Guesses an inspected player's professions from gear.
local defaults = {
    name = "",
    prelink = "https://www.wowsims.com/",
    classes = {},
    itemFields = {},
    events = {},
    characterButtonPoint = { "TOPRIGHT", "CharacterFrame", "BOTTOMRIGHT", 0, 0 },
    supportsInspect = false,
    CreateTalentString = function() return "" end,
    CountPointsPerTree = function() return {} end,
}
local flavorMeta = { __index = defaults }

---@type Flavor
Env.Flavor = setmetatable({}, flavorMeta)

---Register the flavor for the running client.
---@param flavor Flavor
function Env.RegisterFlavor(flavor)
    Env.Flavor = setmetatable(flavor, flavorMeta)
end
