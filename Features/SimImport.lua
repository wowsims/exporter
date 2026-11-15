-- Import tab (Forever): bring gear and talents from the sim back into the game.
-- Accepts:
-- - the sim's JSON export (Export > JSON): player.equipment.items and player.talentsString,
-- - the sim's saved-data text ("wowsims-saved:v1:..."), gear sets or talent builds,
-- - this addon's own export.
-- Also sends all gear sets to the sim as one saved-data text (Env.ExportGearSetBundle).

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local SimImport = {}

-- The sim's Spec enum names (proto/common.proto in wowsims/forever) by class and the addon's spec.
local specEnumNames = {
    druid = { balance = "SpecBalanceDruid", feral = "SpecFeralCatDruid", feral_bear = "SpecFeralBearDruid",
        restoration = "SpecRestorationDruid" },
    hunter = "SpecHunter",
    mage = "SpecMage",
    paladin = { holy = "SpecHolyPaladin", protection = "SpecProtectionPaladin",
        retribution = "SpecRetributionPaladin" },
    priest = { shadow = "SpecDpsPriest", holy_disc = "SpecHealerPriest" },
    rogue = "SpecRogue",
    shaman = { elemental = "SpecElementalShaman", enhancement = "SpecEnhancementShaman",
        restoration = "SpecRestorationShaman" },
    warlock = "SpecWarlock",
    warrior = { protection = "SpecProtectionWarrior", arms = "SpecDpsWarrior", fury = "SpecDpsWarrior" },
}

---The sim's Spec enum name for the player.
---@return string|nil
local function PlayerSpecEnumName()
    local _, classFile = UnitClass("player")
    local byClass = specEnumNames[classFile:lower()]
    if type(byClass) == "string" then return byClass end
    if not byClass then return nil end
    local spec = Env.GetSpec("player")
    return byClass[spec]
end

-- What was last read from a paste, kept while the tab is rebuilt.
-- { kind = "gear"|"talents"|"sets", name, items = { [itemIndex] = { id, enchant } }, talents, entries }
local loaded

--------------------------------------------------------------------------------
-- Reading pastes
--------------------------------------------------------------------------------

---Items from an EquipmentSpec JSON object, by item index (1 = head ... 17 = ranged).
local function ReadItems(equipment)
    local items = {}
    for index, item in pairs(equipment and equipment.items or {}) do
        if type(item) == "table" and tonumber(item.id) and tonumber(item.id) > 0 then
            local gems = {}
            for _, gem in pairs(type(item.gems) == "table" and item.gems or {}) do
                if tonumber(gem) and tonumber(gem) > 0 then table.insert(gems, tonumber(gem)) end
            end
            items[index] = { id = tonumber(item.id), enchant = tonumber(item.enchant), gems = gems }
        end
    end
    return items
end

local classFiles = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

---Class of a build from the sim's names: "ClassMage", "SpecBalanceDruid", "mage" -> "MAGE".
---@param value any
---@return string|nil classFile
local function ClassFileFrom(value)
    if type(value) ~= "string" then return nil end
    local upper = value:upper()
    for _, classFile in ipairs(classFiles) do
        if upper == classFile or upper:sub(-#classFile) == classFile then return classFile end
    end
    return nil
end

---Read a paste into `loaded`.
---@param text string
---@return boolean ok
---@return string|nil error
---Profession names from the sim's JSON (profession1/2, e.g. "Engineering") or this addon's
---export (professions = { { name, level } }).
local function ReadProfessions(data)
    local names = {}
    local function Add(value)
        if type(value) ~= "string" or value == "" then return end
        value = value:gsub("^Profession", ""):gsub("^PROFESSION_", "")
        if value == "" or value == "Unknown" or value == "UNKNOWN" then return end
        value = value:sub(1, 1):upper() .. value:sub(2):lower()
        table.insert(names, value)
    end
    if type(data) ~= "table" then return names end
    Add(data.profession1)
    Add(data.profession2)
    if type(data.professions) == "table" then
        for _, profession in ipairs(data.professions) do
            Add(type(profession) == "table" and profession.name or profession)
        end
    end
    return names
end

---The player's primary professions, lower-cased names as keys.
local function PlayerProfessions()
    local have = {}
    if GetProfessions and GetProfessionInfo then
        local first, second = GetProfessions()
        for _, index in ipairs({ first, second }) do
            local name = index and GetProfessionInfo(index)
            if name then have[name:lower()] = true end
        end
    end
    return have
end

---"Professions: Engineering, Tailoring (you don't have Tailoring)".
local function ProfessionLine(professions)
    if not professions or #professions == 0 then return nil end
    local have = PlayerProfessions()
    local parts = {}
    for _, name in ipairs(professions) do
        if next(have) and not have[name:lower()] then
            table.insert(parts, "|cffff8040" .. name .. "|r")
        else
            table.insert(parts, name)
        end
    end
    local line = L["Professions: %s"]:format(table.concat(parts, ", "))
    if next(have) then
        for _, name in ipairs(professions) do
            if not have[name:lower()] then
                return line .. "  |cff9d9d9d" .. L["(orange: you don't have it, so its bonuses won't apply)"] .. "|r"
            end
        end
    end
    return line
end

local function ReadPaste(text)
    text = strtrim(text or "")
    if text == "" then return false, L["Paste something first."] end

    local json = text
    if Env.Encoding.IsSavedDataText(text) then
        local decoded, err = Env.Encoding.DecodeSavedData(text)
        if not decoded then return false, err end
        json = decoded
    end

    local data, err = Env.Encoding.DecodeJSON(json)
    if type(data) ~= "table" then return false, L["That isn't sim data: %s"]:format(err or "?") end

    -- Saved-data text: { type, spec, entries = { [name] = value } }
    if data.type and type(data.entries) == "table" then
        if data.type ~= "gear" and data.type ~= "talents" then
            return false, L["That saved data is %s; only gear and talents can be imported."]:format(tostring(data.type))
        end
        loaded = { kind = "sets", setType = data.type, entries = {}, classFile = ClassFileFrom(data.spec) }
        for name, value in pairs(data.entries) do
            if data.type == "gear" then
                loaded.entries[name] = { items = ReadItems(value) }
            elseif type(value) == "table" and value.talentsString then
                loaded.entries[name] = { talents = value.talentsString }
            end
        end
        return true
    end

    -- The sim's JSON export.
    if type(data.player) == "table" then
        loaded = {
            kind = "gear", name = L["Imported from sim"],
            items = ReadItems(data.player.equipment),
            talents = data.player.talentsString,
            classFile = ClassFileFrom(data.player.class) or ClassFileFrom(data.player.spec),
            professions = ReadProfessions(data.player),
        }
        return true
    end

    -- This addon's own export.
    if type(data.gear) == "table" then
        loaded = { kind = "gear", name = tostring(data.name or L["Imported"]), items = ReadItems(data.gear),
            talents = data.talents, classFile = ClassFileFrom(data.class), professions = ReadProfessions(data) }
        return true
    end

    return false, L["That JSON doesn't have gear or talents the addon knows."]
end

--------------------------------------------------------------------------------
-- Matching items
--------------------------------------------------------------------------------

-- Same order as ExportStructures/EquipmentSpec.lua.
local itemLayout = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK, INVSLOT_CHEST, INVSLOT_WRIST,
    INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_FINGER1, INVSLOT_FINGER2,
    INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED,
}

---Where each wanted item is: equipped, in the bags, or missing.
---@param items table
---@return table[] rows { slotId, id, where = "equipped"|"bags"|"bank"|"missing", link }
local function MatchItems(items)
    local rows, usedBag = {}, {}
    local bagLinks = {}
    for bagId = 0, NUM_BAG_SLOTS do
        for slotId = 1, C_Container.GetContainerNumSlots(bagId) do
            local link = C_Container.GetContainerItemLink(bagId, slotId)
            if link then table.insert(bagLinks, { key = bagId .. ":" .. slotId, link = link }) end
        end
    end
    -- The bank too, while it's open.
    for _, bagId in ipairs(Env.GetOpenBankContainers() or {}) do
        for slotId = 1, Env.GetContainerSlots(bagId) do
            local link = C_Container.GetContainerItemLink(bagId, slotId)
            if link then table.insert(bagLinks, { key = bagId .. ":" .. slotId, link = link, inBank = true }) end
        end
    end
    local equippedIds = {}
    for _, slotId in ipairs(itemLayout) do
        local link = GetInventoryItemLink("player", slotId)
        if link then equippedIds[Env.GetItemIdFromLink(link)] = link end
    end

    for index, slotId in ipairs(itemLayout) do
        local item = items[index]
        if item then
            local row = { slotId = slotId, id = item.id, where = "missing", item = item }
            local equipped = GetInventoryItemLink("player", slotId)
            if equipped and Env.GetItemIdFromLink(equipped) == item.id then
                row.where, row.link = "equipped", equipped
            elseif equippedIds[item.id] then
                -- Worn in the paired slot (other ring, trinket or hand).
                row.where, row.link = "equipped", equippedIds[item.id]
            else
                for _, bagItem in ipairs(bagLinks) do
                    if not usedBag[bagItem.key] and Env.GetItemIdFromLink(bagItem.link) == item.id then
                        usedBag[bagItem.key] = true
                        row.where, row.link = bagItem.inBank and "bank" or "bags", bagItem.link
                        break
                    end
                end
            end
            table.insert(rows, row)
        end
    end
    return rows
end

--------------------------------------------------------------------------------
-- Talents
--------------------------------------------------------------------------------

function SimImport.ApplyTalents(talentString)
    if not Env.ApplyForeverTalentString then return end
    local _, message = Env.ApplyForeverTalentString(talentString)
    Env.FeaturePrint(message)
end

--------------------------------------------------------------------------------
-- Sending gear sets to the sim
--------------------------------------------------------------------------------

---Show all of a character's gear sets as one saved-data text for the sim's import.
---@param sets table<string, table> GearSets sets
function Env.ExportGearSetBundle(sets)
    local spec = PlayerSpecEnumName()
    if not spec then
        Env.FeaturePrint(L["The sim doesn't support your class yet."])
        return
    end
    local Q = Env.Encoding.QuoteJSON
    local entries = {}
    for name, set in pairs(sets) do
        local items = {}
        for index = 1, #itemLayout do
            local fields = set.items and set.items[index]
            local parts = {}
            if fields and fields.id then
                table.insert(parts, '"id":' .. fields.id)
                if fields.enchant and fields.enchant ~= 0 then table.insert(parts, '"enchant":' .. fields.enchant) end
                if fields.random_suffix and fields.random_suffix ~= 0 then
                    table.insert(parts, '"randomSuffix":' .. fields.random_suffix)
                end
            end
            items[index] = "{" .. table.concat(parts, ",") .. "}"
        end
        table.insert(entries, Q(name) .. ':{"items":[' .. table.concat(items, ",") .. "]}")
    end
    if #entries == 0 then
        Env.FeaturePrint(L["Save a gear set first."])
        return
    end
    local json = '{"type":"gear","spec":' .. Q(spec) .. ',"entries":{' .. table.concat(entries, ",") .. "}}"
    local text, err = Env.Encoding.EncodeSavedData(json)
    if not text then
        Env.FeaturePrint(err)
        return
    end
    Env.ShowTextWindow(L["All gear sets - paste into the sim's saved data import"], text)
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

---"Score with your stat weights: 412 vs 385 now (+7.0%)", or nil without active weights.
local function ScoreComparison(rows)
    local StatWeights = Env.StatWeights
    if not StatWeights or not StatWeights.db then return nil end
    local scaleName, scale = StatWeights:GetActiveScale()
    if not scale then return nil end

    local imported, current = 0, 0
    for _, row in ipairs(rows) do
        imported = imported + (StatWeights.ScoreItem(row.link or ("item:" .. row.id), scale) or 0)
    end
    for _, slotId in ipairs(itemLayout) do
        local link = GetInventoryItemLink("player", slotId)
        if link then current = current + (StatWeights.ScoreItem(link, scale) or 0) end
    end
    if imported <= 0 then return nil end

    local line = L["%s score: %.1f vs %.1f for what you're wearing"]:format(scaleName, imported, current)
    if current > 0 then
        local change = (imported - current) / current * 100
        local color = change >= 0 and "|cff1eff00" or "|cffff4040"
        line = line .. (" (%s%+.1f%%|r)"):format(color, change)
    end
    return line
end

---Points per tree of a talent string, e.g. "31/20/0".
local function PointsPerTree(talentString)
    local counts = {}
    for tree in ((talentString or "") .. "-"):gmatch("([^-]*)-") do
        local points = 0
        for digit in tree:gmatch("%d") do points = points + tonumber(digit) end
        table.insert(counts, points)
    end
    while #counts < 3 do table.insert(counts, 0) end
    return table.concat(counts, "/", 1, 3)
end

---"Talents: 21/0/5 (yours: 9/0/1)".
---Localized class name of a class file, e.g. "MAGE" -> "Mage".
local function ClassName(classFile)
    local names = LOCALIZED_CLASS_NAMES_MALE or {}
    return names[classFile] or (classFile:sub(1, 1) .. classFile:sub(2):lower())
end

---Whether a build is for another class than the player's.
---@param classFile string|nil
---@return boolean
local function IsOtherClass(classFile)
    return classFile ~= nil and classFile ~= select(2, UnitClass("player"))
end

local function TalentComparison(talents, classFile)
    if talents == "" then return nil end
    if IsOtherClass(classFile) then
        return L["Talents: %s (%s build; you're a %s)"]:format(PointsPerTree(talents), ClassName(classFile),
            ClassName(select(2, UnitClass("player"))))
    end
    local yours = Env.Flavor.CreateTalentString(false)
    return L["Talents: %s (yours: %s)"]:format(PointsPerTree(talents), PointsPerTree(yours))
end

---Build a set for GearSets from imported items, using the links found in the game.
local function SetFromItems(items, rows, talents)
    local set = { items = {}, links = {}, talents = talents }
    for index, item in pairs(items) do
        set.items[index] = { id = item.id, enchant = item.enchant }
    end
    for _, row in ipairs(rows) do
        set.links[row.slotId] = row.link or ("item:" .. row.id)
    end
    return set
end

--------------------------------------------------------------------------------
-- Shopping list
--------------------------------------------------------------------------------

local pendingLoads = {}
local refreshQueued = false

---A link for an item ID; a placeholder while the item's data loads (onLoad runs once it has).
local function ItemLinkFor(id, onLoad)
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local _, link = getInfo(id)
    if link then return link end
    if onLoad and not pendingLoads[id] and Item and Item.CreateFromItemID then
        pendingLoads[id] = true
        Item:CreateFromItemID(id):ContinueOnItemLoad(function()
            if refreshQueued then return end
            refreshQueued = true
            C_Timer.After(0.3, function()
                refreshQueued = false
                onLoad()
            end)
        end)
    end
    return "|cff9d9d9d[" .. L["item %d"]:format(id) .. "]|r"
end

---Enchant ID and gem item IDs from an item link.
local function LinkParts(link)
    local itemString = link and link:match("item:([%-%d:]*)")
    if not itemString then return 0, {} end
    local parts = { strsplit(":", itemString) }
    local gems = {}
    for i = 3, 6 do
        local gem = tonumber(parts[i] or "")
        if gem and gem > 0 then table.insert(gems, gem) end
    end
    return tonumber(parts[2] or "") or 0, gems
end

---Gems the sim wants that the owned item doesn't have.
local function MissingGems(wanted, have)
    local left = {}
    for _, gem in ipairs(have) do left[gem] = (left[gem] or 0) + 1 end
    local missing = {}
    for _, gem in ipairs(wanted or {}) do
        if (left[gem] or 0) > 0 then
            left[gem] = left[gem] - 1
        else
            table.insert(missing, gem)
        end
    end
    return missing
end

---What to get to match the sim's set: missing items, other enchants, missing gems.
---@return table[] entries { slotId, link, text }
local function ShoppingList(rows, onLoad)
    local entries = {}
    for _, row in ipairs(rows) do
        local item = row.item or {}
        if row.where == "missing" then
            local extra = ""
            if (item.enchant or 0) > 0 or #(item.gems or {}) > 0 then
                extra = "  |cff9d9d9d" .. L["(plus the sim's enchant and gems)"] .. "|r"
            end
            table.insert(entries, { slotId = row.slotId, link = ItemLinkFor(row.id, onLoad),
                text = "|cffff8040" .. L["Get it"] .. "|r" .. extra })
        else
            local enchant, gems = LinkParts(row.link)
            local wantedEnchant = item.enchant or 0
            if wantedEnchant > 0 and enchant ~= wantedEnchant then
                table.insert(entries, { slotId = row.slotId, link = row.link,
                    text = "|cffffd100" .. (enchant == 0 and L["Needs an enchant"] or L["Has a different enchant than the sim's"]) .. "|r" })
            end
            local missingGems = MissingGems(item.gems, gems)
            if #missingGems > 0 then
                local gemLinks = {}
                for _, gem in ipairs(missingGems) do table.insert(gemLinks, ItemLinkFor(gem, onLoad)) end
                table.insert(entries, { slotId = row.slotId, link = row.link,
                    text = "|cffffd100" .. L["Needs gems:"] .. "|r " .. table.concat(gemLinks, " ") })
            end
        end
    end
    return entries
end

---Plain text for the copy window: "Head: Item Name - Get it".
local function PlainText(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"))
end

local function AddShoppingList(group, rows, name, Refresh)
    local heading = AceGUI:Create("Heading")
    heading:SetFullWidth(true)
    group:AddChild(heading)

    local entries = ShoppingList(rows, Refresh)
    heading:SetText(L["Shopping list (%d)"]:format(#entries))
    if #entries == 0 then
        local done = AceGUI:Create("Label")
        done:SetText("|cff1eff00" .. L["Nothing to get: you have every item, enchanted and gemmed like the sim."] .. "|r")
        done:SetFullWidth(true)
        group:AddChild(done)
        return
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        local text = ("|cffffd100%s:|r %s  %s"):format(Env.SlotName(entry.slotId), entry.link, entry.text)
        table.insert(lines, PlainText(text))
        local label = AceGUI:Create("InteractiveLabel")
        label:SetText(text)
        label:SetFullWidth(true)
        label:SetCallback("OnEnter", function(widget)
            local hyperlink = entry.link:match("|H(item:[^|]+)|h")
            if not hyperlink then return end
            GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(hyperlink)
            GameTooltip:Show()
        end)
        label:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        label:SetCallback("OnClick", function()
            if IsShiftKeyDown() and ChatEdit_InsertLink then ChatEdit_InsertLink(entry.link) end
        end)
        group:AddChild(label)
    end

    local hint = AceGUI:Create("Label")
    hint:SetText("|cff9d9d9d" .. L["Shift-click a line to link the item in chat."] .. "|r")
    hint:SetWidth(330)
    group:AddChild(hint)

    local copy = AceGUI:Create("Button")
    copy:SetText(L["Copy the list"])
    copy:SetWidth(150)
    copy:SetCallback("OnClick", function()
        Env.ShowTextWindow(L["Shopping list: %s"]:format(name), table.concat(lines, "\n"))
    end)
    group:AddChild(copy)
end

local function AddGearSection(scroll, name, items, talents, Refresh)
    local rows = MatchItems(items)
    local found = 0
    for _, row in ipairs(rows) do
        if row.where ~= "missing" then found = found + 1 end
    end

    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(name)
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    scroll:AddChild(group)

    local countColor = (found == #rows and "|cff1eff00") or (found > 0 and "|cffffd100") or "|cffff4040"
    local summaryLines = { L["%s%d of %d|r items found (worn or in bags)"]:format(countColor, found, #rows) }
    if not Env.GetOpenBankContainers() then
        table.insert(summaryLines, "|cff9d9d9d" .. L["Open your bank to include bank items."] .. "|r")
    end
    local scoreLine = ScoreComparison(rows)
    if scoreLine then table.insert(summaryLines, scoreLine) end
    local classFile = loaded and loaded.classFile
    local talentLine = talents and TalentComparison(talents, classFile)
    if talentLine then table.insert(summaryLines, talentLine) end
    local professionLine = loaded and loaded.kind == "gear" and ProfessionLine(loaded.professions)
    if professionLine then table.insert(summaryLines, professionLine) end
    local summary = AceGUI:Create("Label")
    summary:SetText(table.concat(summaryLines, "\n") .. "\n ")
    summary:SetFullWidth(true)
    group:AddChild(summary)

    local gearHeading = AceGUI:Create("Heading")
    gearHeading:SetText(L["Gear"])
    gearHeading:SetFullWidth(true)
    group:AddChild(gearHeading)

    Env.AddPaperDoll(group, rows)

    local buttonRowBreak = AceGUI:Create("Label")
    buttonRowBreak:SetText(" ")
    buttonRowBreak:SetFullWidth(true)
    group:AddChild(buttonRowBreak)

    local equipButton = AceGUI:Create("Button")
    equipButton:SetText(L["Equip what I have"])
    equipButton:SetWidth(170)
    equipButton:SetCallback("OnClick", function()
        local links = {}
        for _, row in ipairs(rows) do
            -- Items in the bank can't be equipped from there.
            if row.where == "equipped" or row.where == "bags" then links[row.slotId] = row.link end
        end
        Env.GearSets:EquipLinks(links, name)
    end)
    group:AddChild(equipButton)

    if Env.GearSets then
        local nameBox = AceGUI:Create("EditBox")
        nameBox:SetLabel(L["Set name"])
        nameBox:SetText(name)
        nameBox:SetWidth(200)
        nameBox:DisableButton(true)
        group:AddChild(nameBox)

        local saveButton = AceGUI:Create("Button")
        saveButton:SetText(L["Save as gear set"])
        saveButton:SetWidth(150)
        saveButton:SetCallback("OnClick", function()
            local setName = strtrim(nameBox:GetText() or "")
            if setName == "" then
                Env.FeaturePrint(L["Enter a name for the set first."])
                return
            end
            if Env.GearSets:GetSets()[setName] then
                Env.FeaturePrint(L["Replaced gear set \"%s\"."]:format(setName))
            else
                Env.FeaturePrint(L["Saved gear set \"%s\"."]:format(setName))
            end
            local set = SetFromItems(items, rows, talents)
            if loaded and loaded.professions and #loaded.professions > 0 then set.professions = loaded.professions end
            Env.GearSets:SaveSet(setName, set)
        end)
        group:AddChild(saveButton)
    end

    AddShoppingList(group, rows, name, Refresh)

    if talents and talents ~= "" then
        local talentHeading = AceGUI:Create("Heading")
        talentHeading:SetText(L["Talents"])
        talentHeading:SetFullWidth(true)
        group:AddChild(talentHeading)

        if not IsOtherClass(classFile) then
            local applyButton = AceGUI:Create("Button")
            applyButton:SetText(L["Apply talents"])
            applyButton:SetWidth(150)
            applyButton:SetCallback("OnClick", function() SimImport.ApplyTalents(talents) end)
            group:AddChild(applyButton)
        end

        if Env.ShowTalentWindow then
            local viewButton = AceGUI:Create("Button")
            viewButton:SetText(L["View talents"])
            viewButton:SetWidth(150)
            viewButton:SetCallback("OnClick", function() Env.ShowTalentWindow(name, talents, loaded and loaded.classFile) end)
            group:AddChild(viewButton)
        end

        local talentLabel = AceGUI:Create("Label")
        talentLabel:SetText("|cff9d9d9d" .. talents .. "|r")
        talentLabel:SetFullWidth(true)
        group:AddChild(talentLabel)
    end
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Refresh()
        container:SelectTab(SimImport.tab.value)
    end

    local paste = Env.AddSection(scroll, L["Paste from the sim"])
    Env.AddHint(paste, L["The sim's Export > JSON, saved gear sets or talent builds (text starting with wowsims-saved), or a WowSims export. Paste it, then click Accept."])

    local pasteBox = AceGUI:Create("MultiLineEditBox")
    pasteBox:SetLabel("")
    pasteBox:SetFullWidth(true)
    pasteBox:SetNumLines(3)
    pasteBox:SetCallback("OnEnterPressed", function(_, _, text)
        local ok, err = ReadPaste(text)
        if not ok then Env.FeaturePrint(err) end
        Refresh()
    end)
    paste:AddChild(pasteBox)

    if not loaded then
        local what = Env.AddSection(scroll, L["What you'll see"])
        Env.AddHint(what, L["Gear: the items on your character model, a score against what you're wearing (with stat weights), and a button to save them as a gear set."])
        Env.AddHint(what, L["Talents: the build as trees next to yours, and Apply talents for your own class."])
        Env.AddHint(what, L["Tip: the Inspect tab's Gear button opens another player's gear here."])
        return
    end

    if loaded.kind == "gear" then
        AddGearSection(scroll, loaded.name, loaded.items, loaded.talents, Refresh)
    elseif loaded.kind == "sets" then
        local names = {}
        for name in pairs(loaded.entries) do table.insert(names, name) end
        table.sort(names)
        for _, name in ipairs(names) do
            local entry = loaded.entries[name]
            if entry.items then
                AddGearSection(scroll, name, entry.items, nil, Refresh)
            elseif entry.talents then
                local group = AceGUI:Create("InlineGroup")
                group:SetTitle(name)
                group:SetFullWidth(true)
                group:SetLayout("Flow")
                scroll:AddChild(group)
                local label = AceGUI:Create("Label")
                label:SetText(entry.talents)
                label:SetWidth(300)
                group:AddChild(label)
                if not IsOtherClass(loaded.classFile) then
                    local applyButton = AceGUI:Create("Button")
                    applyButton:SetText(L["Apply talents"])
                    applyButton:SetWidth(150)
                    applyButton:SetCallback("OnClick", function() SimImport.ApplyTalents(entry.talents) end)
                    group:AddChild(applyButton)
                end
                if Env.ShowTalentWindow then
                    local viewButton = AceGUI:Create("Button")
                    viewButton:SetText(L["View talents"])
                    viewButton:SetWidth(150)
                    viewButton:SetCallback("OnClick", function() Env.ShowTalentWindow(name, entry.talents, loaded and loaded.classFile) end)
                    group:AddChild(viewButton)
                end
            end
        end
    end
end

---Load text into the Import tab, as if it was pasted there (used by the Inspect tab's Gear button).
---@param text string
---@return boolean ok
---@return string|nil error
function SimImport.Load(text)
    return ReadPaste(text)
end

SimImport.tab = { value = "simimport", text = L["Import"], Create = CreateTab }

function SimImport:Initialize(db)
    self.db = db
end

Env.SimImport = SimImport
Env.RegisterFeature(SimImport)
