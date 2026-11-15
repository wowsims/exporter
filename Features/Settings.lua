-- About tab, the minimap button, and the general WowSims settings.
--
-- Settings live in the game's options (Options > AddOns > WowSimsExporter); each feature adds its own
-- group with Env.AddOptions. The About tab links there.
--
-- The minimap button's state is kept in WSEDB.global.minimap = { hide = false, angle = 225 }.

local addonName, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local Settings = {}

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Skins\\wowsims"
local DEFAULT_ANGLE = 225 -- degrees around the minimap, bottom left

local LINKS = {
    { label = L["Report a bug or suggest something (GitHub)"], url = "https://github.com/wowsims/exporter/issues" },
    { label = L["Chat with us (WowSims Discord)"], url = "https://discord.gg/N9ZgAMXQ3p" },
    { label = L["The simulator"], url = "https://www.wowsims.com" },
}

local button

---@return table
function Settings:GetMinimapData()
    local data = Env.GetOrCreateTable(self.db.global, "minimap")
    if data.angle == nil then data.angle = DEFAULT_ANGLE end
    return data
end

---@param show boolean
function Settings:SetMinimapButtonShown(show)
    self:GetMinimapData().hide = not show
    if button then button:SetShown(show) end
end

---Open the addon's page in the game's options.
function Settings:OpenOptions()
    if self.addon and self.addon.OpenOptions then self.addon:OpenOptions() end
end

---Open the WowSims window on a tab.
---@param value string Tab value, e.g. "upgrades".
function Settings:OpenTab(value)
    if not (Env.UI and Env.UI.tabGroup) and self.addon then
        self.addon:OpenWindow("")
    end
    if Env.UI and Env.UI.tabGroup then Env.UI.tabGroup:SelectTab(value) end
end

-- Minimap button --------------------------------------------------------------------------------

local function UpdateButtonPosition()
    local angle = math.rad(Settings:GetMinimapData().angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

---Right-click menu: quick actions. Uses the retail client's menu API (WoW Forever runs on it);
---without it, right-click opens the settings instead.
local function ShowMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        Settings:OpenOptions()
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("WowSims")
        root:CreateButton(L["Export my character"], function() Settings.addon:OpenWindow("export") end)
        if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
            root:CreateButton(L["Export my target"], function() Settings.addon:OpenWindow("inspect") end)
        end
        root:CreateDivider()
        local tabs = {
            { "upgrades", L["Upgrades"] },
            { "gearsets", L["Gear Sets"] },
            { "statweights", L["Stat Weights"] },
            { "inspect", L["Inspect"] },
            { "group", L["Group"] },
            { "simimport", L["Import"] },
        }
        for _, tab in ipairs(tabs) do
            root:CreateButton(tab[2], function() Settings:OpenTab(tab[1]) end)
        end
        root:CreateDivider()
        root:CreateButton(L["Settings"], function() Settings:OpenOptions() end)
        root:CreateButton(L["Hide this button"], function()
            Settings:SetMinimapButtonShown(false)
            Env.FeaturePrint(L["Minimap button hidden. Turn it back on in the addon settings."])
        end)
    end)
end

local function CreateMinimapButton()
    if button or not Minimap then return end

    button = CreateFrame("Button", "WowSimsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture(ICON)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            ShowMenu(self)
        else
            Settings.addon:OpenWindow()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            Settings:GetMinimapData().angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            UpdateButtonPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("WowSims")
        GameTooltip:AddLine(L["Click to open. Right-click for quick actions. Drag to move."], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateButtonPosition()
end

-- Settings page: general options ----------------------------------------------------------------

Env.AddOptions("general", 10, L["General"], {
    minimap = Env.Toggle(1, L["Show minimap button"], nil,
        function() return not Settings:GetMinimapData().hide end,
        function(value) Settings:SetMinimapButtonShown(value) end),
    tour = {
        type = "execute", order = 10, name = L["Replay the tour"],
        func = function() if Env.Tutorial then Env.Tutorial:Start() end end,
    },
})

-- About tab -------------------------------------------------------------------------------------

local function AddLink(container, link)
    local label = AceGUI:Create("InteractiveLabel")
    label:SetText("|cff00ccff" .. link.label .. "|r  |cff9d9d9d" .. link.url .. "|r")
    label:SetFullWidth(true)
    label:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    label:SetCallback("OnClick", function() Env.ShowTextWindow(link.label, link.url) end)
    container:AddChild(label)
end

local function AddButton(container, text, width, onClick)
    local widget = AceGUI:Create("Button")
    widget:SetText(text)
    widget:SetWidth(width)
    widget:SetCallback("OnClick", onClick)
    container:AddChild(widget)
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local header = AceGUI:Create("SimpleGroup")
    header:SetFullWidth(true)
    header:SetLayout("Flow")
    scroll:AddChild(header)
    local icon = AceGUI:Create("Icon")
    icon:SetImage(ICON)
    icon:SetImageSize(48, 48)
    icon:SetWidth(60)
    header:AddChild(icon)
    local title = AceGUI:Create("Label")
    title:SetFontObject(GameFontNormalLarge)
    title:SetText("WowSims " .. tostring(Env.VERSION) .. "\n|cffffffff" .. L["for WoW Forever"] .. "|r")
    title:SetWidth(400)
    header:AddChild(title)

    Env.AddHint(scroll, L["WowSims connects the game to the simulator at wowsims.com: export your character, compare gear with your stat weights, find upgrades, inspect other players and share builds with your group."])

    local settings = Env.AddSection(scroll, L["Settings"])
    Env.AddHint(settings, L["Turn WowSims features on or off, and choose what exports include, in the game's options (Options > AddOns > WowSimsExporter)."])
    AddButton(settings, L["Open addon settings"], 180, function() Settings:OpenOptions() end)
    if Env.Tutorial then
        AddButton(settings, L["Replay the tour"], 160, function() Env.Tutorial:Start() end)
    end

    local help = Env.AddSection(scroll, L["Help and feedback"])
    Env.AddHint(help, L["Click a link to copy it."])
    for _, link in ipairs(LINKS) do AddLink(help, link) end

    local commands = Env.AddSection(scroll, L["Commands"])
    Env.AddHint(commands, table.concat({
        "|cffffd100/wowsims|r, |cffffd100/wse|r  " .. L["open this window"],
        "|cffffd100/wse export|r  " .. L["export your character"],
        "|cffffd100/wse inspect|r  " .. L["export your target"],
        "|cffffd100/wse options|r  " .. L["open the addon settings"],
        "|cffffd100/wowsims tour|r  " .. L["replay the tour"],
        "|cffffd100/wowsims version|r  " .. L["who in your guild or group has WowSims"],
    }, "\n"))

    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local authors = getMetadata and getMetadata(addonName, "Author")
    if authors and authors ~= "" then
        local credits = Env.AddSection(scroll, L["Made by"])
        Env.AddHint(credits, authors)
    end
end

Settings.tab = { value = "about", text = L["About"], Create = CreateTab }

function Settings:Initialize(db, addon)
    self.db = db
    self.addon = addon
    CreateMinimapButton()
    if button then button:SetShown(not self:GetMinimapData().hide) end
end

Env.Settings = Settings
Env.RegisterFeature(Settings)
