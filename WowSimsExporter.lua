-- Author      : generalwrex (Natop)
-- Create Date : 1/28/2022 9:30:08 AM
--
-- Update Date : 2023-04-16 Riotdog-GehennasEU: v2.5 - exporting bag items for bulk sim, fixes use of legacy APIs in libs and corrects link order (LibStub must come first).
-- Update Date : 2024-02-04 coolmodi(FelixPflaum) v2.6 - Added rune exporting and split the addon for classic/wotlk
-- Update Date : 2024-02-04 generalwrex (Natop on Old Blanchy) v2.6 - Minor fixes and version change
-- Update Date : 2025-07-03 Polynomix & generalwrex v2.7
-- Update Date : 2025-07-06 RaiN v2.8 - Added support for saving exported characters data in SavedVariables and added auto-save functionality.
-- Update Date : 2026-08-01 generalwrex - Added option to toggle the character pane button, changed button to wowsims icon

local addonName, Env = ...

local LibParse = LibStub("LibParse")
local L = Env.L

local WowSimsExporter = LibStub("AceAddon-3.0"):NewAddon("WowSimsExporter", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")

local defaults = {
    profile = Env.SavedDataManager.defaults,
}

-- Events on every client that mean the character changed; flavors add their own.
local characterChangedEvents = {
    "PLAYER_EQUIPMENT_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ENCHANT_SPELL_COMPLETED",
}

local options = {
    name = addonName,
    handler = WowSimsExporter,
    type = "group",
    args = {
        openExporterButton = {
            type = "execute",
            name = L["Open Exporter Window"],
            desc = L["Opens the exporter window"],
            func = function() WowSimsExporter:OpenWindow() end,
            order = 1,
            width = "full",
        },
        showCharacterButton = {
            type = "toggle",
            name = L["Show Character Pane Button"],
            desc = L["Show or hide the WowSims icon button on the character sheet."],
            get = function(info)
                -- Default to true
                if WowSimsExporter.db.profile.showCharacterButton == nil then
                    return true
                end
                return WowSimsExporter.db.profile.showCharacterButton
            end,
            set = function(info, value) 
                WowSimsExporter.db.profile.showCharacterButton = value
                -- show or hide
                if WSECharacterFrameButton then
                    if value then
                        WSECharacterFrameButton:Show()
                    else
                        WSECharacterFrameButton:Hide()
                    end
                end
            end,
            order = 2,
            width = "double",
        },
    },
    
}

---Register an event, skipping events the client doesn't have (registering one of those throws).
---@param event string
---@param handler string
function WowSimsExporter:RegisterEventIfValid(event, handler)
    if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then
        return
    end
    self:RegisterEvent(event, handler)
end

function WowSimsExporter:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WSEDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter", options)
    self.optionsFrame, self.optionsCategoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter", "WowSimsExporter")

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter_Profiles", L["Profiles"], "WowSimsExporter")

    -- Initialize the SavedDataManager
    Env.SavedDataManager:Initialize(self.db, self)

    self:RegisterChatCommand("wse", "OpenWindow")
    self:RegisterChatCommand("wowsimsexporter", "OpenWindow")
    self:RegisterChatCommand("wsexporter", "OpenWindow")

    -- Register events for automatic character saving
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function (event, isInitialLogin, isReloadingUI)
        if isInitialLogin then
            for _, characterEvent in ipairs(characterChangedEvents) do
                self:RegisterEventIfValid(characterEvent, "OnCharacterChanged")
            end
            for _, characterEvent in ipairs(Env.Flavor.events) do
                self:RegisterEventIfValid(characterEvent, "OnCharacterChanged")
            end
        end
    end)

    if Env.Flavor.supportsInspect then
        self:SecureHook("InspectFrame_LoadUI", function()
            C_Timer.After(0.1, function()
                Env.UI:CreateInspectButton(function ()
                    self:CreateWindow(true, true)
                end)
                self:Unhook("InspectFrame_LoadUI")
            end)
        end)
        self:SecureHook("InspectUnit", function (unit)
            Env.inspectUnit=unit
            local name = UnitName(unit)
            if Env.profInspectTable[name] == nil then
                self:SendCommMessage("WSEProfession", "request", "WHISPER", name)
            end
        end)
        function self:OnCommReceived(prefix, text, sender, name)
            self:handleAddonMessage(prefix, text, sender, name)
        end
        self:RegisterComm("WSEProfession")
    end

    local showButton = self.db.profile.showCharacterButton
    if showButton == nil then showButton = true end

    Env.UI:CreateCharacterPanelButton(options.args.openExporterButton.func, showButton)

    self:Print(L["%s %s Initialized. Commands:"]:format(addonName, Env.VERSION) .. "\n" ..
        L["/wse - Open window"] .. "\n" ..
        L["/wse export - Export character (auto-saves)"] .. "\n" ..
        L["Auto-save: %s"]:format(self.db.profile.autoSaveEnabled and L["ENABLED"] or L["DISABLED"]) .. "\n" ..
        "\124cff008000" .. L["Credits go to %s"]:format(Env.AUTHORS) .. "\124r")

    if not Env.IS_CLIENT_SUPPORTED then
        self:Print(L["WARNING: Sim does not support your game version! Supported versions are:"] .. "\n" ..
            table.concat(Env.supportedClientNames, "\n"))
    end
end

function WowSimsExporter:handleAddonMessage(prefix, text, type, name)
    if text == "request" then
        local entry = Env.CreateProfessionEntry(false)
        local msg = ""
        for _, prof in pairs(entry) do
            msg = msg..prof.name.."="..prof.level..", "
        end
        self:SendCommMessage("WSEProfession", msg, "WHISPER", name)
    else -- received professions info
        local entry = {}
        for k, v in text:gmatch("(%w+)=(%w+)") do
            table.insert(entry, {
                name = k,
                level = tonumber(v),
            })
        end
        Env.AddInspectedProfessions(name, entry)
    end
end

function WowSimsExporter:OpenWindow(input)
    if not input or input:trim() == "" then
        self:CreateWindow(false, false)
    elseif (input == "export") then
        self:CreateWindow(true, false)
    elseif (input == "options") then
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        else
            Settings.OpenToCategory(self.optionsCategoryID or self.optionsFrame.name)
        end
    end
end

local function GenerateOutput(character, isInspect, exportBags)
    character:FillForExport(isInspect)
    local jsonExport = LibParse:JSONEncode(character)
    
    if not isInspect and character.level == GetMaxPlayerLevel() then
        -- Automatically save to database using SavedDataManager
        Env.SavedDataManager:SaveCharacterData(jsonExport)
    end

    return jsonExport
end

local function GenerateOutputBags()
    local equipmentSpecBags = Env.CreateEquipmentSpec()
    equipmentSpecBags:FillFromBagItems()
    DEFAULT_CHAT_FRAME:AddMessage("[|cffFFFF00WowSimsExporter|r] " .. L["Exported %d items from bags."]:format(#
        equipmentSpecBags.items))
    return LibParse:JSONEncode(equipmentSpecBags)
end

function WowSimsExporter:CreateWindow(generate, isInspect)
    local character = Env.CreateCharacter()
    local unit = isInspect and Env.inspectUnit or "player"
    character:SetUnit(unit)
    local classIsSupported = table.contains(Env.Flavor.classes, character.class)
    local linkToSim = Env.Flavor.prelink .. select(2, Env.GetSpec("player"))

    Env.UI:CreateMainWindow(classIsSupported, linkToSim)
    if not classIsSupported then return end
    if generate then Env.UI:SetOutput(GenerateOutput(character, isInspect)) end
end

Env.UI:SetOutputGenerator(function()
    local character = Env.CreateCharacter()
    character:SetUnit("player")
    local output = GenerateOutput(character, false)
    return output
end)

Env.UI:SetOutputGeneratorBags(function()
    local character = Env.CreateCharacter()
    character:SetUnit("player")
    local output = GenerateOutputBags()
    return output
end)

-- Wrapper functions that delegate to SavedDataManager
-- All saved data functionality has been moved to SavedDataManager.lua for better organization
function WowSimsExporter:SaveCharacterData(characterData, characterName, isAutoSave)
    return Env.SavedDataManager:SaveCharacterData(characterData, characterName, isAutoSave)
end

function WowSimsExporter:OnCharacterChanged(event, ...)
    Env.SavedDataManager:OnCharacterChanged(event)
end
