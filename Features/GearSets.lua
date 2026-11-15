-- Gear sets: save named sets of the equipped gear per character, equip them again out of combat,
-- and export any set to the sim in the same format as the main export.
--
-- Sets are kept in WSEDB.global.gearSets[characterKey][setName] = {
--     saved = time(), -- when the set was saved
--     items = { [itemIndex] = ItemSpec fields }, -- what the export sends, decorations included
--     links = { [slotId] = itemLink },          -- what equipping looks for
-- }

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local GearSets = {}

-- Same order as ExportStructures/EquipmentSpec.lua, which positions items in EquipmentSpec.items.
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
}

-- Slots that take the same kind of item, so an item can move between them.
local pairedSlot = {
    [INVSLOT_FINGER1] = INVSLOT_FINGER2,
    [INVSLOT_FINGER2] = INVSLOT_FINGER1,
    [INVSLOT_TRINKET1] = INVSLOT_TRINKET2,
    [INVSLOT_TRINKET2] = INVSLOT_TRINKET1,
    [INVSLOT_MAINHAND] = INVSLOT_OFFHAND,
    [INVSLOT_OFFHAND] = INVSLOT_MAINHAND,
}

local EQUIP_STEP_DELAY = 0.3 -- seconds between equipping items, so the server keeps up

local function CopyValue(value)
    if type(value) == "table" then
        return CopyTable(value)
    end
    return value
end

---Sets of the logged in character.
---@return table<string, table>
function GearSets:GetSets()
    local all = Env.GetOrCreateTable(self.db.global, "gearSets")
    return Env.GetOrCreateTable(all, Env.CharacterKey())
end

---Save the equipped gear as a set, replacing a set of the same name.
---@param name string
---@return boolean saved
function GearSets:SaveCurrent(name)
    name = name and strtrim(name) or ""
    if name == "" then
        Env.FeaturePrint(L["Enter a name for the set first."])
        return false
    end

    local equipment = Env.CreateEquipmentSpec()
    equipment:UpdateEquippedItems("player")

    local set = { saved = time(), items = {}, links = {}, talents = Env.Flavor.CreateTalentString(false) }
    local count = 0
    for itemIndex, slotId in ipairs(itemLayout) do
        local itemSpec = equipment.items[itemIndex]
        local link = slotId and GetInventoryItemLink("player", slotId)
        if itemSpec and link then
            local fields = {}
            for key, value in pairs(itemSpec) do
                fields[key] = CopyValue(value)
            end
            set.items[itemIndex] = fields
            set.links[slotId] = link
            count = count + 1
        end
    end

    self:GetSets()[name] = set
    Env.FeaturePrint(L["Saved gear set \"%s\" (%d items)."]:format(name, count))
    return true
end

---Save a set made elsewhere, e.g. imported from the sim.
---@param name string
---@param set table { items = { [itemIndex] = ItemSpec fields }, links = { [slotId] = link }, talents = string|nil }
function GearSets:SaveSet(name, set)
    set.saved = time()
    self:GetSets()[name] = set
end

---Lines describing how a set differs from what's equipped now.
---@param name string
---@return string[] lines
function GearSets:Compare(name)
    local set = self:GetSets()[name]
    if not set then return {} end
    local lines = {}
    local slotNames = {
        [INVSLOT_HEAD] = HEADSLOT, [INVSLOT_NECK] = NECKSLOT, [INVSLOT_SHOULDER] = SHOULDERSLOT,
        [INVSLOT_BACK] = BACKSLOT, [INVSLOT_CHEST] = CHESTSLOT, [INVSLOT_WRIST] = WRISTSLOT,
        [INVSLOT_HAND] = HANDSSLOT, [INVSLOT_WAIST] = WAISTSLOT, [INVSLOT_LEGS] = LEGSSLOT,
        [INVSLOT_FEET] = FEETSLOT, [INVSLOT_FINGER1] = FINGER0SLOT, [INVSLOT_FINGER2] = FINGER1SLOT,
        [INVSLOT_TRINKET1] = TRINKET0SLOT, [INVSLOT_TRINKET2] = TRINKET1SLOT,
        [INVSLOT_MAINHAND] = MAINHANDSLOT, [INVSLOT_OFFHAND] = SECONDARYHANDSLOT,
    }
    if INVSLOT_RANGED then slotNames[INVSLOT_RANGED] = RANGEDSLOT end

    local function ItemText(link)
        if not link then return L["(empty)"] end
        local enchant = tonumber(link:match("item:%d+:(%-?%d*)") or "")
        local text = link
        if enchant and enchant > 0 then text = text .. " " .. L["(enchant %d)"]:format(enchant) end
        return text
    end

    for _, slotId in ipairs(itemLayout) do
        local saved = set.links[slotId]
        local now = GetInventoryItemLink("player", slotId)
        local savedKey = saved and saved:match("item:([%-%d:]*)")
        local nowKey = now and now:match("item:([%-%d:]*)")
        -- Compare item and enchant only; other link fields change with level and context.
        local function Short(key) return key and key:match("^(%-?%d*:%-?%d*)") end
        if Short(savedKey) ~= Short(nowKey) then
            table.insert(lines, ("%s: %s -> %s"):format(slotNames[slotId] or tostring(slotId), ItemText(now), ItemText(saved)))
        end
    end
    local currentTalents = Env.Flavor.CreateTalentString(false)
    if set.talents and set.talents ~= currentTalents then
        table.insert(lines, L["Talents: %s -> %s"]:format(currentTalents ~= "" and currentTalents or "-", set.talents))
    end
    if #lines == 0 then
        table.insert(lines, L["Same as what you're wearing now."])
    end
    return lines
end

---@param name string
function GearSets:Delete(name)
    self:GetSets()[name] = nil
    Env.FeaturePrint(L["Deleted gear set \"%s\"."]:format(name))
end

---Export a set in the main export's format: this character with the set's gear.
---@param name string
---@return string|nil json
function GearSets:Export(name)
    local set = self:GetSets()[name]
    if not set then return nil end

    local character = Env.CreateCharacter()
    character:SetUnit("player")
    character:FillForExport(false)

    local equipment = Env.CreateEquipmentSpec()
    for itemIndex, fields in pairs(set.items) do
        local itemSpec = Env.CreateItemSpec()
        for key, value in pairs(fields) do
            -- A field another client version wrote is skipped instead of failing the export.
            pcall(function() itemSpec[key] = CopyValue(value) end)
        end
        equipment.items[itemIndex] = itemSpec
    end
    character.gear = equipment

    return Env.JSONEncode(character)
end

---Find an item in the bags, preferring the exact link (same enchant and gems) over the same item ID.
---@param link string
---@param used table<string, boolean> Bag positions already taken by this equip.
---@return integer|nil bagId
---@return integer|nil slotId
local function FindInBags(link, used)
    local wantedId = Env.GetItemIdFromLink(link)
    local fallbackBag, fallbackSlot
    for bagId = 0, NUM_BAG_SLOTS do
        for slotId = 1, C_Container.GetContainerNumSlots(bagId) do
            local key = bagId .. ":" .. slotId
            local bagLink = not used[key] and C_Container.GetContainerItemLink(bagId, slotId)
            if bagLink then
                if bagLink == link then
                    return bagId, slotId
                elseif not fallbackBag and Env.GetItemIdFromLink(bagLink) == wantedId then
                    fallbackBag, fallbackSlot = bagId, slotId
                end
            end
        end
    end
    return fallbackBag, fallbackSlot
end

---Equip a set, one item at a time. Only works out of combat.
---@param name string
function GearSets:Equip(name)
    local set = self:GetSets()[name]
    if set then self:EquipLinks(set.links, name) end
end

---Equip items by slot, one at a time, from the bags or the paired slot. Only works out of combat.
---@param links table<integer, string> slotId to item link (an "item:ID" string works too)
---@param name string Shown in the messages.
function GearSets:EquipLinks(links, name)
    if InCombatLockdown() then
        Env.FeaturePrint(L["You can't change gear in combat."])
        return
    end

    local queue = {}
    for slotId, link in pairs(links) do
        local current = GetInventoryItemLink("player", slotId)
        if not current or Env.GetItemIdFromLink(current) ~= Env.GetItemIdFromLink(link) then
            table.insert(queue, { slotId = slotId, link = link })
        end
    end
    table.sort(queue, function(a, b) return a.slotId < b.slotId end)
    if #queue == 0 then
        Env.FeaturePrint(L["You're already wearing \"%s\"."]:format(name))
        return
    end

    local used, missing = {}, {}
    local function Step(index)
        if index > #queue then
            if #missing > 0 then
                Env.FeaturePrint(L["Equipped \"%s\". Not found in your bags:"]:format(name) .. " " .. table.concat(missing, " "))
            else
                Env.FeaturePrint(L["Equipped \"%s\"."]:format(name))
            end
            return
        end
        if InCombatLockdown() then
            Env.FeaturePrint(L["Stopped equipping: you entered combat."])
            return
        end

        local job = queue[index]
        local wantedId = Env.GetItemIdFromLink(job.link)
        local current = GetInventoryItemLink("player", job.slotId)
        if not current or Env.GetItemIdFromLink(current) ~= wantedId then
            ClearCursor()
            local bagId, bagSlot = FindInBags(job.link, used)
            local other = pairedSlot[job.slotId]
            local otherLink = other and GetInventoryItemLink("player", other)
            if bagId then
                used[bagId .. ":" .. bagSlot] = true
                C_Container.PickupContainerItem(bagId, bagSlot)
                EquipCursorItem(job.slotId)
            elseif otherLink and Env.GetItemIdFromLink(otherLink) == wantedId then
                -- It's in the paired slot (the other ring, trinket or hand): swap the two.
                PickupInventoryItem(other)
                EquipCursorItem(job.slotId)
            else
                table.insert(missing, job.link)
            end
            ClearCursor()
        end
        C_Timer.After(EQUIP_STEP_DELAY, function() Step(index + 1) end)
    end
    Step(1)
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Refresh()
        container:SelectTab(GearSets.tab.value)
    end

    local newSet = Env.AddSection and Env.AddSection(scroll, L["Save what you're wearing"]) or scroll
    if Env.AddHint then
        Env.AddHint(newSet, L["Save your current gear and talents under a name. Equip it again later, compare it, or send it to the sim."])
    end

    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel(L["Set name"])
    nameBox:SetWidth(220)
    nameBox:DisableButton(true)
    newSet:AddChild(nameBox)

    local saveButton = AceGUI:Create("Button")
    saveButton:SetText(L["Save current gear"])
    saveButton:SetWidth(180)
    saveButton:SetCallback("OnClick", function()
        if GearSets:SaveCurrent(nameBox:GetText()) then Refresh() end
    end)
    newSet:AddChild(saveButton)

    if Env.ExportGearSetBundle then
        local bundleButton = AceGUI:Create("Button")
        bundleButton:SetText(L["Send all sets to sim"])
        bundleButton:SetWidth(180)
        bundleButton:SetCallback("OnClick", function() Env.ExportGearSetBundle(GearSets:GetSets()) end)
        bundleButton:SetDisabled(next(GearSets:GetSets()) == nil)
        newSet:AddChild(bundleButton)
    end

    local sets = GearSets:GetSets()
    local names = {}
    for name in pairs(sets) do table.insert(names, name) end
    table.sort(names)

    local heading = AceGUI:Create("Heading")
    heading:SetText(L["Your gear sets (%d)"]:format(#names))
    heading:SetFullWidth(true)
    scroll:AddChild(heading)

    if #names == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetText("|cff9d9d9d" .. L["No gear sets yet for this character."] .. " "
            .. L["Type a name above and click Save current gear, or save one from the Import tab."] .. "|r")
        empty:SetFullWidth(true)
        scroll:AddChild(empty)
        return
    end

    for _, name in ipairs(names) do
        local set = sets[name]
        local count = 0
        for _ in pairs(set.links) do count = count + 1 end

        local group = AceGUI:Create("InlineGroup")
        group:SetTitle(name)
        group:SetFullWidth(true)
        group:SetLayout("Flow")
        scroll:AddChild(group)

        for _, slotId in ipairs(itemLayout) do
            if set.links[slotId] then Env.AddItemIcon(group, set.links[slotId]) end
        end

        local info = AceGUI:Create("Label")
        local details = { L["%d items"]:format(count),
            L["saved %s"]:format(Env.Ago and Env.Ago(set.saved) or date("%Y-%m-%d %H:%M", set.saved)) }
        if set.talents and set.talents ~= "" and Env.TalentPointsText then
            table.insert(details, L["talents %s"]:format(Env.TalentPointsText(set.talents)))
        end
        if type(set.professions) == "table" and #set.professions > 0 then
            table.insert(details, table.concat(set.professions, ", "))
        end
        info:SetText("|cff9d9d9d" .. table.concat(details, "  ·  ") .. "|r")
        info:SetFullWidth(true)
        group:AddChild(info)

        local equipButton = AceGUI:Create("Button")
        equipButton:SetText(L["Equip"])
        equipButton:SetWidth(90)
        equipButton:SetCallback("OnClick", function() GearSets:Equip(name) end)
        group:AddChild(equipButton)

        local exportButton = AceGUI:Create("Button")
        exportButton:SetText(L["Export"])
        exportButton:SetWidth(90)
        exportButton:SetCallback("OnClick", function()
            local json = GearSets:Export(name)
            if json then
                Env.ShowTextWindow(L["Gear set \"%s\" - paste into the sim's Addon import"]:format(name), json)
            end
        end)
        group:AddChild(exportButton)

        if Env.ChatLinks then
            local linkButton = AceGUI:Create("Button")
            linkButton:SetText(L["Link"])
            linkButton:SetWidth(90)
            linkButton:SetCallback("OnClick", function() Env.ChatLinks:LinkSet(name) end)
            linkButton:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
                GameTooltip:SetText(L["Link in chat"])
                GameTooltip:AddLine(L["Other WowSims users can click the link to open this set."], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            linkButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            group:AddChild(linkButton)
        end

        if set.talents and set.talents ~= "" and Env.ShowTalentWindow then
            local talentsButton = AceGUI:Create("Button")
            talentsButton:SetText(L["Talents"])
            talentsButton:SetWidth(90)
            talentsButton:SetCallback("OnClick", function()
                Env.ShowTalentWindow(L["Talents of \"%s\""]:format(name), set.talents)
            end)
            group:AddChild(talentsButton)
        end

        local compareButton = AceGUI:Create("Button")
        compareButton:SetText(L["Compare"])
        compareButton:SetWidth(90)
        compareButton:SetCallback("OnClick", function()
            Env.ShowTextWindow(L["\"%s\" compared to what you're wearing"]:format(name),
                table.concat(GearSets:Compare(name), "\n"))
        end)
        group:AddChild(compareButton)

        local deleteButton = AceGUI:Create("Button")
        deleteButton:SetText(L["Delete"])
        deleteButton:SetWidth(90)
        deleteButton:SetCallback("OnClick", function()
            GearSets:Delete(name)
            Refresh()
        end)
        group:AddChild(deleteButton)
    end
end

GearSets.tab = { value = "gearsets", text = L["Gear Sets"], Create = CreateTab }

function GearSets:Initialize(db)
    self.db = db
end

Env.GearSets = GearSets
Env.RegisterFeature(GearSets)
