local Env = select(2, ...)

local L = Env.L

local UI = {}

local WINDOW_WIDTH, WINDOW_HEIGHT = 700, 500
local ICON = "Interface\\AddOns\\wowsimsexporter\\Skins\\wowsims.tga"

local _window
local _copyDialog
local _outputGenerator
local _outputGeneratorBags

---A movable window with the game's standard frame, a title, a status line and a close button,
---closed by the Escape key. Widgets go in `frame.content`, which covers the whole window and sits
---above the frame's own art.
---@param name string Global name of the frame.
local function CreateWindowFrame(name, width, height, strata)
    local frame = CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata(strata)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, name)

    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints()
    content:SetFrameLevel(frame:GetFrameLevel() + 5)
    frame.content = content

    frame.title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)

    frame.status = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("BOTTOMLEFT", 14, 10)
    frame.status:SetPoint("BOTTOMRIGHT", -14, 10)
    frame.status:SetJustifyH("LEFT")

    return frame
end

local function CreateLabel(parent, font, text)
    local label = parent:CreateFontString(nil, "ARTWORK", font)
    label:SetJustifyH("LEFT")
    if text then label:SetText(text) end
    return label
end

local function CreateButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

---A checkbox with its label to the right.
---@param onChange fun(value: boolean)
local function CreateCheckbox(parent, text, onChange)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetScript("OnClick", function(self)
        onChange(self:GetChecked() and true or false)
    end)
    checkbox.label = CreateLabel(checkbox, "GameFontHighlight", text)
    checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    return checkbox
end

local function ShowCopyDialog(text)
    if not _copyDialog then
        local dialog = CreateWindowFrame("WSECopyDialog", 400, 100, "FULLSCREEN_DIALOG")
        dialog.title:SetText(L["WSE Copy Dialog"])
        dialog.status:SetText(L["Use CTRL+C to copy link"])

        local editBox = CreateFrame("EditBox", nil, dialog.content, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", 22, -38)
        editBox:SetPoint("RIGHT", -18, 0)
        editBox:SetHeight(20)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
        -- The box only holds the link to copy: undo any typing.
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText(dialog.text)
                self:HighlightText()
            end
        end)
        dialog.editBox = editBox

        _copyDialog = dialog
    end

    _copyDialog.text = text
    _copyDialog.editBox:SetText(text)
    _copyDialog:Show()
    _copyDialog.editBox:SetFocus()
    _copyDialog.editBox:HighlightText()
end

---The Main tab: the sim links, the export buttons and the box holding the output.
local function CreateMainTab(window, parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    local icon = tab:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(32, 32)
    icon:SetPoint("TOP", 0, -2)

    local info = CreateLabel(tab, "GameFontHighlight")
    info:SetPoint("TOPLEFT", 0, -38)
    info:SetPoint("RIGHT")

    -- Clickable lines that open the copy dialog for a link.
    tab.links = {}
    for i = 1, 2 do
        local link = CreateFrame("Button", nil, tab)
        link:SetHeight(18)
        link.label = CreateLabel(link, "GameFontNormal")
        link.label:SetPoint("LEFT")
        link:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
        link:SetScript("OnLeave", function(self) self.label:SetTextColor(1, 0.82, 0) end)
        link:SetScript("OnClick", function(self) ShowCopyDialog(self.url) end)
        tab.links[i] = link
    end

    local generateButton = CreateButton(tab, L["Generate Data (Equipped Only)"], 300, function()
        if _outputGenerator then
            UI:SetOutput(_outputGenerator())
        end
    end)
    local bagsButton = CreateButton(tab, L["Batch: Export Bag Items"], 300, function()
        if _outputGeneratorBags then
            UI:SetOutput(_outputGeneratorBags())
        end
    end)
    bagsButton:SetPoint("LEFT", generateButton, "RIGHT", 8, 0)
    tab.generateButton, tab.bagsButton = generateButton, bagsButton

    local boxLabel = CreateLabel(tab, "GameFontNormal", L["Copy and paste into the websites importer!"])

    local box = CreateFrame("Frame", nil, tab)
    box:SetPoint("BOTTOMRIGHT", 0, 0)
    local background = box:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(WINDOW_WIDTH - 70)
    editBox:SetScript("OnEscapePressed", function() window:Hide() end)
    if ScrollingEdit_OnCursorChanged then
        -- Keep the cursor in view as it moves.
        editBox:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
        editBox:SetScript("OnTextChanged", function(self) ScrollingEdit_OnTextChanged(self, scroll) end)
        editBox:SetScript("OnUpdate", function(self, elapsed) ScrollingEdit_OnUpdate(self, elapsed, scroll) end)
    end
    scroll:SetScrollChild(editBox)
    -- Clicking anywhere in the box puts the cursor in it.
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    window.editBox = editBox

    local exportWidgets = { generateButton, bagsButton, boxLabel, box }

    ---Show the export controls for a supported class, or the list of supported classes.
    ---@param classIsSupported boolean
    ---@param simLink string
    function tab:Update(classIsSupported, simLink)
        for _, widget in ipairs(tab.links) do widget:Hide() end
        for _, widget in ipairs(exportWidgets) do widget:SetShown(classIsSupported) end

        if not classIsSupported then
            local classNames = {}
            for i, class in ipairs(Env.Flavor.classes) do
                classNames[i] = LOCALIZED_CLASS_NAMES_MALE[class:upper()] or class
            end
            info:SetText(L["Your character's class is currently unsupported. The supported classes are currently:"] .. "\n" ..
                table.concat(classNames, "\n"))
            return
        end

        info:SetText(L["MAIN_INSTRUCTIONS"])

        local links = {}
        if simLink and Env.Flavor.cnPrelink and Env.LOCALE == "zhCN" then
            links[1] = { L["International site - click to copy: %s"]:format(simLink), simLink }
            links[2] = { L["China site - click to copy: %s"]:format(Env.Flavor.cnPrelink), Env.Flavor.cnPrelink }
        elseif simLink then
            links[1] = { L["Click to copy: %s"]:format(simLink), simLink }
        end

        -- Stack the links, buttons and output box under the instructions.
        local previous = info
        for i, link in ipairs(links) do
            local widget = tab.links[i]
            widget.label:SetText(link[1])
            widget.url = link[2]
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
            widget:SetPoint("RIGHT", tab)
            widget:Show()
            previous = widget
        end
        generateButton:ClearAllPoints()
        generateButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -10)
        boxLabel:ClearAllPoints()
        boxLabel:SetPoint("TOPLEFT", generateButton, "BOTTOMLEFT", 0, -12)
        box:ClearAllPoints()
        box:SetPoint("TOPLEFT", boxLabel, "BOTTOMLEFT", 0, -4)
        box:SetPoint("BOTTOMRIGHT", tab)
    end

    return tab
end

---The Saved Data tab: auto-save settings and the saved characters, each with Export and Delete.
local function CreateSavedDataTab(window, parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    local scroll = CreateFrame("ScrollFrame", nil, tab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -26, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(WINDOW_WIDTH - 70, 1)
    scroll:SetScrollChild(child)

    local function SetSetting(key, value, enabledMessage, disabledMessage)
        if not Env.SavedDataManager.db then return end
        Env.SavedDataManager.db.profile[key] = value
        DEFAULT_CHAT_FRAME:AddMessage("[WowSimsExporter] " .. (value and enabledMessage or disabledMessage))
    end

    local heading = CreateLabel(child, "GameFontNormalLarge", L["Saved Character Data Management"])
    heading:SetPoint("TOPLEFT", 0, -4)

    local settingsHeading = CreateLabel(child, "GameFontNormal", L["Auto-Save Settings"])
    settingsHeading:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -14)

    local autoSaveCheckbox = CreateCheckbox(child, L["Enable Auto-Save"], function(value)
        SetSetting("autoSaveEnabled", value, L["Auto-save enabled."], L["Auto-save disabled."])
    end)
    autoSaveCheckbox:SetPoint("TOPLEFT", settingsHeading, "BOTTOMLEFT", 0, -4)

    local messagesCheckbox = CreateCheckbox(child, L["Show Auto-Save Messages"], function(value)
        SetSetting("showAutoSaveMessages", value, L["Auto-save messages enabled."], L["Auto-save messages disabled."])
    end)
    messagesCheckbox:SetPoint("LEFT", autoSaveCheckbox.label, "RIGHT", 40, 0)

    local savedHeading = CreateLabel(child, "GameFontNormal", L["Saved Characters"])
    savedHeading:SetPoint("TOPLEFT", autoSaveCheckbox, "BOTTOMLEFT", 0, -14)

    local emptyLabel = CreateLabel(child, "GameFontHighlight", L["No saved characters found."])
    emptyLabel:SetPoint("TOPLEFT", savedHeading, "BOTTOMLEFT", 0, -8)

    local ROW_HEIGHT = 30
    tab.rows = {}

    local function GetRow(i)
        if tab.rows[i] then return tab.rows[i] end
        local row = CreateFrame("Frame", nil, child)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", savedHeading, "BOTTOMLEFT", 0, -4 - (i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", child)
        row.name = CreateLabel(row, "GameFontNormal")
        row.name:SetPoint("LEFT", 4, 0)
        row.date = CreateLabel(row, "GameFontHighlightSmall")
        row.date:SetPoint("LEFT", 250, 0)
        row.deleteButton = CreateButton(row, L["Delete"], 80, function(self)
            Env.SavedDataManager:DeleteSavedCharacter(self:GetParent().index)
            tab:Refresh()
        end)
        row.deleteButton:SetPoint("RIGHT", -4, 0)
        row.exportButton = CreateButton(row, L["Export"], 80, function(self)
            local data = self:GetParent().data
            window:SelectTab("main")
            UI:SetOutput(data)
        end)
        row.exportButton:SetPoint("RIGHT", row.deleteButton, "LEFT", -4, 0)
        tab.rows[i] = row
        return row
    end

    function tab:Refresh()
        local profile = Env.SavedDataManager.db and Env.SavedDataManager.db.profile or {}
        autoSaveCheckbox:SetChecked(profile.autoSaveEnabled or false)
        messagesCheckbox:SetChecked(profile.showAutoSaveMessages or false)

        local savedChars = Env.SavedDataManager:GetSavedCharacters()
        emptyLabel:SetShown(#savedChars == 0)
        for i, charData in ipairs(savedChars) do
            local row = GetRow(i)
            row.index = i
            row.data = charData.data
            row.name:SetText(charData.name)
            row.date:SetText(L["Saved: %s"]:format(charData.dateString))
            row:Show()
        end
        for i = #savedChars + 1, #tab.rows do
            tab.rows[i]:Hide()
        end
        child:SetHeight(120 + math.max(#savedChars, 1) * ROW_HEIGHT)
    end

    return tab
end

local function GetWindow()
    if _window then return _window end

    -- Named `WowSimsExporter` so that it's in UISpecialFrames and the Escape key closes it.
    local window = CreateWindowFrame("WowSimsExporter", WINDOW_WIDTH, WINDOW_HEIGHT, "DIALOG")
    window.title:SetText("WowSimsExporter " .. Env.VERSION)
    window:SetScript("OnHide", function(self)
        self.editBox:ClearFocus()
    end)

    local tabArea = CreateFrame("Frame", nil, window.content)
    tabArea:SetPoint("TOPLEFT", 16, -62)
    tabArea:SetPoint("BOTTOMRIGHT", -16, 30)

    local tabs = {
        main = CreateMainTab(window, tabArea),
        saveddata = CreateSavedDataTab(window, tabArea),
    }
    window.tabs = tabs

    window.tabButtons = {}
    local previous
    for _, tab in ipairs({ { "main", L["Main"] }, { "saveddata", L["Saved Data"] } }) do
        local button = CreateButton(window.content, tab[2], 120, function() window:SelectTab(tab[1]) end)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else
            button:SetPoint("TOPLEFT", 14, -30)
        end
        window.tabButtons[tab[1]] = button
        previous = button
    end

    ---@param name "main"|"saveddata"
    function window:SelectTab(name)
        for key, tab in pairs(tabs) do
            tab:SetShown(key == name)
            if key == name then
                self.tabButtons[key]:LockHighlight()
            else
                self.tabButtons[key]:UnlockHighlight()
            end
        end
        if name == "saveddata" then
            tabs.saveddata:Refresh()
        end
    end

    _window = window
    return window
end

---Create/show the main window.
---@param classIsSupported boolean If false then show class not supported info instead of export stuff.
---@param simLink string The URL to the (class/spec) sim to display.
function UI:CreateMainWindow(classIsSupported, simLink)
    local window = GetWindow()
    if window:IsShown() then return end

    window.tabs.main:Update(classIsSupported, simLink)
    window.editBox:SetText("")
    window.status:SetText(L["Click 'Generate Data' to generate exportable data"])
    window:SelectTab("main")
    window:Show()
end

---Create a button on the character panel that will call the provided function
---@param onClick fun()
function UI:CreateCharacterPanelButton(onClick, showInitially)

    local openButton = CreateFrame("Button", "WSECharacterFrameButton", CharacterFrame, "UIPanelButtonTemplate")
    openButton:SetSize(30, 30)


    -- statement to hide the button
    if showInitially then
        openButton:Show()
    else
        openButton:Hide()
    end

    local point, relativeTo, relativePoint, x, y = unpack(Env.Flavor.characterButtonPoint)
    openButton:SetPoint(point, _G[relativeTo], relativePoint, x, y)

    openButton:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)
    openButton:SetText("WowSims")
    openButton:SetSize(openButton:GetTextWidth() + 15, openButton:GetTextHeight() + 10)
    openButton:SetScript("OnClick", function(self)
        onClick()
    end)
    openButton:RegisterForClicks("AnyUp")

    -- tooltip!
    openButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Open WowSimsExporter"])
        GameTooltip:Show()
    end)
    openButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function UI:CreateInspectButton(onClick)
    if not InspectFrame then return end

    local inspectButton = CreateFrame("Button", "WSEInspectButton", InspectFrame, "UIPanelButtonTemplate")
    inspectButton:SetSize(50, 24)
    inspectButton:SetText("WowSims")
    inspectButton:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", 0, 0)
    inspectButton:SetSize(inspectButton:GetTextWidth() + 15, inspectButton:GetTextHeight() + 10)
    inspectButton:SetScript("OnClick", function()
        onClick()
    end)
end

---Sets string in textbox.
---@param outputString string
function UI:SetOutput(outputString)
    if not _window or not _window:IsShown() then return end
    _window.editBox:SetText(outputString)
    _window.editBox:HighlightText()
    _window.editBox:SetFocus()
    _window.status:SetText(L["Data Generated!"])
end

---Set the function that is used to get the output value when
---pressing the character export button.
---@param func fun():string
function UI:SetOutputGenerator(func)
    _outputGenerator = func
end

---Set the function that is used to get the output value when
---pressing the bag items export button.
---@param func fun():string
function UI:SetOutputGeneratorBags(func)
    _outputGeneratorBags = func
end

Env.UI = UI
