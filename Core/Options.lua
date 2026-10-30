-- The addon's page in the game's options, in place of AceConfig.

local addonName, Env = ...
local L = Env.L

local function AddTooltip(widget, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

---Add the options page.
---@param openWindow fun() Opens the exporter window.
---@param getShowButton fun():boolean Whether the character pane button is shown.
---@param setShowButton fun(value: boolean)
---@return table panel
---@return number|nil categoryID The Settings category, on clients that have the Settings API.
function Env.CreateOptionsPanel(openWindow, getShowButton, setShowButton)
    local panel = CreateFrame("Frame")
    panel.name = addonName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName)

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetText(L["Open Exporter Window"])
    openButton:SetSize(openButton:GetTextWidth() + 40, 24)
    openButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    openButton:SetScript("OnClick", function() openWindow() end)
    AddTooltip(openButton, L["Opens the exporter window"])

    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", openButton, "BOTTOMLEFT", -4, -12)
    checkbox:SetScript("OnClick", function(self)
        setShowButton(self:GetChecked() and true or false)
    end)
    AddTooltip(checkbox, L["Show or hide the WowSims icon button on the character sheet."])

    local checkboxLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    checkboxLabel:SetText(L["Show Character Pane Button"])

    panel:SetScript("OnShow", function()
        checkbox:SetChecked(getShowButton())
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
        return panel, category:GetID()
    end
    InterfaceOptions_AddCategory(panel)
    return panel
end
