-- Shared pieces for the features under Features/.
--
-- A feature is a table registered with Env.RegisterFeature(feature) that may have:
-- - Initialize(self, db, addon): called from OnInitialize once the saved variables are loaded.
-- - tab = { value = "id", text = "Tab name", Create = function(container) end }: a tab in the main window.
--
-- Features keep their data in the existing WSEDB saved variables (db.global or db.profile),
-- creating their own subtables on first use, so data saved before them is never touched.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

Env.Features = {}

---@param feature table
function Env.RegisterFeature(feature)
    table.insert(Env.Features, feature)
end

---Print a message with the addon's chat prefix.
---@param message string
function Env.FeaturePrint(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00WowSims|r: " .. message)
end

---Key for the logged in character, the same form SavedDataManager uses.
---@return string
function Env.CharacterKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

---Get a subtable of a table, creating it if it doesn't exist.
---@param parent table
---@param key string
---@return table
function Env.GetOrCreateTable(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

---Put a near-solid dark background behind an AceGUI Frame, which is see-through by default.
---AceGUI shares its frames with other addons, so the background hides again when the frame does.
---@param widget table AceGUI Frame
function Env.MakeOpaque(widget)
    local frame = widget.frame
    if not frame.wowsimsSolid then
        local solid = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        solid:SetPoint("TOPLEFT", 8, -8)
        solid:SetPoint("BOTTOMRIGHT", -8, 8)
        solid:SetColorTexture(0.05, 0.05, 0.06, 0.94)
        frame.wowsimsSolid = solid
        frame:HookScript("OnHide", function(self) self.wowsimsSolid:Hide() end)
    end
    frame.wowsimsSolid:Show()
end

local function SetResizeBounds(frame, width, height)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(width, height)
    elseif frame.SetMinResize then
        frame:SetMinResize(width, height)
    end
end

---Stop an AceGUI Frame from being resized smaller than width x height. The frame is pooled
---and shared with other addons, so AceGUI's own 400x200 minimum comes back when it's hidden.
---@param widget table AceGUI Frame
---@param width number
---@param height number
function Env.SetMinSize(widget, width, height)
    local frame = widget.frame
    SetResizeBounds(frame, width, height)
    if frame:GetWidth() < width then widget:SetWidth(width) end
    if frame:GetHeight() < height then widget:SetHeight(height) end
    if not frame.wowsimsMinSizeHooked then
        frame.wowsimsMinSizeHooked = true
        frame:HookScript("OnHide", function(self) SetResizeBounds(self, 400, 200) end)
    end
end

---Show a window with text that's selected and ready to copy.
---@param title string
---@param text string
function Env.ShowTextWindow(title, text)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(title)
    frame:SetStatusText(L["Use CTRL+C to copy"])
    Env.MakeOpaque(frame)
    frame:SetLayout("Fill")
    frame:SetWidth(500)
    frame:SetHeight(300)
    Env.SetMinSize(frame, 360, 220)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel("")
    box:DisableButton(true)
    box:SetText(text)
    frame:AddChild(box)
    box:SetFocus()
    box:HighlightText()
end

---Item info that works on every client, old and new API.
---@param item string|number Item link or ID.
---@return string|nil equipLoc e.g. "INVTYPE_HEAD", nil if unknown.
function Env.GetItemEquipLoc(item)
    local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not getInstant then return nil end
    local _, _, _, equipLoc = getInstant(item)
    if equipLoc == "" then return nil end
    return equipLoc
end

---Item ID of an item link.
---@param itemLink string
---@return integer|nil
function Env.GetItemIdFromLink(itemLink)
    return tonumber(itemLink:match("item:(%d+)"))
end

-- The client's slot for ranged weapons. MoP Classic has none and puts them in the main hand.
local rangedSlot = INVSLOT_RANGED
if not rangedSlot then
    local ok, slot = pcall(GetInventorySlotInfo, "RangedSlot")
    rangedSlot = ok and slot or nil
end

-- Equipment slots an item of an equip location goes in.
local slotsByEquipLoc = {
    INVTYPE_HEAD = { INVSLOT_HEAD },
    INVTYPE_NECK = { INVSLOT_NECK },
    INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
    INVTYPE_CLOAK = { INVSLOT_BACK },
    INVTYPE_CHEST = { INVSLOT_CHEST },
    INVTYPE_ROBE = { INVSLOT_CHEST },
    INVTYPE_WRIST = { INVSLOT_WRIST },
    INVTYPE_HAND = { INVSLOT_HAND },
    INVTYPE_WAIST = { INVSLOT_WAIST },
    INVTYPE_LEGS = { INVSLOT_LEGS },
    INVTYPE_FEET = { INVSLOT_FEET },
    INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_2HWEAPON = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND },
    INVTYPE_SHIELD = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE = { INVSLOT_OFFHAND },
    INVTYPE_RANGED = { rangedSlot or INVSLOT_MAINHAND },
    INVTYPE_RANGEDRIGHT = { rangedSlot or INVSLOT_MAINHAND },
    INVTYPE_THROWN = { rangedSlot or INVSLOT_MAINHAND },
    INVTYPE_RELIC = { rangedSlot },
}

---Equipment slots an item can go in.
---@param equipLoc string|nil
---@return integer[] slots Empty for items that can't be equipped.
function Env.GetSlotsForEquipLoc(equipLoc)
    return equipLoc and slotsByEquipLoc[equipLoc] or {}
end

---Whether an equip location is a ranged weapon, for picking the weapon DPS weight.
---@param equipLoc string|nil
---@return boolean
function Env.IsRangedEquipLoc(equipLoc)
    return equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" or equipLoc == "INVTYPE_THROWN"
end

-- Export hooks: features add { Before = fn(character, isInspect), After = fn(json, character, isInspect) }.
-- They run for exports made from the window (not auto-saves). Before can change what's exported.
Env.exportHooks = {}

---@param hook table
function Env.AddExportHook(hook)
    table.insert(Env.exportHooks, hook)
end

---Run one stage of the export hooks. A failing hook is reported without stopping the export.
---@param stage "Before"|"After"
function Env.RunExportHooks(stage, ...)
    for _, hook in ipairs(Env.exportHooks) do
        if hook[stage] then
            local ok, err = pcall(hook[stage], ...)
            if not ok and geterrorhandler then geterrorhandler()(err) end
        end
    end
end

-- Settings in the game's options (Options > AddOns > WowSimsExporter). Each feature adds a group of
-- AceConfig options when its file loads; WowSimsExporter.lua adds them all to its options table
-- before registering it, so they appear under the exporter's own settings.
local optionGroups = {}

---Add a group of options to the addon's settings page.
---@param key string Unique key, e.g. "tooltips".
---@param order number Position among the WowSims groups (lower first).
---@param name string Heading shown above the group.
---@param args table AceConfig args (toggles, buttons...). Getters run when the page is shown.
function Env.AddOptions(key, order, name, args)
    optionGroups[key] = { type = "group", inline = true, name = name, order = 100 + order, args = args }
end

---Add every feature's option group to the addon's AceConfig options table.
---@param options table The options table passed to AceConfig's RegisterOptionsTable.
function Env.AddFeatureOptions(options)
    -- The exporter's own toggles (character pane button, startup message) belong in General.
    local general = optionGroups.general
    if general then
        for key, order in pairs({ showCharacterButton = 2, showStartupMessage = 3 }) do
            local option = options.args[key]
            if option then
                option.order, option.width = order, "full"
                general.args[key] = option
                options.args[key] = nil
            end
        end
    end
    if options.args.openExporterButton then
        options.args.openExporterButton.name = L["Open WowSims"]
        options.args.openExporterButton.desc = nil
        options.args.openExporterButton.width = nil
    end
    for key, group in pairs(optionGroups) do
        options.args["wowsims_" .. key] = group
    end
end

---A simple on/off option for Env.AddOptions.
---@param order number
---@param name string
---@param desc string|nil
---@param get fun(): boolean
---@param set fun(value: boolean)
---@return table
function Env.Toggle(order, name, desc, get, set)
    return {
        type = "toggle", order = order, width = "full", name = name, desc = desc,
        get = function() return get() and true or false end,
        set = function(_, value) set(value) end,
    }
end

-- Events for features, on their own frame. AceEvent keeps one handler per event per object,
-- so registering on the addon object could replace the addon's own handlers (e.g. auto-save).
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}
eventFrame:SetScript("OnEvent", function(_, event, ...)
    for _, handler in ipairs(eventHandlers[event] or {}) do
        local ok, err = pcall(handler, event, ...)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end)

---Call handler(event, ...) on an event. Events the client doesn't have are skipped.
---@param event string
---@param handler function
function Env.RegisterFeatureEvent(event, handler)
    if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then return end
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(eventHandlers[event], handler)
end

---Show or hide a colored border on an AceGUI Icon. AceGUI reuses widgets, so every icon that
---may have had one sets it (nil hides it).
---@param icon table AceGUI Icon widget
---@param color table|nil { r, g, b }
function Env.SetIconBorder(icon, color)
    local frame = icon.frame
    if not frame.wowsimsBorder then
        if not color then return end
        local border = frame:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Common\\WhiteIconFrame")
        frame.wowsimsBorder = border
    end
    local border = frame.wowsimsBorder
    if not color then
        border:Hide()
        return
    end
    border:ClearAllPoints()
    border:SetAllPoints(icon.image)
    border:SetVertexColor(color.r, color.g, color.b)
    border:Show()
end

---Quality color of an item, nil if unknown yet.
---@param itemId integer
---@return table|nil color { r, g, b, hex }
function Env.GetItemQualityColor(itemId)
    local quality = C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemId)
    if not quality then
        local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        quality = select(3, getInfo(itemId))
    end
    local colors = ITEM_QUALITY_COLORS
    return quality and colors and colors[quality] or nil
end

---Add an item icon to an AceGUI container, with the item's tooltip on hover.
---@param container table AceGUI container (Flow layout).
---@param item string|number Item link, "item:ID" string, or item ID.
---@param missing boolean|nil Grey the icon out with a red tint.
function Env.AddItemIcon(container, item, missing)
    local itemId = type(item) == "number" and item or Env.GetItemIdFromLink(item)
    if not itemId then return end
    local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    local icon = AceGUI:Create("Icon")
    icon:SetImage(getIcon and getIcon(itemId) or 134400) -- 134400: question mark
    icon:SetImageSize(30, 30)
    icon:SetWidth(36)
    icon:SetHeight(36)
    if icon.image then
        icon.image:SetDesaturated(missing and true or false)
        if missing then icon.image:SetVertexColor(1, 0.4, 0.4) else icon.image:SetVertexColor(1, 1, 1) end
    end
    Env.SetIconBorder(icon, not missing and Env.GetItemQualityColor(itemId) or nil)
    icon:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
        if type(item) == "string" and item:find("item:") then
            GameTooltip:SetHyperlink(item:match("|H(item:[^|]+)|h") or item)
        else
            GameTooltip:SetHyperlink("item:" .. itemId)
        end
        if missing then GameTooltip:AddLine(L["Not in your bags"], 1, 0.3, 0.3) end
        GameTooltip:Show()
    end)
    icon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    container:AddChild(icon)
    return icon
end

---"5m ago", "3h ago", "2d ago".
---@param timestamp integer
---@return string
function Env.Ago(timestamp)
    local seconds = math.max(0, time() - (timestamp or 0))
    if seconds < 3600 then return L["%dm ago"]:format(math.max(1, math.floor(seconds / 60))) end
    if seconds < 86400 then return L["%dh ago"]:format(math.floor(seconds / 3600)) end
    return L["%dd ago"]:format(math.floor(seconds / 86400))
end

---Grey hint text for the tabs.
---@param container table
---@param text string
function Env.AddHint(container, text)
    local label = AceGUI:Create("Label")
    label:SetText("|cff9d9d9d" .. text .. "|r")
    label:SetFullWidth(true)
    container:AddChild(label)
    return label
end

---A titled box in a tab.
---@param container table
---@param title string
---@return table group
function Env.AddSection(container, title)
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(title)
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    container:AddChild(group)
    return group
end

---Points per tree of a talent string, e.g. "21/0/5".
---@param talentString string|nil
---@return string
function Env.TalentPointsText(talentString)
    local counts = {}
    for tree in ((talentString or "") .. "-"):gmatch("([^-]*)-") do
        local points = 0
        for digit in tree:gmatch("%d") do points = points + tonumber(digit) end
        table.insert(counts, points)
    end
    while #counts < 3 do table.insert(counts, 0) end
    return table.concat(counts, "/", 1, 3)
end

---Name of an equipment slot, e.g. "Head".
---@param slotId integer
---@return string
function Env.SlotName(slotId)
    local names = {
        [INVSLOT_HEAD or 1] = L["Head"], [INVSLOT_NECK or 2] = L["Neck"], [INVSLOT_SHOULDER or 3] = L["Shoulder"],
        [INVSLOT_CHEST or 5] = L["Chest"], [INVSLOT_WAIST or 6] = L["Waist"], [INVSLOT_LEGS or 7] = L["Legs"],
        [INVSLOT_FEET or 8] = L["Feet"], [INVSLOT_WRIST or 9] = L["Wrist"], [INVSLOT_HAND or 10] = L["Hands"],
        [INVSLOT_FINGER1 or 11] = L["Ring"], [INVSLOT_FINGER2 or 12] = L["Ring"],
        [INVSLOT_TRINKET1 or 13] = L["Trinket"], [INVSLOT_TRINKET2 or 14] = L["Trinket"],
        [INVSLOT_BACK or 15] = L["Back"], [INVSLOT_MAINHAND or 16] = L["Main Hand"],
        [INVSLOT_OFFHAND or 17] = L["Off Hand"], [INVSLOT_RANGED or 18] = L["Ranged"],
    }
    return names[slotId] or ""
end

-- Bank ------------------------------------------------------------------------------------------

local bankOpen = false
Env.RegisterFeatureEvent("BANKFRAME_OPENED", function() bankOpen = true end)
Env.RegisterFeatureEvent("BANKFRAME_CLOSED", function() bankOpen = false end)

---Container IDs of the bank while it's open, or nil when it's closed. Built from whatever the
---client defines: the classic bank and its bags, and the retail client's bank tabs (Forever runs
---on the retail client, where the bank was reworked). IDs the client doesn't have are skipped.
---@return integer[]|nil
function Env.GetOpenBankContainers()
    if not bankOpen then return nil end
    local ids, seen = {}, {}
    local function Add(id)
        if type(id) == "number" and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    Add(BANK_CONTAINER)
    if NUM_BANKBAGSLOTS and NUM_BAG_SLOTS then
        local first = (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS) + 1
        for i = 0, NUM_BANKBAGSLOTS - 1 do Add(first + i) end
    end
    local bagIndex = Enum and Enum.BagIndex
    if bagIndex then
        Add(bagIndex.Bank)
        for i = 1, 7 do Add(bagIndex["BankBag_" .. i]) end
        for i = 1, 6 do Add(bagIndex["CharacterBankTab_" .. i]) end
    end
    return ids
end

---Number of slots in a container, 0 if the client doesn't know it.
---@param bagId integer
---@return integer
function Env.GetContainerSlots(bagId)
    local ok, slots = pcall(C_Container.GetContainerNumSlots, bagId)
    return ok and tonumber(slots) or 0
end
