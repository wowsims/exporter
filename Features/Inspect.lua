-- Inspect tab (Forever): export the target, keep the last exports, and fill in inspected players'
-- professions, which the client doesn't share with addons:
-- - from profession windows other players link in chat, saved automatically,
-- - or picked by hand for the current target.
--
-- Data: WSEDB.global.inspectHistory = { { name, class, level, time, json }, ... } (newest first)
--       WSEDB.global.knownProfessions = { [name] = { [engName] = level } }

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local Inspect = {}

local HISTORY_SIZE = 15
local PROFESSIONS = {
    "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Jewelcrafting",
    "Leatherworking", "Mining", "Skinning", "Tailoring",
}
local DEFAULT_PROFESSION_LEVEL = 60

local function GetData()
    local global = Inspect.db.global
    Env.GetOrCreateTable(global, "inspectHistory")
    Env.GetOrCreateTable(global, "knownProfessions")
    return global
end

---Keys a player's professions are stored under. Forever names are "Firstname Surname" and
---UnitName returns only the first name, so both the full name and the first word are used.
---@param name string
---@return string[] keys
local function NameKeys(name)
    name = Ambiguate and Ambiguate(name, "short") or name
    local keys = { name }
    local first = name:match("^(%S+)%s")
    if first then table.insert(keys, first) end
    return keys
end

---Turn { engName = level } into the export's professions list.
local function ToProfessionList(professions)
    local list = {}
    for engName, level in pairs(professions) do
        table.insert(list, { name = engName, level = level })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

---Remember a player's professions and make the inspect export use them.
---@param name string
---@param professions table<string, integer> engName to skill level
function Inspect:SetProfessions(name, professions)
    local known = GetData().knownProfessions
    local list = ToProfessionList(professions)
    for _, key in ipairs(NameKeys(name)) do
        known[key] = professions
        Env.AddInspectedProfessions(key, list)
    end
end

---Load saved professions into the table the inspect export reads.
local function LoadKnownProfessions()
    for name, professions in pairs(GetData().knownProfessions) do
        if not Env.profInspectTable[name] then
            Env.AddInspectedProfessions(name, ToProfessionList(professions))
        end
    end
end

---When a linked profession window opens, save that player's profession and skill level.
local function OnTradeSkillShow()
    local tradeSkill = C_TradeSkillUI
    if not (tradeSkill and tradeSkill.IsTradeSkillLinked and tradeSkill.GetBaseProfessionInfo) then return end
    local isLinked, playerName = tradeSkill.IsTradeSkillLinked()
    if not isLinked or not playerName or playerName == "" then return end

    local info = tradeSkill.GetBaseProfessionInfo()
    if not info or not info.skillLevel or info.skillLevel <= 0 then return end
    local engName = Env.professionEngNameBySkillLine[info.professionID]
        or (info.professionName and Env.professionNames[info.professionName]
            and Env.professionNames[info.professionName].engName)
    if not engName then return end

    local current = {}
    local known = GetData().knownProfessions[NameKeys(playerName)[1]]
    for name, level in pairs(known or {}) do current[name] = level end
    if current[engName] == info.skillLevel then return end
    current[engName] = info.skillLevel
    Inspect:SetProfessions(playerName, current)
    Env.FeaturePrint(L["Saved %s's %s (%d) for inspect exports."]:format(playerName, engName, info.skillLevel))
end

---Keep an inspect export in the history.
local function AddToHistory(json, character)
    local history = GetData().inspectHistory
    for i = #history, 1, -1 do
        if history[i].name == character.name then table.remove(history, i) end
    end
    table.insert(history, 1, {
        name = character.name,
        class = character.class,
        level = character.level,
        time = time(),
        json = json,
    })
    while #history > HISTORY_SIZE do table.remove(history) end
end

---Inspect the target and show its export.
---@param onDone fun()|nil
---@param unit string|nil Defaults to the target.
function Inspect:ExportTarget(onDone, unit)
    self.addon:RequestInspect(function()
        local json = self.addon:BuildExport(true)
        if json then
            Env.ShowTextWindow(L["Inspect export - paste into the sim's Addon import"], json)
        else
            Env.FeaturePrint(L["The sim doesn't support that player's class yet."])
        end
        if onDone then onDone() end
    end, unit)
end

-- "Export to WowSims" on player right-click menus (target, party, raid, focus frames).
local MENU_TAGS = { "MENU_UNIT_TARGET", "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FOCUS" }
local function AddUnitMenuEntries()
    if not (Menu and Menu.ModifyMenu) then return end
    for _, tag in ipairs(MENU_TAGS) do
        pcall(Menu.ModifyMenu, tag, function(_, rootDescription, contextData)
            local unit = contextData and contextData.unit
            if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
            rootDescription:CreateDivider()
            rootDescription:CreateButton("|cff00ccffWowSims|r " .. L["Export to sim"], function()
                Inspect:ExportTarget(nil, unit)
            end)
        end)
    end
end

---The target's full name ("Firstname Surname" in Forever), nil without a player target.
local function TargetName()
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
        -- Forever: UnitFullName returns the surname where other clients return the realm.
        local first, surname = UnitFullName("target")
        return (surname and surname ~= "") and (first .. " " .. surname) or first
    end
    return nil
end

local function AddProfessionPicker(container, targetName, Refresh)
    local list = { [""] = L["None"] }
    for _, name in ipairs(PROFESSIONS) do list[name] = name end
    local order = { "" }
    for _, name in ipairs(PROFESSIONS) do table.insert(order, name) end

    local current = GetData().knownProfessions[NameKeys(targetName)[1]] or {}
    local picked = {}
    for name in pairs(current) do
        table.insert(picked, name)
    end
    table.sort(picked)

    local dropdowns, levelBoxes = {}, {}
    for i = 1, 2 do
        local dropdown = AceGUI:Create("Dropdown")
        dropdown:SetLabel(L["Profession %d"]:format(i))
        dropdown:SetList(list, order)
        dropdown:SetValue(picked[i] or "")
        dropdown:SetWidth(170)
        container:AddChild(dropdown)
        dropdowns[i] = dropdown

        local levelBox = AceGUI:Create("EditBox")
        levelBox:SetLabel(L["Skill"])
        levelBox:SetText(tostring(current[picked[i] or ""] or DEFAULT_PROFESSION_LEVEL))
        levelBox:SetWidth(60)
        levelBox:DisableButton(true)
        container:AddChild(levelBox)
        levelBoxes[i] = levelBox
    end

    local saveButton = AceGUI:Create("Button")
    saveButton:SetText(L["Save professions"])
    saveButton:SetWidth(200)
    saveButton:SetCallback("OnClick", function()
        local professions = {}
        for i = 1, 2 do
            local name = dropdowns[i]:GetValue()
            if name and name ~= "" then
                professions[name] = tonumber(levelBoxes[i]:GetText()) or DEFAULT_PROFESSION_LEVEL
            end
        end
        Inspect:SetProfessions(targetName, professions)
        Env.FeaturePrint(L["Saved professions for %s."]:format(targetName))
        Refresh()
    end)
    container:AddChild(saveButton)
end

---"5m ago", "3h ago", "2d ago".
local function Ago(timestamp)
    local seconds = math.max(0, time() - (timestamp or 0))
    if seconds < 3600 then return L["%dm ago"]:format(math.max(1, math.floor(seconds / 60))) end
    if seconds < 86400 then return L["%dh ago"]:format(math.floor(seconds / 3600)) end
    return L["%dd ago"]:format(math.floor(seconds / 86400))
end

---"|cff...Name|r" in the class's color.
local function ClassColored(text, classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile:upper()]
    if not color then return text end
    return ("|c%s%s|r"):format(color.colorStr or "ffffffff", text)
end

local function ClassName(classFile)
    if not classFile then return "" end
    local names = LOCALIZED_CLASS_NAMES_MALE or {}
    return names[classFile:upper()] or (classFile:sub(1, 1):upper() .. classFile:sub(2):lower())
end

---A class icon (round class emblem).
local function AddClassIcon(container, classFile, size)
    local icon = AceGUI:Create("Icon")
    local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile:upper()]
    if coords then
        icon:SetImage("Interface\\TargetingFrame\\UI-Classes-Circles", unpack(coords))
    else
        icon:SetImage(134400)
    end
    icon:SetImageSize(size, size)
    icon:SetWidth(size + 6)
    icon:SetHeight(size + 4)
    if icon.image then
        icon.image:SetDesaturated(false)
        icon.image:SetVertexColor(1, 1, 1)
    end
    Env.SetIconBorder(icon, nil)
    container:AddChild(icon)
end

local function AddButton(container, text, width, onClick)
    local button = AceGUI:Create("Button")
    button:SetText(text)
    button:SetWidth(width)
    button:SetCallback("OnClick", onClick)
    container:AddChild(button)
    return button
end

local function AddTargetCard(scroll, Refresh)
    local card = AceGUI:Create("InlineGroup")
    card:SetTitle(L["Target"])
    card:SetFullWidth(true)
    card:SetLayout("Flow")
    scroll:AddChild(card)

    local targetName = TargetName()
    if not targetName then
        local label = AceGUI:Create("Label")
        label:SetText(L["Target a player, out of combat and close by, to export them and set their professions."])
        label:SetFullWidth(true)
        card:AddChild(label)
        return
    end

    local _, classFile = UnitClass("target")
    AddClassIcon(card, classFile, 36)
    local name = AceGUI:Create("Label")
    name:SetText(("%s\n|cffbbbbbb%s %s %s|r"):format(ClassColored(targetName, classFile), LEVEL or "Level",
        tostring(UnitLevel("target")), ClassName(classFile)))
    name:SetFontObject(GameFontNormalLarge)
    name:SetWidth(330)
    card:AddChild(name)
    AddButton(card, L["Inspect and export"], 200, function() Inspect:ExportTarget(Refresh) end)

    local professionsHeading = AceGUI:Create("Heading")
    professionsHeading:SetText(L["Professions"])
    professionsHeading:SetFullWidth(true)
    card:AddChild(professionsHeading)

    local hint = AceGUI:Create("Label")
    hint:SetText("|cff9d9d9d" .. L["Saved automatically when they link a profession in chat and you open it, or set them here."] .. "|r")
    hint:SetFullWidth(true)
    card:AddChild(hint)
    AddProfessionPicker(card, targetName, Refresh)
end

local function AddHistory(scroll, container, Refresh)
    local history = GetData().inspectHistory
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(L["Recent inspect exports"])
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    scroll:AddChild(group)

    if #history == 0 then
        local empty = AceGUI:Create("Label")
        empty:SetText("|cff9d9d9d" .. L["None yet. Exports of other players show up here."] .. "|r")
        empty:SetFullWidth(true)
        group:AddChild(empty)
        return
    end

    for index, entry in ipairs(history) do
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")
        group:AddChild(row)

        AddClassIcon(row, entry.class, 26)
        local label = AceGUI:Create("Label")
        label:SetText(("%s\n|cff9d9d9d%s %s  %s|r"):format(ClassColored(entry.name, entry.class), tostring(entry.level),
            ClassName(entry.class), Ago(entry.time)))
        label:SetWidth(250)
        row:AddChild(label)

        AddButton(row, L["Copy"], 70, function() Env.ShowTextWindow(entry.name, entry.json) end)
        if Env.SimImport and Env.SimImport.Load then
            AddButton(row, L["Gear"], 70, function()
                local ok, err = Env.SimImport.Load(entry.json)
                if ok then container:SelectTab(Env.SimImport.tab.value) else Env.FeaturePrint(err) end
            end)
        end
        if Env.ShowTalentWindow and Env.Encoding then
            AddButton(row, L["Talents"], 80, function()
                local data = Env.Encoding.DecodeJSON(entry.json)
                local talents = type(data) == "table" and data.talents or ""
                Env.ShowTalentWindow(L["Talents of %s"]:format(entry.name), talents, entry.class)
            end)
        end
        AddButton(row, L["Delete"], 84, function()
            table.remove(history, index)
            Refresh()
        end)
    end

    local clear = AceGUI:Create("Button")
    clear:SetText(L["Clear all"])
    clear:SetWidth(120)
    clear:SetCallback("OnClick", function()
        wipe(history)
        Refresh()
    end)
    group:AddChild(clear)
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Refresh()
        container:SelectTab(Inspect.tab.value)
    end

    AddTargetCard(scroll, Refresh)
    AddHistory(scroll, container, Refresh)
end

Inspect.tab = { value = "inspect", text = L["Inspect"], Create = CreateTab }

function Inspect:Initialize(db, addon)
    self.db = db
    self.addon = addon
    LoadKnownProfessions()
    AddUnitMenuEntries()
    Env.RegisterFeatureEvent("TRADE_SKILL_SHOW", OnTradeSkillShow)
    Env.RegisterFeatureEvent("TRADE_SKILL_LIST_UPDATE", OnTradeSkillShow)
end

Env.AddExportHook({
    After = function(json, character, isInspect)
        if isInspect and Inspect.db then AddToHistory(json, character) end
    end,
})

Inspect.AddToHistory = AddToHistory
Inspect.AddClassIcon = AddClassIcon
Inspect.ClassColored = ClassColored
Inspect.ClassName = ClassName

Env.InspectFeature = Inspect
Env.RegisterFeature(Inspect)
