-- Author      : generalwrex (Natop)
-- Create Date : 1/28/2022 9:30:08 AM
--
-- Update Date : 2023-04-16 Riotdog-GehennasEU: v2.5 - exporting bag items for bulk sim, fixes use of legacy APIs in libs and corrects link order (LibStub must come first).
-- Update Date : 2024-02-04 coolmodi(FelixPflaum) v2.6 - Added rune exporting and split the addon for classic/wotlk
-- Update Date : 2024-02-04 generalwrex (Natop on Old Blanchy) v2.6 - Minor fixes and version change
-- Update Date : 2025-07-03 Polynomix & generalwrex v2.7
-- Update Date : 2025-07-06 RaiN v2.8 - Added support for saving exported characters data in SavedVariables and added auto-save functionality.

local addonName, Env = ...

local LibParse = LibStub("LibParse")

local WowSimsExporter = LibStub("AceAddon-3.0"):NewAddon("WowSimsExporter", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = Env.SavedDataManager.defaults,
}

local options = {
    name = addonName,
    handler = WowSimsExporter,
    type = "group",
    args = {
        openExporterButton = {
            type = "execute",
            name = "Open Exporter Window",
            desc = "Opens the exporter window",
            func = function() WowSimsExporter:OpenWindow() end
        },
    },
}

function WowSimsExporter:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WSEDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter", "WowSimsExporter")

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter_Profiles", "Profiles", "WowSimsExporter")

    -- Initialize the SavedDataManager
    Env.SavedDataManager:Initialize(self.db, self)

    self:RegisterChatCommand("wse", "OpenWindow")
    self:RegisterChatCommand("wowsimsexporter", "OpenWindow")
    self:RegisterChatCommand("wsexporter", "OpenWindow")

    -- Register events for automatic character saving
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnCharacterChanged")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED", "OnCharacterChanged") 
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnCharacterChanged")
    self:RegisterEvent("ENCHANT_SPELL_COMPLETED", "OnCharacterChanged")
    if Env.IS_CLASSIC_ERA_SOD then
        self:RegisterEvent("RUNE_UPDATED", "OnCharacterChanged")
    end
    if not Env.IS_CLASSIC_ERA then
        self:RegisterEvent("GLYPH_ADDED", "OnCharacterChanged")
        self:RegisterEvent("GLYPH_REMOVED", "OnCharacterChanged")
        self:RegisterEvent("GLYPH_UPDATED", "OnCharacterChanged")
    end

    Env.UI:CreateCharacterPanelButton(options.args.openExporterButton.func)

    self:Print(addonName .. " " .. Env.VERSION .. " Initialized. Commands:\n" ..
        "/wse - Open window\n" ..
        "/wse export - Export character (auto-saves)\n" ..
        "Auto-save: " .. (self.db.profile.autoSaveEnabled and "ENABLED" or "DISABLED") .. "\n" ..
        "\124cff008000Credits go to " .. Env.AUTHORS.."\124r")

    if not Env.IS_CLIENT_SUPPORTED then
        self:Print("WARNING: Sim does not support your game version! Supported versions are:\n" ..
            table.concat(Env.supportedClientNames, "\n"))
    end
end

function WowSimsExporter:OpenWindow(input)
    if not input or input:trim() == "" then
        self:CreateWindow()
    elseif (input == "export") then
        self:CreateWindow(true)
    elseif (input == "options") then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
end

local function GenerateOutput(character, exportBags)
    character:FillForExport()
    local jsonExport = LibParse:JSONEncode(character)
    
    if character.level == GetMaxPlayerLevel() then
        -- Automatically save to database using SavedDataManager
        Env.SavedDataManager:SaveCharacterData(jsonExport)
    end

    return jsonExport
end

local function GenerateOutputBags()
    local equipmentSpecBags = Env.CreateEquipmentSpec()
    equipmentSpecBags:FillFromBagItems()
    DEFAULT_CHAT_FRAME:AddMessage(("[|cffFFFF00WowSimsExporter|r] Exported %d items from bags."):format(#
        equipmentSpecBags.items))
    return LibParse:JSONEncode(equipmentSpecBags)
end

function WowSimsExporter:CreateWindow(generate)
    local character = Env.CreateCharacter()
    character:SetUnit("player")
    local classIsSupported = table.contains(Env.supportedClasses, character.class)
    local linkToSim = Env.prelink .. select(2, Env.GetSpec("player"))

    Env.UI:CreateMainWindow(classIsSupported, linkToSim)
    if not classIsSupported then return end
    if generate then Env.UI:SetOutput(GenerateOutput(character)) end
end

Env.UI:SetOutputGenerator(function()
    local character = Env.CreateCharacter()
    character:SetUnit("player")
    local output = GenerateOutput(character)
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
