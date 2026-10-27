-- A fake WoW client for the snapshot test (tools/test/snapshots.js), run under fengari.
--
-- FLAVOR (set before this file runs) picks the game version: era, sod, tbc, wrath, cata, mists or
-- forever. Each flavor only defines the APIs that client really has, so code that calls an API the
-- flavor lacks fails here instead of passing by accident. MOCK.class and MOCK.tree pick the character
-- (class token, and which talent tree / specialization holds most of its points).
--
-- MOCK.RunScenario(root, files) loads the addon's files in TOC order and returns the snapshot text.

MOCK = { class = "WARRIOR", tree = 1 }
local flavor = FLAVOR

local IS_CLASSIC = flavor ~= "forever"
local HAS_GLYPHS = flavor == "wrath" or flavor == "cata" or flavor == "mists"

local FLAVORS = {
    era = { project = "WOW_PROJECT_CLASSIC", level = 60, race = "Scourge" },
    sod = { project = "WOW_PROJECT_CLASSIC", level = 60, race = "Human" },
    tbc = { project = "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", level = 70, race = "BloodElf" },
    wrath = { project = "WOW_PROJECT_WRATH_CLASSIC", level = 80, race = "Dwarf" },
    cata = { project = "WOW_PROJECT_CATACLYSM_CLASSIC", level = 85, race = "Worgen" },
    mists = { project = "WOW_PROJECT_MISTS_CLASSIC", level = 90, race = "Pandaren" },
    forever = { project = "WOW_PROJECT_CAMELOT", level = 60, race = "NightElf" },
}
local info = assert(FLAVORS[flavor], "unknown flavor " .. tostring(flavor))

MOCK.classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
if flavor == "wrath" or flavor == "cata" or flavor == "mists" then
    table.insert(MOCK.classes, "DEATHKNIGHT")
end
if flavor == "mists" then
    table.insert(MOCK.classes, "MONK")
end

--------------------------------------------------------------------------------
-- Lua 5.1 / WoW globals
--------------------------------------------------------------------------------

function strsplit(delimiter, text)
    local parts = {}
    local start = 1
    while true do
        local s, e = string.find(text, delimiter, start, true)
        if not s then
            table.insert(parts, string.sub(text, start))
            break
        end
        table.insert(parts, string.sub(text, start, s - 1))
        start = e + 1
    end
    return table.unpack(parts)
end

function wipe(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

-- WoW runs Lua 5.1, where "%x" in a gsub replacement string is just "x" unless x is a digit or "%".
-- fengari implements Lua 5.3, which rejects it, so translate replacement strings to 5.1 behaviour.
local gsub = string.gsub
function string.gsub(text, pattern, replacement, n)
    if type(replacement) == "string" then
        replacement = gsub(replacement, "%%(.)", function(c)
            if c:match("[%d%%]") then return "%" .. c end
            return c
        end)
    end
    return gsub(text, pattern, replacement, n)
end

tinsert = table.insert
unpack = table.unpack
function time() return 1700000000 end
function date() return "2023-11-14 22:13:20" end

--------------------------------------------------------------------------------
-- Project and client constants
--------------------------------------------------------------------------------

WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_CLASSIC = 2
WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
WOW_PROJECT_WRATH_CLASSIC = 11
WOW_PROJECT_CATACLYSM_CLASSIC = 14
WOW_PROJECT_MISTS_CLASSIC = 19
if flavor == "forever" then
    WOW_PROJECT_CAMELOT = 18
end
WOW_PROJECT_ID = _G[info.project]

INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BODY, INVSLOT_CHEST = 1, 2, 3, 4, 5
INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST, INVSLOT_HAND = 6, 7, 8, 9, 10
INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1, INVSLOT_TRINKET2 = 11, 12, 13, 14
INVSLOT_BACK, INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED, INVSLOT_TABARD = 15, 16, 17, 18, 19
NUM_BAG_SLOTS = 4
MAX_NUM_TALENT_TIERS = 6

Enum = {
    ItemQuality = { Poor = 0, Common = 1, Good = 2, Rare = 3, Epic = 4 },
    ItemClass = { Weapon = 2, Armor = 4, Projectile = 6 },
    InventoryType = { IndexShoulderType = 3 },
}

ITEM_UPGRADE_TOOLTIP_FORMAT = "Upgrade Level: %d/%d"
ITEM_SPELL_TRIGGER_ONUSE = "Use:"
ITEM_COOLDOWN_TOTAL_MIN = "(%d Min Cooldown)"
ITEM_COOLDOWN_TOTAL_SEC = "(%d Sec Cooldown)"
ITEM_COOLDOWN_TOTAL = "(%s Cooldown)"
ITEM_SOCKET_BONUS = "Socket Bonus: %s"
ITEM_MOD_SPIRIT_SHORT = "Spirit"
ITEM_MOD_DODGE_RATING = "Increases your dodge rating by %s."
ITEM_MOD_PARRY_RATING = "Increases your parry rating by %s."
ITEM_MOD_HIT_RATING = "Improves hit rating by %s."
ITEM_MOD_CRIT_RATING = "Improves critical strike rating by %s."
ITEM_MOD_HASTE_RATING = "Improves haste rating by %s."
ITEM_MOD_EXPERTISE_RATING = "Increases your expertise rating by %s."
ITEM_MOD_MASTERY_RATING_SHORT = "Mastery"

UISpecialFrames = {}
WorldFrame = { name = "WorldFrame" }

C_AddOns = {
    GetAddOnMetadata = function(_, field)
        return field == "Version" and "test-version" or "test-authors"
    end,
}

C_EventUtils = {
    -- Forever's retail client lacks the classic talent point event.
    IsEventValid = function(event)
        return not (flavor == "forever" and event == "CHARACTER_POINTS_CHANGED")
    end,
}

C_Timer = {
    After = function() end,
    NewTimer = function() return { Cancel = function() end } end,
}

DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, message) table.insert(MOCK.prints, "chat: " .. message) end,
}

--------------------------------------------------------------------------------
-- Frames and tooltips
--------------------------------------------------------------------------------

MOCK.frames = {}

local function NewFrame(frameType, name, parent)
    local frame = { frameType = frameType, name = name, parent = parent, points = {}, scripts = {}, events = {} }
    function frame:SetPoint(point, relativeTo, relativePoint, x, y)
        table.insert(self.points, {
            point = point,
            relativeTo = type(relativeTo) == "table" and relativeTo.name or relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        })
    end
    function frame:SetScript(script, fn) self.scripts[script] = fn end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:GetFrameLevel() return 1 end
    function frame:GetTextWidth() return 50 end
    function frame:GetTextHeight() return 12 end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetText(text) self.text = text end
    setmetatable(frame, { __index = function() return function() end end })
    if name then _G[name] = frame end
    table.insert(MOCK.frames, frame)
    return frame
end

CharacterFrame = NewFrame("Frame", "CharacterFrame")
CharacterFrameTab5 = NewFrame("Button", "CharacterFrameTab5")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")

local function FontStrings(lines)
    local regions = {}
    for i, text in ipairs(lines) do
        regions[i] = {
            GetObjectType = function() return "FontString" end,
            GetText = function() return text end,
        }
    end
    return regions
end

local function NewTooltip(name)
    local tooltip = NewFrame("GameTooltip", name)
    tooltip.lines = {}
    function tooltip:ClearLines() self.lines = {} end
    function tooltip:SetHyperlink(link)
        local enchantID = link:match("^item:9333:(%d+)")
        self.lines = { "Hearthstone", "Binds when picked up" }
        if enchantID then
            table.insert(self.lines, "Enchant " .. enchantID)
        end
    end
    function tooltip:SetInventoryItem(unit, slot) self.lines = MOCK.InventoryTooltip(unit, slot) end
    function tooltip:SetBagItem(bag, slot) self.lines = MOCK.BagTooltip(bag, slot) end
    function tooltip:GetRegions() return table.unpack(FontStrings(self.lines)) end
    return tooltip
end

function CreateFrame(frameType, name, parent)
    if frameType == "GameTooltip" then
        return NewTooltip(name)
    end
    return NewFrame(frameType, name, parent)
end

function MOCK.FireFrameEvent(event)
    for _, frame in ipairs(MOCK.frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame, event)
        end
    end
end

--------------------------------------------------------------------------------
-- Units
--------------------------------------------------------------------------------

local CLASS_NAMES = {
    WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid",
    DEATHKNIGHT = "Death Knight", MONK = "Monk",
}

function UnitGUID(unit) return unit == "player" and "Player-1-00000001" or "Player-1-00000002" end
function UnitFullName(unit) return unit == "player" and "Tester" or "Inspected", "TestRealm" end
function UnitName(unit) return (UnitFullName(unit)) end
function GetRealmName() return "TestRealm" end
function UnitLevel() return info.level end
function GetMaxPlayerLevel() return info.level end
function UnitFactionGroup() return "Alliance", "Alliance" end
function UnitClass() return CLASS_NAMES[MOCK.class], MOCK.class end
function GetPlayerInfoByGUID()
    return CLASS_NAMES[MOCK.class], MOCK.class, info.race, info.race
end

function UnitStat(_, statID)
    local stats = { 100, 200, 300, MOCK.tree == 1 and 250 or 150, 120 }
    return stats[statID], stats[statID]
end

--------------------------------------------------------------------------------
-- Talents, specializations and glyphs
--------------------------------------------------------------------------------

local TALENTS_PER_TAB = { 30, 31, 32 }

local function TalentRank(tab, index)
    if tab == MOCK.tree then
        return (index * 7 + tab) % 4
    end
    return index % 5 == 0 and 1 or 0
end

if IS_CLASSIC then
    function GetNumTalentTabs() return 3 end
    function GetNumTalents(tab) return TALENTS_PER_TAB[tab] end
    -- Indexes run in reverse grid order, and one talent per tree is unavailable, so the addon's
    -- tier/column ordering is exercised.
    function GetTalentInfo(tab, index)
        local count = TALENTS_PER_TAB[tab]
        local position = count - index
        local tier = math.floor(position / 4) + 1
        local column = position % 4 + 1
        local available = index ~= 5
        local rank = available and TalentRank(tab, index) or 0
        return "Talent " .. tab .. "-" .. index, 0, tier, column, rank, 5, false, available
    end
end

local MISTS_SPEC_IDS = {
    WARRIOR = { 71, 72, 73 }, PALADIN = { 65, 66, 70 }, HUNTER = { 253, 254, 255 },
    ROGUE = { 259, 260, 261 }, PRIEST = { 256, 257, 258 }, SHAMAN = { 262, 263, 264 },
    MAGE = { 62, 63, 64 }, WARLOCK = { 265, 266, 267 }, DRUID = { 102, 103, 104, 105 },
    DEATHKNIGHT = { 250, 251, 252 }, MONK = { 268, 270, 269 },
}

-- How many talent trees, or MoP specializations, the spec matrix tries for a class.
function MOCK.SpecCount(class)
    if flavor == "mists" then return #MISTS_SPEC_IDS[class] end
    return 3
end

if flavor == "cata" or flavor == "mists" or flavor == "forever" then
    C_SpecializationInfo = { GetActiveSpecGroup = function() return 1 end }
end

if flavor == "mists" then
    C_SpecializationInfo.GetSpecialization = function() return MOCK.tree end
    C_SpecializationInfo.GetSpecializationInfo = function(index) return MISTS_SPEC_IDS[MOCK.class][index] end
    C_SpecializationInfo.GetTalentInfo = function(query)
        return { selected = query.column == (query.tier + MOCK.tree) % 3 + 1 }
    end
    function GetInspectSpecialization() return MISTS_SPEC_IDS[MOCK.class][MOCK.tree] end
end

if HAS_GLYPHS then
    function GetNumGlyphSockets() return flavor == "cata" and 9 or 6 end
    if flavor == "wrath" then
        function GetGlyphSocketInfo(socket)
            return true, socket % 2 == 1 and 1 or 2, 50000 + socket
        end
    else
        function GetGlyphSocketInfo(socket)
            return true, (socket - 1) % 3 + 1, socket, 60000 + socket
        end
    end
end

-- Forever: the first talent of each tree per class, as TraitDefinition IDs. snapshots.js reads them
-- from the generated table in Flavors/Forever/Talents.lua, so the Forever snapshot doesn't change
-- when the daily sync regenerates that table.
local FOREVER_FIRST_TALENTS = FOREVER_FIRST_TALENTS
if flavor == "forever" then
    assert(FOREVER_FIRST_TALENTS, "snapshots.js must set FOREVER_FIRST_TALENTS")
end

if flavor == "forever" then
    local function Nodes()
        local nodes = {}
        for tree, definitionID in ipairs(FOREVER_FIRST_TALENTS[MOCK.class]) do
            table.insert(nodes, { definitionID = definitionID, rank = tree == MOCK.tree and 5 or 2 })
        end
        table.insert(nodes, { definitionID = 999999, rank = 3 }) -- not in any sim tree
        table.insert(nodes, { definitionID = FOREVER_FIRST_TALENTS[MOCK.class][1] + 1, rank = 0 })
        return nodes
    end
    C_SpecializationInfo.GetCombatConfigIDForSpecGroup = function() return 7 end
    C_Traits = {
        GetConfigInfo = function() return { treeIDs = { 1 } } end,
        GetTreeNodes = function()
            local ids = {}
            for i = 1, #Nodes() do ids[i] = i end
            return ids
        end,
        GetNodeInfo = function(_, nodeID)
            local node = Nodes()[nodeID]
            return { ranksPurchased = node.rank, currentRank = node.rank, activeEntry = { entryID = nodeID } }
        end,
        GetEntryInfo = function(_, entryID) return { definitionID = Nodes()[entryID].definitionID } end,
    }
end

--------------------------------------------------------------------------------
-- Professions
--------------------------------------------------------------------------------

local SKILL_LINE_NAMES = {
    [164] = "Blacksmithing", [165] = "Leatherworking", [171] = "Alchemy", [182] = "Herbalism",
    [186] = "Mining", [197] = "Tailoring", [202] = "Engineering", [333] = "Enchanting",
    [393] = "Skinning", [755] = "Jewelcrafting", [773] = "Inscription",
}

C_TradeSkillUI = {
    -- Wrath's client has no display name for Jewelcrafting and Inscription; the addon adds them itself.
    GetTradeSkillDisplayName = function(skillLine)
        if flavor == "wrath" and (skillLine == 755 or skillLine == 773) then return nil end
        return SKILL_LINE_NAMES[skillLine]
    end,
}

if IS_CLASSIC then
    local SKILL_LINES = {
        { "Professions", true, true, 0 },
        { flavor == "wrath" and "Jewelcrafting" or "Blacksmithing", false, true, 300 },
        { "Mining", false, true, 275 },
        { "Swords", false, true, 300 },
    }
    function GetNumSkillLines() return #SKILL_LINES end
    function GetSkillLineInfo(index) return table.unpack(SKILL_LINES[index]) end
    function GetSpellInfo(spellID)
        local names = { [25229] = "Jewelcrafting", [45357] = "Inscription" }
        return names[spellID]
    end
else
    function GetProfessions() return 1, 2, nil, 4, 5 end
    function GetProfessionInfo(index)
        local professions = {
            [1] = { "Enchanting", 0, 290, 300, 0, 0, 333 },
            [2] = { "Herbalism", 0, 300, 300, 0, 0, 182 },
        }
        return table.unpack(professions[index])
    end
end

--------------------------------------------------------------------------------
-- Items
--------------------------------------------------------------------------------

-- Link fields after "item:": id, enchant, gem1-4, suffix, unique, linkLevel, then the field the addon
-- reads as the reforge ID (the 11th part of strsplit(":", link)), and a few more.
local function ItemLink(id, enchant, gems, suffix, reforge)
    return ("|cffa335ee|Hitem:%d:%s:%s:%s:%s:%s:%s:0:%d:%s:0:1:0|h[Item %d]|h|r"):format(
        id, enchant or "", gems[1] or "", gems[2] or "", gems[3] or "", gems[4] or "",
        suffix or "", info.level, reforge or "", id)
end

-- The inspected player's gear has a ring enchant (Enchanting) and a leg enchant (Leatherworking).
-- MOCK.inspectVariant changes it: "gaps" empties the head and first ring slots, drops the leg
-- enchant and adds a Jewelcrafting-only gem; "conflict" only adds the gem, for three professions.
local INSPECT_ENCHANTS = { [INVSLOT_FINGER1] = 4359, [INVSLOT_LEGS] = 4880 }

function GetInventoryItemLink(unit, slot)
    if slot == INVSLOT_RANGED or slot == INVSLOT_BODY or slot == INVSLOT_TABARD then
        return nil
    end
    local inspected = unit ~= "player"
    local variant = inspected and MOCK.inspectVariant
    if variant == "gaps" and (slot == INVSLOT_HEAD or slot == INVSLOT_FINGER1) then
        return nil
    end
    local base = inspected and 5000 or 1000
    local enchant = slot % 3 == 0 and tostring(2000 + slot) or nil
    if inspected and INSPECT_ENCHANTS[slot] and not (variant == "gaps" and slot == INVSLOT_LEGS) then
        enchant = tostring(INSPECT_ENCHANTS[slot])
    end
    local gems = slot % 4 == 0 and { "3001", nil, "3003" } or {}
    if variant and slot == INVSLOT_NECK then
        gems = { "83141" }
    end
    local suffix = slot % 5 == 0 and tostring(-slot) or nil
    local reforge = slot % 2 == 0 and tostring(113 + slot) or nil
    return ItemLink(base + slot, enchant, gems, suffix, reforge)
end

-- Cata reforge: the chest has 100 Spirit and 50 crit by default, and 40 of the Spirit moved to hit.
function GetItemStats(link)
    if link:find("item:1005:") then
        return { ITEM_MOD_SPIRIT_SHORT = 100, ITEM_MOD_CRIT_RATING = 50 }
    end
    return {}
end

function MOCK.InventoryTooltip(unit, slot)
    local lines = { "Item " .. slot }
    if flavor == "cata" and unit == "player" and slot == INVSLOT_CHEST then
        table.insert(lines, "+60 Spirit")
        table.insert(lines, "Improves critical strike rating by 50.")
        table.insert(lines, "Improves hit rating by 40.")
    end
    if flavor == "mists" and slot % 3 == 1 then
        table.insert(lines, "Upgrade Level: 1/2")
    end
    if flavor == "mists" and unit == "player" and slot == INVSLOT_HAND then
        table.insert(lines, "Use: Increases your Intellect by 1,920 for 10 sec. (1 Min Cooldown)")
    end
    return lines
end

function MOCK.BagTooltip()
    return { "Shoulder rune item", "Enchant 7670" }
end

-- Bag 0 holds one of each case the bag export filters on.
local BAG_ITEMS = {
    { id = 7001, rarity = 3, ilvl = 120, class = 4 },
    { id = 7002, rarity = 1, ilvl = 200, class = 4 },
    { id = 7003, rarity = 4, ilvl = 200, class = 6 },
    { id = 7004, rarity = 4, ilvl = 200, class = 4, notEquippable = true },
    { id = 7005, rarity = 4, ilvl = 60, class = 4, shoulder = true },
    { id = 7006, rarity = 3, ilvl = 100, class = 4 },
    { id = 7007, uncached = true },
}

local function BagItemByLink(link)
    local id = tonumber(link:match("item:(%d+)"))
    for _, item in ipairs(BAG_ITEMS) do
        if item.id == id then return item end
    end
end

C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and #BAG_ITEMS or 0 end,
    GetContainerItemLink = function(bag, slot)
        local item = BAG_ITEMS[slot]
        return item and ItemLink(item.id, slot == 1 and "2500" or nil, {}, nil, nil)
    end,
}

local function ItemInfo(link)
    local item = BagItemByLink(link)
    if not item or item.uncached then return nil end
    return "Item " .. item.id, link, item.rarity, item.ilvl, 1, "Armor", "Misc", 1, "INVTYPE_CHEST", 0, 0, item.class
end

local function IsEquippable(link)
    local item = BagItemByLink(link)
    return not (item and item.notEquippable)
end

C_Item = {
    RequestLoadItemDataByID = function() end,
    GetItemNumSockets = function() return 1 end,
    GetItemInventoryType = function(location)
        local item = BAG_ITEMS[location.slot]
        return item and item.shoulder and Enum.InventoryType.IndexShoulderType or 5
    end,
}
if IS_CLASSIC then
    GetItemInfo = ItemInfo
    IsEquippableItem = IsEquippable
else
    C_Item.GetItemInfo = ItemInfo
    C_Item.IsEquippableItem = IsEquippable
end

ItemLocation = {
    CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end,
}

--------------------------------------------------------------------------------
-- Season of Discovery runes
--------------------------------------------------------------------------------

if flavor == "era" or flavor == "sod" then
    C_Engraving = {
        IsEngravingEnabled = function() return flavor == "sod" end,
        GetNumRunesKnown = function() return 12, 40 end,
        RefreshRunesList = function() end,
        GetRuneForEquipmentSlot = function(slot)
            local runes = {
                [INVSLOT_CHEST] = { learnedAbilitySpellIDs = { 401000 } },
                [INVSLOT_LEGS] = { learnedAbilitySpellIDs = { 407993 } },
                [INVSLOT_HAND] = { learnedAbilitySpellIDs = { MOCK.tree == 3 and 403789 or 403000 } },
                [INVSLOT_FINGER1] = { learnedAbilitySpellIDs = {}, itemEnchantmentID = 7514 },
            }
            return runes[slot]
        end,
        GetRuneForInventorySlot = function(_, slot)
            if slot == 1 then return { learnedAbilitySpellIDs = { 407993 } } end
        end,
    }
    function FindSpellOverrideByID(spellID) return spellID == 1219955 and 1219962 or spellID end
    function LoadAddOn() end
end

--------------------------------------------------------------------------------
-- Libraries
--------------------------------------------------------------------------------

local function Serialize(value, indent)
    indent = indent or ""
    local valueType = type(value)
    if valueType == "string" then
        return ("%q"):format(value)
    elseif valueType == "number" then
        return ("%.14g"):format(value)
    elseif valueType ~= "table" then
        return tostring(value)
    end

    local keys = {}
    for key in pairs(value) do table.insert(keys, key) end
    if #keys == 0 then return "{}" end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)

    local isArray = #keys == #value
    local inner = indent .. "  "
    local lines = {}
    for _, key in ipairs(keys) do
        local prefix = isArray and "" or (type(key) == "string" and ("%q: "):format(key) or ("[%s]: "):format(key))
        table.insert(lines, inner .. prefix .. Serialize(value[key], inner))
    end
    local open, close = isArray and "[" or "{", isArray and "]" or "}"
    return open .. "\n" .. table.concat(lines, ",\n") .. "\n" .. indent .. close
end
MOCK.Serialize = Serialize

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = DeepCopy(v) end
    return copy
end

MOCK.prints = {}
MOCK.addons = {}

local function NewAddon(_, name)
    local addon = { name = name, events = {}, hooks = {}, commands = {}, comms = {} }
    function addon:RegisterChatCommand(command) table.insert(self.commands, command) end
    function addon:RegisterEvent(event, handler) self.events[event] = handler end
    function addon:UnregisterEvent(event) self.events[event] = nil end
    function addon:Print(message) table.insert(MOCK.prints, message) end
    function addon:SecureHook(target, handler) self.hooks[target] = handler end
    function addon:Unhook(target) self.hooks[target] = nil end
    function addon:RegisterComm(prefix) table.insert(self.comms, prefix) end
    function addon:SendCommMessage(prefix, text, channel, target)
        table.insert(MOCK.prints, ("comm: %s %s %s %s"):format(prefix, text, channel, tostring(target)))
    end
    MOCK.addons[name] = addon
    return addon
end

local LIBRARIES = {
    ["LibParse"] = { JSONEncode = function(_, value) return Serialize(value) end },
    ["AceAddon-3.0"] = { NewAddon = NewAddon },
    ["AceGUI-3.0"] = {},
    ["AceDB-3.0"] = { New = function(_, _, defaults) return { profile = DeepCopy(defaults.profile) } end },
    ["AceDBOptions-3.0"] = { GetOptionsTable = function() return {} end },
    ["AceConfig-3.0"] = { RegisterOptionsTable = function() end },
    ["AceConfigDialog-3.0"] = {
        AddToBlizOptions = function() return { name = "WowSimsExporter" }, "WowSimsExporter" end,
    },
}

function LibStub(name) return assert(LIBRARIES[name], "no mock for library " .. name) end

--------------------------------------------------------------------------------
-- Scenario
--------------------------------------------------------------------------------

local REPRESENTATIVE_CLASS = {
    era = "DRUID", sod = "WARLOCK", tbc = "PALADIN", wrath = "DEATHKNIGHT",
    cata = "DRUID", mists = "MONK", forever = "MAGE",
}

local function SortedKeys(t)
    local keys = {}
    for key in pairs(t) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

function MOCK.RunScenario(root, files)
    local Env = {}
    local window = {}

    for _, file in ipairs(files) do
        local chunk = assert(loadfile(root .. "/" .. file))
        chunk("WowSimsExporter", Env)

        if file == "UI.lua" then
            -- Capture what the addon would show instead of building AceGUI windows.
            local UI = Env.UI
            UI.CreateMainWindow = function(_, classIsSupported, link)
                window.classIsSupported = classIsSupported
                window.link = link
            end
            UI.SetOutput = function(_, output) window.output = output end
            UI.SetOutputGenerator = function(_, generator) MOCK.generator = generator end
            UI.SetOutputGeneratorBags = function(_, generator) MOCK.bagGenerator = generator end
            UI.CreateInspectButton = function() end
        end
    end

    MOCK.FireFrameEvent("SPELLS_CHANGED")

    local addon = MOCK.addons.WowSimsExporter
    addon:OnInitialize()
    local enteringWorld = addon.events.PLAYER_ENTERING_WORLD
    enteringWorld("PLAYER_ENTERING_WORLD", true, false)

    local sections = {}
    local function Section(title, body)
        table.insert(sections, "## " .. title .. "\n" .. body)
    end

    local events = {}
    for _, event in ipairs(SortedKeys(addon.events)) do
        if event ~= "PLAYER_ENTERING_WORLD" then table.insert(events, event) end
    end
    Section("Events", Serialize(events))
    Section("Hooks", Serialize(SortedKeys(addon.hooks)))
    Section("Comms", Serialize(addon.comms))
    Section("Chat commands", Serialize(addon.commands))
    Section("Character pane button", Serialize(WSECharacterFrameButton.points))

    MOCK.class, MOCK.tree = REPRESENTATIVE_CLASS[flavor], 2
    addon:CreateWindow(true, false)
    Section("Export: " .. MOCK.class .. " tree 2", Serialize({
        classIsSupported = window.classIsSupported,
        link = window.link,
    }) .. "\n" .. window.output)

    Section("Bag export", MOCK.bagGenerator())

    if addon.hooks.InspectUnit then
        window.output = nil
        addon.hooks.InspectUnit("target")
        addon:CreateWindow(true, true)
        Section("Inspect export: " .. MOCK.class .. " tree 2", window.output)

        for _, variant in ipairs({ "gaps", "conflict" }) do
            MOCK.inspectVariant = variant
            window.output = nil
            addon:CreateWindow(true, true)
            Section("Inspect export (" .. variant .. "): " .. MOCK.class .. " tree 2", window.output)
        end
        MOCK.inspectVariant = nil
    end

    local matrix = {}
    for _, class in ipairs(MOCK.classes) do
        for tree = 1, MOCK.SpecCount(class) do
            MOCK.class, MOCK.tree = class, tree
            addon:CreateWindow(false, false)
            local character = Env.CreateCharacter()
            character:SetUnit("player")
            table.insert(matrix, ("%s %d: supported=%s spec=%s link=%s"):format(
                class, tree, tostring(window.classIsSupported), character.spec, window.link))
        end
    end
    Section("Spec matrix", table.concat(matrix, "\n"))

    Section("Prints", table.concat(MOCK.prints, "\n"))

    return table.concat(sections, "\n\n") .. "\n"
end
