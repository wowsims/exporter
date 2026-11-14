-- Export options (Forever): choose what the window's exports include, and warn about
-- missing enchants and empty sockets when exporting yourself.
--
-- Data: WSEDB.global.exportOptions = { talents = true, gear = true, professions = true, warnMissing = true }

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local ExportOptions = {}

-- Slots that take an enchant in Forever. The off hand only counts for weapons and shields.
local enchantableSlots = {
    { slotId = INVSLOT_BACK, name = L["Back"] },
    { slotId = INVSLOT_CHEST, name = L["Chest"] },
    { slotId = INVSLOT_WRIST, name = L["Wrist"] },
    { slotId = INVSLOT_HAND, name = L["Hands"] },
    { slotId = INVSLOT_FEET, name = L["Feet"] },
    { slotId = INVSLOT_MAINHAND, name = L["Main Hand"] },
    { slotId = INVSLOT_OFFHAND, name = L["Off Hand"], weaponOrShieldOnly = true },
}
local enchantableOffHand = { INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true }

local function GetOptions()
    local options = Env.GetOrCreateTable(ExportOptions.db.global, "exportOptions")
    for _, key in ipairs({ "talents", "gear", "professions", "warnMissing" }) do
        if options[key] == nil then options[key] = true end
    end
    return options
end

---Equipped items missing an enchant or with empty gem sockets.
---@return table[] problems { slotId, slotName, link, noEnchant = bool, emptySockets = n }, in slot order.
function ExportOptions.FindProblems()
    local bySlot, order = {}, {}
    local function Get(slotId, link)
        if not bySlot[slotId] then
            bySlot[slotId] = { slotId = slotId, link = link, noEnchant = false, emptySockets = 0 }
            table.insert(order, slotId)
        end
        return bySlot[slotId]
    end

    for _, slot in ipairs(enchantableSlots) do
        local link = GetInventoryItemLink("player", slot.slotId)
        if link and (not slot.weaponOrShieldOnly or enchantableOffHand[Env.GetItemEquipLoc(link) or ""]) then
            local enchant = tonumber(link:match("item:%d+:(%-?%d*)") or "")
            if not enchant or enchant == 0 then
                local problem = Get(slot.slotId, link)
                problem.noEnchant = true
                problem.slotName = slot.name
            end
        end
    end

    local getStats = (C_Item and C_Item.GetItemStats) or GetItemStats
    for slotId = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
        local link = GetInventoryItemLink("player", slotId)
        local ok, stats = pcall(getStats, link or "")
        if link and ok and stats then
            local sockets = 0
            for key, count in pairs(stats) do
                if key:find("^EMPTY_SOCKET_") then sockets = sockets + count end
            end
            if sockets > 0 then
                local filled = 0
                local gems = { link:match("item:%d+:%-?%d*:(%-?%d*):(%-?%d*):(%-?%d*):(%-?%d*)") }
                for _, gem in ipairs(gems) do
                    if tonumber(gem) and tonumber(gem) > 0 then filled = filled + 1 end
                end
                local empty = math.max(0, sockets - filled)
                if empty > 0 then Get(slotId, link).emptySockets = empty end
            end
        end
    end

    table.sort(order)
    local problems = {}
    for _, slotId in ipairs(order) do table.insert(problems, bySlot[slotId]) end
    return problems
end

---Slots missing an enchant, and the number of empty sockets, on the player's gear.
---@return string[] missingEnchants Slot names.
---@return integer emptySockets
function ExportOptions.FindMissing()
    local missing, emptySockets = {}, 0
    for _, problem in ipairs(ExportOptions.FindProblems()) do
        if problem.noEnchant then table.insert(missing, problem.slotName) end
        emptySockets = emptySockets + problem.emptySockets
    end
    return missing, emptySockets
end

local function Before(character, isInspect)
    if not ExportOptions.db then return end
    local options = GetOptions()
    if not options.talents then character.talents = "" end
    if not options.gear then character.gear = Env.CreateEquipmentSpec() end
    if not options.professions then character.professions = {} end

    if not isInspect and options.warnMissing then
        local missing, emptySockets = ExportOptions.FindMissing()
        if #missing > 0 then
            Env.FeaturePrint(L["Missing enchants: %s"]:format(table.concat(missing, ", ")))
        end
        if emptySockets > 0 then
            Env.FeaturePrint(L["Empty gem sockets: %d"]:format(emptySockets))
        end
    end
end

local function CreateSettingsSection(container)
    local options = GetOptions()

    local label = AceGUI:Create("Label")
    label:SetText(L["Exports include:"])
    label:SetFullWidth(true)
    container:AddChild(label)

    local rows = {
        { key = "gear", label = L["Gear"] },
        { key = "talents", label = L["Talents"] },
        { key = "professions", label = L["Professions"] },
        { key = "warnMissing", label = L["Warn about missing enchants and empty sockets"] },
    }
    for _, row in ipairs(rows) do
        local checkBox = AceGUI:Create("CheckBox")
        checkBox:SetLabel(row.label)
        checkBox:SetWidth(row.key == "warnMissing" and 400 or 150)
        checkBox:SetValue(options[row.key])
        checkBox:SetCallback("OnValueChanged", function(_, _, value) options[row.key] = value end)
        container:AddChild(checkBox)
    end
end

function ExportOptions:Initialize(db)
    self.db = db
end

Env.AddExportHook({ Before = Before })
Env.AddSettingsSection(CreateSettingsSection)
Env.ExportOptions = ExportOptions
Env.RegisterFeature(ExportOptions)
