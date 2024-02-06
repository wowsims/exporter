-- Author      : generalwrex (Natop on Myzrael TBC)
-- Create Date : 1/28/2022 9:30:08 AM
--
-- Update Date : 2023-04-16 Riotdog-GehennasEU: v2.5 - exporting bag items for bulk sim, fixes use of legacy APIs in libs and corrects link order (LibStub must come first).
-- Update Date : 2024-02-04 coolmodi(FelixPflaum) v2.6 - Added rune exporting and split the addon for classic/wotlk
-- Update Date : 2024-02-04 generalwrex (Natop on Old Blanchy) v2.6 - Minor fixes and version change

local Env = select(2, ...)

WowSimsExporter = LibStub("AceAddon-3.0"):NewAddon("WowSimsExporter", "AceConsole-3.0", "AceEvent-3.0")

WowSimsExporter.Character = Env.CreateCharacter()

local IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IS_CLASSIC_ERA_SOD = IS_CLASSIC_ERA and C_Engraving.IsEngravingEnabled()

Env.IS_CLASSIC_ERA = IS_CLASSIC_ERA
Env.IS_CLASSIC_ERA_SOD = IS_CLASSIC_ERA_SOD

local AceGUI = LibStub("AceGUI-3.0")
local LibParse = LibStub("LibParse")

-- Get from .toc file.
local version = GetAddOnMetadata(select(1, ...), "Version")

local defaults = {
    profile = {
    },
}

local options = {
    name = "WowSimsExporter",
    handler = WowSimsExporter,
    type = "group",
    args = {
        openExporterButton = {
            type = "execute",
            name = "Open Exporter Window",
            desc = "Opens the exporter window",
            func = function() WowSimsExporter:CreateWindow() end
        },
    },
}

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

function WowSimsExporter:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WSEDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter", "WowSimsExporter")

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WowSimsExporter_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WowSimsExporter_Profiles", "Profiles", "WowSimsExporter")

    self:RegisterChatCommand("wse", "OpenWindow")
    self:RegisterChatCommand("wowsimsexporter", "OpenWindow")
    self:RegisterChatCommand("wsexporter", "OpenWindow")

    self:Print("WowSimsExporter v" .. version .. " Initialized. use /wse For Window.")
end

-- UI
function WowSimsExporter:BuildLinks(frame, character)
    local specs         = self.specializations
    local supportedsims = self.supportedSims
    local class         = character.class
    local spec          = character.spec

    if table.contains(supportedsims, class) then
        for i, char in ipairs(specs) do
            if char and char.class == class and char.spec == spec then
                local link = WowSimsExporter.prelink .. (char.url) .. WowSimsExporter.postlink

                local l = AceGUI:Create("InteractiveLabel")
                l:SetText("Click to copy: " .. link .. "\r\n")
                l:SetFullWidth(true)
                l:SetCallback("OnClick", function()
                    WowSimsExporter:CreateCopyDialog(link)
                end)
                frame:AddChild(l)
            end
        end
    end
end

function WowSimsExporter:CreateCopyDialog(text)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("WSE Copy Dialog")
    frame:SetStatusText("Use CTRL+C to copy link")
    frame:SetLayout("Flow")
    frame:SetWidth(400)
    frame:SetHeight(100)
    frame:SetCallback(
        "OnClose",
        function(widget)
            AceGUI:Release(widget)
        end
    )

    local editbox = AceGUI:Create("EditBox")
    editbox:SetText(text)
    editbox:SetFullWidth(true)
    editbox:DisableButton(true)

    editbox:SetFocus()
    editbox:HighlightText()

    frame:AddChild(editbox)
end

function WowSimsExporter:CreateWindow(generate)
    WowSimsExporter.Character:SetUnit("player")

    local frame = AceGUI:Create("Frame")
    frame:SetCallback(
        "OnClose",
        function(widget)
            AceGUI:Release(widget)
        end
    )
    frame:SetTitle("WowSimsExporter V" .. version .. "")
    frame:SetStatusText("Click 'Generate Data' to generate exportable data")
    frame:SetLayout("Flow")


    local jsonbox = AceGUI:Create("MultiLineEditBox")
    jsonbox:SetLabel("Copy and paste into the websites importer!")
    jsonbox:SetFullWidth(true)
    jsonbox:SetFullHeight(true)
    jsonbox:DisableButton(true)

    local function l_Generate(withBags)
        jsonbox:SetText('')
        if not withBags then
            WowSimsExporter.Character:FillForExport()
            jsonbox:SetText(LibParse:JSONEncode(WowSimsExporter.Character))
        else
            local equipmentSpecBags = Env.CreateEquipmentSpec()
            equipmentSpecBags:FillFromBagItems()
            DEFAULT_CHAT_FRAME:AddMessage(("[|cffFFFF00WowSimsExporter|r] Exported %d items from bags."):format(#
                equipmentSpecBags.items))
            jsonbox:SetText(LibParse:JSONEncode(equipmentSpecBags))
        end
        jsonbox:HighlightText()
        jsonbox:SetFocus()

        frame:SetStatusText("Data Generated!")
    end

    if generate then l_Generate() end

    local button = AceGUI:Create("Button")
    button:SetText("Generate Data (Equipped Only)")
    button:SetWidth(300)
    button:SetCallback("OnClick", function()
        l_Generate(false)
    end)

    local extraButton = AceGUI:Create("Button")
    extraButton:SetText("Batch: Export Bag Items")
    extraButton:SetWidth(300)
    extraButton:SetCallback("OnClick", function()
        l_Generate(true)
    end)

    local icon = AceGUI:Create("Icon")
    icon:SetImage("Interface\\AddOns\\wowsimsexporter\\Skins\\wowsims.tga")
    icon:SetImageSize(32, 32)
    icon:SetFullWidth(true)

    local label = AceGUI:Create("Label")
    label:SetFullWidth(true)
    label:SetText([[

To upload your character to the simuator, click on the url below that leads to the simuator website.

You will find an Import button on the top right of the simulator named "Import". Click that and select the "Addon" tab, paste the data
into the provided box and click "Import"

]])

    if not table.contains(self.supportedSims, self.Character.class) then
        frame:AddChild(icon)

        local l1 = AceGUI:Create("Heading")
        l1:SetText("")
        --l1:SetColor(255,0,0)
        l1:SetFullWidth(true)
        frame:AddChild(l1)


        local l = AceGUI:Create("Label")
        l:SetText("Your characters class is currently unsupported. The supported classes are currently;\n" ..
            table.concat(self.supportedSims, "\n"))
        --l:SetColor(255,0,0)
        l:SetFullWidth(true)
        frame:AddChild(l)
    else
        frame:AddChild(icon)
        frame:AddChild(label)
        WowSimsExporter:BuildLinks(frame, self.Character)
        frame:AddChild(button)
        frame:AddChild(extraButton)
        frame:AddChild(jsonbox)
    end
end

function WowSimsExporter:OnEnable()
end

function WowSimsExporter:OnDisable()
end

function WowSimsExporter:isGearChangeSet(info)
    return self.db.profile.updateGearChange
end

function WowSimsExporter:setGearChange(info, value)
    self.db.profile.updateGearChange = value
end
