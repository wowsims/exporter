-- Settings tab and the minimap button.
--
-- The minimap button's state is kept in WSEDB.global.minimap = { hide = false, angle = 225 }.
-- The other settings shown here are the existing ones in WSEDB.profile, read and written as before.

local addonName, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local Settings = {}

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Skins\\wowsims"
local DEFAULT_ANGLE = 225 -- degrees around the minimap, bottom left

local button

---@return table
function Settings:GetMinimapData()
    local data = Env.GetOrCreateTable(self.db.global, "minimap")
    if data.angle == nil then data.angle = DEFAULT_ANGLE end
    return data
end

local function UpdateButtonPosition()
    local angle = math.rad(Settings:GetMinimapData().angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CreateMinimapButton(addon)
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

    button:SetScript("OnClick", function()
        addon:OpenWindow()
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
        GameTooltip:AddLine(L["Click to open. Drag to move."], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateButtonPosition()
end

---@param show boolean
function Settings:SetMinimapButtonShown(show)
    self:GetMinimapData().hide = not show
    if button then button:SetShown(show) end
end

---@param container table
---@param label string
---@param value boolean
---@param onChange fun(value: boolean)
local function AddCheckBox(container, label, value, onChange)
    local checkBox = AceGUI:Create("CheckBox")
    checkBox:SetLabel(label)
    checkBox:SetFullWidth(true)
    checkBox:SetValue(value)
    checkBox:SetCallback("OnValueChanged", function(_, _, newValue) onChange(newValue) end)
    container:AddChild(checkBox)
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local profile = Settings.db.profile

    local general = Env.AddSection(scroll, L["General"])
    AddCheckBox(general, L["Show minimap button"], not Settings:GetMinimapData().hide, function(value)
        Settings:SetMinimapButtonShown(value)
    end)
    AddCheckBox(general, L["Show Character Pane Button"], profile.showCharacterButton ~= false, function(value)
        profile.showCharacterButton = value
        if WSECharacterFrameButton then WSECharacterFrameButton:SetShown(value) end
    end)
    AddCheckBox(general, L["Show Startup Message"], profile.showStartupMessage ~= false, function(value)
        profile.showStartupMessage = value
    end)

    if Env.StatWeights then
        local tooltips = Env.AddSection(scroll, L["Tooltips"])
        local data = Env.StatWeights:GetData()
        AddCheckBox(tooltips, L["Show WowSims scores and upgrades on item tooltips"], data.showOnTooltips, function(value)
            data.showOnTooltips = value
        end)
    end

    if #(Env.settingsSections or {}) > 0 then
        local exports = Env.AddSection(scroll, L["Exports"])
        for _, createSection in ipairs(Env.settingsSections) do
            createSection(exports)
        end
    end

    if Env.Tutorial then
        local help = Env.AddSection(scroll, L["Help"])
        local tour = AceGUI:Create("Button")
        tour:SetText(L["Replay the tour"])
        tour:SetWidth(160)
        tour:SetCallback("OnClick", function() Env.Tutorial:Start() end)
        help:AddChild(tour)
    end

    Env.AddHint(scroll, " \n" .. L["Auto-save settings are on the Saved Data tab. Open this window with /wowsims or /wse. Commands: /wowsims tour, /wowsims version."])
end

Settings.tab = { value = "settings", text = L["Settings"], Create = CreateTab }

function Settings:Initialize(db, addon)
    self.db = db
    CreateMinimapButton(addon)
    if button then button:SetShown(not self:GetMinimapData().hide) end
end

Env.Settings = Settings
Env.RegisterFeature(Settings)
