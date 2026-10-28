-- SavedDataManager.lua
-- Handles all functionality related to saving, loading, and managing character data
--
-- This module contains:
-- - Character data saving and loading functionality
-- - Auto-save configuration and throttling
-- - Saved character list management
-- - Database interaction for persistent storage
-- - Chat command handlers for saved data operations

local addonName, Env = ...
local L = Env.L

local SavedDataManager = {}
Env.SavedDataManager = SavedDataManager

-- Constants
local AUTO_SAVE_DELAY = 1 -- seconds after the last change event before auto-saving
local pendingAutoSave

-- Default configuration for saved data
SavedDataManager.defaults = {
    savedCharacters = {}, -- Table to store exported character data
    maxSavedCharacters = 20, -- Maximum number of characters to keep
    autoSaveEnabled = true, -- Enable automatic saving on character changes
    showAutoSaveMessages = false, -- Show messages when auto-saving
}

-- Initialize the SavedDataManager with a database reference
function SavedDataManager:Initialize(db, addon)
    self.db = db
    self.addon = addon -- Reference to the main addon for Print functionality
end

-- Save character data to the database
function SavedDataManager:SaveCharacterData(characterData, characterName, isAutoSave)
    if not characterName then
        characterName = UnitName("player") .. "-" .. GetRealmName()
    end

    local timestamp = time()
    local savedEntry = {
        name = characterName,
        data = characterData,
        timestamp = timestamp,
        dateString = date("%Y-%m-%d %H:%M:%S", timestamp)
    }
    
    -- Initialize if doesn't exist
    if not self.db.profile.savedCharacters then
        self.db.profile.savedCharacters = {}
    end
    
    -- Check if character already exists and remove old entry
    local existingIndex = nil
    for i, entry in ipairs(self.db.profile.savedCharacters) do
        if entry.name == characterName then
            existingIndex = i
            break
        end
    end
    
    if existingIndex then
        -- Remove existing entry
        table.remove(self.db.profile.savedCharacters, existingIndex)
        if not isAutoSave then
            self.addon:Print(L["Updated saved character data for %s"]:format(characterName))
        end
    else
        if not isAutoSave then
            self.addon:Print(L["Character data saved for %s"]:format(characterName))
        end
    end
    
    -- Add new entry at the beginning
    table.insert(self.db.profile.savedCharacters, 1, savedEntry)
    
    -- Limit the number of saved characters
    local maxSaved = self.db.profile.maxSavedCharacters or 10
    while #self.db.profile.savedCharacters > maxSaved do
        table.remove(self.db.profile.savedCharacters)
    end
    
    return savedEntry
end

-- Get all saved characters
function SavedDataManager:GetSavedCharacters()
    return self.db.profile.savedCharacters or {}
end

-- Delete a saved character by index
function SavedDataManager:DeleteSavedCharacter(index)
    local savedChars = self:GetSavedCharacters()
    if savedChars[index] then
        local deletedChar = table.remove(savedChars, index)
        self.addon:Print(L["Deleted saved character: %s"]:format(deletedChar.name))
        return true
    end
    return false
end

-- List all saved characters
function SavedDataManager:ListSavedCharacters()
    local savedChars = self:GetSavedCharacters()
    if #savedChars == 0 then
        self.addon:Print(L["No saved characters found."])
        return
    end
    
    self.addon:Print(L["Saved Characters:"])
    for i, charData in ipairs(savedChars) do
        self.addon:Print(L["%d. %s (saved: %s)"]:format(i, charData.name, charData.dateString))
    end
end

-- Delete saved character command handler
function SavedDataManager:DeleteSavedCharacterCommand(input)
    local index = tonumber(input)
    if not index then
        self.addon:Print(L["Usage: /wsedelete <number> - Use /wselist to see available characters"])
        return
    end
    
    if self:DeleteSavedCharacter(index) then
        -- Success message already printed in DeleteSavedCharacter
    else
        self.addon:Print(L["No saved character found at index %d"]:format(index))
    end
end

-- Toggle auto-save functionality
function SavedDataManager:ToggleAutoSave(input)
    if input and input:trim() ~= "" then
        local option = input:trim():lower()
        if option == "on" or option == "enable" or option == "true" then
            self.db.profile.autoSaveEnabled = true
            self.addon:Print(L["Auto-save enabled. Character will be saved automatically on equipment, talent, level, and other changes."])
        elseif option == "off" or option == "disable" or option == "false" then
            self.db.profile.autoSaveEnabled = false
            self.addon:Print(L["Auto-save disabled. Use /wse export to manually save character data."])
        elseif option == "messages" then
            self.db.profile.showAutoSaveMessages = not self.db.profile.showAutoSaveMessages
            self.addon:Print(self.db.profile.showAutoSaveMessages and L["Auto-save messages enabled."] or L["Auto-save messages disabled."])
        else
            self.addon:Print(L["Usage: /wseautosave [on|off|messages]"])
        end
    else
        -- Toggle auto-save
        self.db.profile.autoSaveEnabled = not self.db.profile.autoSaveEnabled
        self.addon:Print(self.db.profile.autoSaveEnabled and L["Auto-save enabled."] or L["Auto-save disabled."])
    end
end

-- Check if auto-save is enabled
function SavedDataManager:IsAutoSaveEnabled()
    return self.db.profile.autoSaveEnabled
end

-- Check if auto-save messages should be shown
function SavedDataManager:ShouldShowAutoSaveMessages()
    return self.db.profile.showAutoSaveMessages
end

-- Handle character change events for auto-saving
function SavedDataManager:OnCharacterChanged(event)
    -- Check if auto-save is enabled
    if not self:IsAutoSaveEnabled() then
        return
    end
    
    -- Debounce: one change often fires several events in a row (e.g. a talent point and a talent
    -- update), so save once after the last of them, when the client data is up to date.
    if pendingAutoSave then
        pendingAutoSave:Cancel()
    end
    pendingAutoSave = C_Timer.NewTimer(AUTO_SAVE_DELAY, function()
        pendingAutoSave = nil
        self:AutoSave(event)
    end)
end

-- Save the player's current character data
function SavedDataManager:AutoSave(event)
    -- Only auto-save for supported classes
    local character = Env.CreateCharacter()
    character:SetUnit("player")
    if not table.contains(Env.Flavor.classes, character.class) then
        return
    end
    
    -- Generate and auto-save character data
    character:FillForExport(false)
    if character.level < GetMaxPlayerLevel() then
        return
    end

    local LibParse = LibStub("LibParse")
    local jsonExport = LibParse:JSONEncode(character)
    self:SaveCharacterData(jsonExport, nil, true) -- Pass true for isAutoSave
    
    -- Optional: Print a subtle message for auto-saves
    if self:ShouldShowAutoSaveMessages() then
        self.addon:Print(L["Character auto-saved due to %s"]:format(event))
    end
end

return SavedDataManager
