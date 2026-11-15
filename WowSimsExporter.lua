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
        showStartupMessage = {
            type = "toggle",
            name = L["Show Startup Message"],
            desc = L["Show or hide the initialization message in chat when the addon loads."],
            get = function(info)
                if WowSimsExporter.db.profile.showStartupMessage == nil then
                    return true
                end
                return WowSimsExporter.db.profile.showStartupMessage
            end,
            set = function(info, value)
                WowSimsExporter.db.profile.showStartupMessage = value
            end,
            order = 3,
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

    -- WoW Forever: every WowSims feature's settings, under the exporter's own.
    if Env.AddFeatureOptions then Env.AddFeatureOptions(options) end
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter", options)
    self.optionsFrame, self.optionsCategoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter", "WowSimsExporter")

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter_Profiles", L["Profiles"], "WowSimsExporter")

    -- Initialize the SavedDataManager
    Env.SavedDataManager:Initialize(self.db, self)

    -- Initialize the features under Features/. One failing doesn't stop the rest of the addon.
    for _, feature in ipairs(Env.Features or {}) do
        if feature.Initialize then
            local ok, err = pcall(feature.Initialize, feature, self.db, self)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end

    self:RegisterChatCommand("wse", "OpenWindow")
    self:RegisterChatCommand("wowsimsexporter", "OpenWindow")
    self:RegisterChatCommand("wsexporter", "OpenWindow")
    if Env.IS_FOREVER then
        self:RegisterChatCommand("wowsims", "OpenWindow")
        -- The saved data commands the addon's messages tell people to use.
        self:RegisterChatCommand("wselist", function() Env.SavedDataManager:ListSavedCharacters() end)
        self:RegisterChatCommand("wsedelete", function(input) Env.SavedDataManager:DeleteSavedCharacterCommand(input) end)
        self:RegisterChatCommand("wseautosave", function(input) Env.SavedDataManager:ToggleAutoSave(input) end)
    end

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

    if Env.Flavor.supportsInspect and Env.IS_FOREVER then
        local function CreateInspectButton()
            Env.UI:CreateInspectButton(function ()
                -- The unit the inspect window shows, in case InspectUnit wasn't what opened it.
                local unit = (InspectFrame and InspectFrame.unit) or Env.inspectUnit
                if not unit then return end
                Env.inspectUnit = unit
                -- Their items may still be loading; wait so the export isn't missing gear.
                self:WaitForInspectItems(unit, function() self:CreateWindow(true, true) end)
            end)
        end
        -- Also create the button whenever the inspect window's addon loads, however it was loaded.
        if Env.RegisterFeatureEvent then
            Env.RegisterFeatureEvent("ADDON_LOADED", function(_, loadedAddon)
                if loadedAddon == "Blizzard_InspectUI" then
                    C_Timer.After(0.1, CreateInspectButton)
                end
            end)
        end
        if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
            -- Another addon loaded the inspect window before us.
            CreateInspectButton()
        else
            -- pcall: AceHook errors if a client lacks the function, which would stop the addon loading.
            -- /wse inspect works without these hooks.
            pcall(self.SecureHook, self, "InspectFrame_LoadUI", function()
                C_Timer.After(0.1, function()
                    CreateInspectButton()
                    self:Unhook("InspectFrame_LoadUI")
                end)
            end)
        end
        pcall(self.SecureHook, self, "InspectUnit", function (unit)
            Env.inspectUnit=unit
            self:RequestInspectProfessions(unit)
        end)
        function self:OnCommReceived(prefix, text, sender, name)
            self:handleAddonMessage(prefix, text, sender, name)
        end
        self:RegisterComm("WSEProfession")
    elseif Env.Flavor.supportsInspect then
        -- Other game versions: the original inspect button, unchanged.
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

    if self.db.profile.showStartupMessage ~= false then
        self:Print(L["%s %s Initialized. Commands:"]:format(addonName, Env.VERSION) .. "\n" ..
            L["/wse - Open window"] .. "\n" ..
            L["/wse export - Export character (auto-saves)"] .. "\n" ..
            ((Env.IS_FOREVER and Env.Flavor.supportsInspect) and (L["/wse inspect - Export your target"] .. "\n") or "") ..
            L["Auto-save: %s"]:format(self.db.profile.autoSaveEnabled and L["ENABLED"] or L["DISABLED"]) .. "\n" ..
            "\124cff008000" .. L["Credits go to %s"]:format(Env.AUTHORS) .. "\124r")
    end

    if not Env.IS_CLIENT_SUPPORTED then
        self:Print(L["WARNING: Sim does not support your game version! Supported versions are:"] .. "\n" ..
            table.concat(Env.supportedClientNames, "\n"))
    end
end

---Ask an inspected player's exporter for their professions. Players without the addon don't answer.
---@param unit string
function WowSimsExporter:RequestInspectProfessions(unit)
    local name, realm = UnitName(unit)
    if not name or Env.profInspectTable[name] ~= nil then return end
    local target = (realm and realm ~= "") and (name .. "-" .. realm) or name
    self:SendCommMessage("WSEProfession", "request", "WHISPER", target)
end

local INSPECT_TIMEOUT = 5 -- seconds to wait for the client's inspect data

---Inspect the target (or another unit) without the inspect window, then call onReady once its
---data is in.
---@param onReady fun()
---@param unit string|nil Defaults to "target".
function WowSimsExporter:RequestInspect(onReady, unit)
    unit = unit or "target"
    if not Env.Flavor.supportsInspect then
        self:Print(L["Exporting other players isn't supported for this game version yet."])
        return
    end
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        self:Print(L["Target a player first."])
        return
    end
    if UnitIsUnit(unit, "player") then
        self:Print(L["That's you. Use /wse export for your own character."])
        return
    end
    if InCombatLockdown() then
        self:Print(L["You can't inspect players in combat. Try again after the fight."])
        return
    end
    if not CanInspect(unit) then
        self:Print(L["Can't inspect %s right now. Get closer and try again."]:format(UnitName(unit) or "?"))
        return
    end

    Env.inspectUnit = unit
    self:RequestInspectProfessions(unit)
    self.pendingInspect = { guid = UnitGUID(unit), onReady = onReady }
    self:RegisterEvent("INSPECT_READY", "OnInspectReady")
    if self.inspectTimer then self.inspectTimer:Cancel() end
    self.inspectTimer = C_Timer.NewTimer(INSPECT_TIMEOUT, function()
        self.inspectTimer = nil
        if self.pendingInspect then
            self.pendingInspect = nil
            self:UnregisterEvent("INSPECT_READY")
            self:Print(L["Inspect timed out. Get closer to the player and try again."])
        end
    end)
    NotifyInspect(unit)
end

function WowSimsExporter:OnInspectReady(event, guid)
    local pending = self.pendingInspect
    if not pending or guid ~= pending.guid then return end
    self.pendingInspect = nil
    self:UnregisterEvent("INSPECT_READY")
    if self.inspectTimer then
        self.inspectTimer:Cancel()
        self.inspectTimer = nil
    end
    if UnitGUID(Env.inspectUnit) ~= guid then
        self:Print(L["Your target changed while inspecting. Target the player again and retry."])
        return
    end
    -- Wait for their items to load, which also gives the professions reply a moment to arrive.
    self:WaitForInspectItems(Env.inspectUnit, pending.onReady)
end

local ITEM_WAIT_STEP = 0.3 -- seconds between checks
local ITEM_WAIT_TRIES = 10 -- checks before exporting with what has loaded

---Count equipped slots of a unit that have an item but no item link yet.
---The client gives an inspected player's item links only once each item's data has loaded.
---@param unit string
---@return integer missing
local function CountUnloadedItems(unit)
    local missing = 0
    for slotId = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
        local itemId = GetInventoryItemID(unit, slotId)
        if itemId and not GetInventoryItemLink(unit, slotId) then
            missing = missing + 1
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemId)
            end
        end
    end
    return missing
end

---Call done once every equipped item of the unit has a link, or after ITEM_WAIT_TRIES checks.
---@param unit string
---@param done fun()
function WowSimsExporter:WaitForInspectItems(unit, done)
    if not GetInventoryItemID then
        C_Timer.After(0.5, done)
        return
    end
    local tries = 0
    local function Check()
        tries = tries + 1
        local missing = CountUnloadedItems(unit)
        if missing == 0 and tries > 1 then
            done()
        elseif tries >= ITEM_WAIT_TRIES then
            if missing > 0 then
                self:Print(L["%d items didn't load in time and are left out. Try again in a moment."]:format(missing))
            end
            done()
        else
            C_Timer.After(ITEM_WAIT_STEP, Check)
        end
    end
    Check()
end

---Print what the client gives for the inspected player, to check inspect exports work.
function WowSimsExporter:PrintInspectDebug()
    local unit = Env.inspectUnit
    local name = UnitName(unit) or "?"
    local _, class = UnitClass(unit)
    self:Print(("Inspect debug: %s, %s level %s"):format(name, tostring(class), tostring(UnitLevel(unit))))

    if Env.DescribeForeverInspectTalents then
        for _, line in ipairs(Env.DescribeForeverInspectTalents()) do
            self:Print("  " .. line)
        end
    else
        local talents = Env.Flavor.CreateTalentString(true)
        self:Print("  Talent string: " .. (talents ~= "" and talents or "(empty)"))
    end

    local spec, simPath = Env.GetSpec(unit)
    self:Print(("  Spec: %s, sim page: %s"):format(spec ~= "" and spec or "(not found)", simPath ~= "" and simPath or "(none)"))

    local gearCount, withId, enchanted = 0, 0, 0
    local firstLink
    for slotId = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
        if GetInventoryItemID and GetInventoryItemID(unit, slotId) then
            withId = withId + 1
        end
        local link = GetInventoryItemLink(unit, slotId)
        if link then
            gearCount = gearCount + 1
            firstLink = firstLink or link
            local enchant = link:match("item:%d+:(%d*)")
            if enchant and enchant ~= "" and enchant ~= "0" then
                enchanted = enchanted + 1
            end
        end
    end
    self:Print(("  Gear: %d slots with an item, %d with a link, %d enchanted"):format(withId, gearCount, enchanted))
    if firstLink then
        -- Raw link, pipes escaped so chat shows the format instead of a clickable link.
        self:Print("  Link format: " .. firstLink:gsub("|", "||"))
    end

    local professions = Env.profInspectTable[name]
    if professions and #professions > 0 then
        local parts = {}
        for _, prof in ipairs(professions) do
            table.insert(parts, prof.name .. " " .. prof.level)
        end
        self:Print("  Professions: " .. table.concat(parts, ", "))
    else
        self:Print("  Professions: none received (they need WowSimsExporter installed)")
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
        -- Inspect lookups use the name without the realm.
        if Env.IS_FOREVER and Ambiguate then name = Ambiguate(name, "short") end
        Env.AddInspectedProfessions(name, entry)
    end
end

function WowSimsExporter:OpenWindow(input)
    if not Env.IS_FOREVER then
        -- Other game versions: the original commands, unchanged.
        if not input or input:trim() == "" then
            self:CreateWindow(false, false)
        elseif (input == "export") then
            self:CreateWindow(true, false)
        elseif (input == "options") then
            self:OpenOptions()
        end
        return
    end
    input = input and input:trim():lower() or ""
    if input == "" then
        self:CreateWindow(false, false)
    elseif (input == "export") then
        self:CreateWindow(true, false)
    elseif (input == "inspect") then
        self:RequestInspect(function() self:CreateWindow(true, true) end)
    elseif (input == "tour") then
        if Env.Tutorial then Env.Tutorial:Start() end
    elseif (input == "version") then
        if Env.VersionCheck then Env.VersionCheck:PrintSeen() end
    elseif (input == "inspectdebug") then
        self:RequestInspect(function() self:PrintInspectDebug() end)
    elseif (input == "options") then
        self:OpenOptions()
    end
end

---Open the addon's page in the game's options.
function WowSimsExporter:OpenOptions()
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        Settings.OpenToCategory(self.optionsCategoryID or self.optionsFrame.name)
    end
end

local function GenerateOutput(character, isInspect, exportBags, noSave)
    character:FillForExport(isInspect)
    if Env.RunExportHooks then Env.RunExportHooks("Before", character, isInspect) end
    local jsonExport = Env.JSONEncode(character)

    if not isInspect and not noSave and (character.level == GetMaxPlayerLevel() or Env.Flavor.saveBelowMaxLevel) then
        -- Automatically save to database using SavedDataManager
        Env.SavedDataManager:SaveCharacterData(jsonExport)
    end
    if Env.RunExportHooks then Env.RunExportHooks("After", jsonExport, character, isInspect) end

    return jsonExport
end

---Export the player, or the inspected player, the same way the export window does.
---@param isInspect boolean
---@param noSave boolean|nil Don't auto-save it (exports sent to other players).
---@return string|nil json nil if the class isn't supported by the sim.
function WowSimsExporter:BuildExport(isInspect, noSave)
    local character = Env.CreateCharacter()
    character:SetUnit(isInspect and Env.inspectUnit or "player")
    if not table.contains(Env.Flavor.classes, character.class) then return nil end
    return GenerateOutput(character, isInspect, nil, noSave)
end

local function GenerateOutputBags()
    local equipmentSpecBags = Env.CreateEquipmentSpec()
    local includedBank = equipmentSpecBags:FillFromBagItems()
    local message
    if includedBank then
        message = L["Exported %d items from bags and bank."]:format(#equipmentSpecBags.items)
    elseif Env.GetOpenBankContainers then
        message = L["Exported %d items from bags."]:format(#equipmentSpecBags.items) .. " "
            .. L["Open your bank first to include bank items."]
    else
        message = L["Exported %d items from bags."]:format(#equipmentSpecBags.items)
    end
    DEFAULT_CHAT_FRAME:AddMessage("[|cffFFFF00WowSimsExporter|r] " .. message)
    return Env.JSONEncode(equipmentSpecBags)
end

function WowSimsExporter:CreateWindow(generate, isInspect)
    if Env.IS_FOREVER and isInspect and (not Env.inspectUnit or (UnitExists and not UnitExists(Env.inspectUnit))) then
        self:Print(L["No inspected player. Target a player and type /wse inspect."])
        return
    end
    local character = Env.CreateCharacter()
    local unit = isInspect and Env.inspectUnit or "player"
    local simPath = character:SetUnit(unit)
    local classIsSupported = table.contains(Env.Flavor.classes, character.class)
    local linkToSim = Env.Flavor.prelink .. simPath
    local cnLinkToSim = Env.Flavor.cnPrelink and Env.Flavor.cnPrelink .. simPath

    Env.UI:CreateMainWindow(classIsSupported, linkToSim, cnLinkToSim)
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
