-- Talent view (Forever): show a talent string as the player's class trees, like the talent window.
-- Opened with Env.ShowTalentWindow(title, talentString, classFile) from the Import, Gear Sets and Inspect tabs.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local ICON_SIZE = 32
local CELL_WIDTH = 44
local TREE_PADDING = 30 -- InlineGroup borders and insets around a tree's cells

---One talent cell: icon with "rank/max" under it, greyed out without points, spell tooltip on hover.
local function AddTalentIcon(container, cell)
    local icon = AceGUI:Create("Icon")
    icon:SetImage(cell.icon)
    icon:SetImageSize(ICON_SIZE, ICON_SIZE)
    icon:SetWidth(CELL_WIDTH)
    icon:SetLabel(cell.rank > 0 and ("|cff1eff00%d/%d|r"):format(cell.rank, cell.maxRank)
        or ("|cff808080%d/%d|r"):format(cell.rank, cell.maxRank))
    if icon.image then
        icon.image:SetDesaturated(cell.rank == 0)
        icon.image:SetVertexColor(1, 1, 1)
    end
    Env.SetIconBorder(icon, cell.rank > 0 and { r = 0.12, g = 1, b = 0 } or nil)
    icon:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
        if cell.spellID then
            GameTooltip:SetSpellByID(cell.spellID)
        else
            GameTooltip:SetText(cell.name or "")
        end
        GameTooltip:AddLine(L["Rank %d/%d"]:format(cell.rank, cell.maxRank), 1, 0.82, 0)
        GameTooltip:Show()
    end)
    icon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    container:AddChild(icon)
    return icon
end

-- Prerequisite lines are drawn on the tree group's frame. AceGUI frames are pooled and shared
-- with other addons, so the lines are hidden whenever that frame hides (when it's released).
local function GetLinePool(frame)
    if not frame.wowsimsLines then
        frame.wowsimsLines = {}
        frame:HookScript("OnHide", function(self)
            for _, line in ipairs(self.wowsimsLines) do line:Hide() end
        end)
    end
    for _, line in ipairs(frame.wowsimsLines) do line:Hide() end
    return frame.wowsimsLines
end

---Draw a line from a prerequisite talent down (or across) to the talent that needs it.
---Lines are anchored to the icons, so they follow the layout.
local function DrawPrereqLine(pool, used, frame, fromIcon, toIcon, sameRow, met)
    if not frame.CreateLine then return used end
    used = used + 1
    local line = pool[used]
    if not line then
        line = frame:CreateLine(nil, "ARTWORK")
        line:SetThickness(3)
        pool[used] = line
    end
    if sameRow then
        line:SetStartPoint("RIGHT", fromIcon.image, 0, 0)
        line:SetEndPoint("LEFT", toIcon.image, 0, 0)
    else
        line:SetStartPoint("BOTTOM", fromIcon.frame, 0, 2)
        line:SetEndPoint("TOP", toIcon.image, 0, 0)
    end
    if met then
        line:SetColorTexture(1, 0.82, 0, 0.9)
    else
        line:SetColorTexture(0.5, 0.5, 0.5, 0.7)
    end
    line:Show()
    return used
end

local function AddBlank(container)
    local blank = AceGUI:Create("Label")
    blank:SetText(" ")
    blank:SetWidth(CELL_WIDTH)
    container:AddChild(blank)
end

---Add a talent string's trees to a container, side by side.
---@param container table AceGUI container with a Flow layout.
---@param talentString string
---@param classFile string|nil The build's class, e.g. "MAGE"; the player's class if nil.
function Env.AddTalentTrees(container, talentString, classFile)
    local layout, err = Env.GetForeverTalentLayout and Env.GetForeverTalentLayout(talentString, classFile)
    if not layout then
        local label = AceGUI:Create("Label")
        label:SetText(err or L["Talents can't be shown on this client."])
        label:SetFullWidth(true)
        container:AddChild(label)
        return
    end

    for _, tree in ipairs(layout) do
        local points = 0
        local byPosition = {}
        for _, cell in ipairs(tree.cells) do
            points = points + cell.rank
            byPosition[cell.row .. ":" .. cell.column] = cell
        end

        local group = AceGUI:Create("InlineGroup")
        group:SetTitle(("%s  |cffffffff%d|r"):format(tree.name, points))
        -- A fixed width that fits exactly one row of the tree, so trees sit side by side.
        group:SetWidth(tree.columns * CELL_WIDTH + TREE_PADDING)
        group:SetLayout("List")
        container:AddChild(group)

        -- One group per talent row, so the grid never wraps out of line.
        local icons = {}
        for row = 1, tree.rows do
            local rowGroup = AceGUI:Create("SimpleGroup")
            rowGroup:SetFullWidth(true)
            rowGroup:SetLayout("Flow")
            group:AddChild(rowGroup)
            for column = 1, tree.columns do
                local cell = byPosition[row .. ":" .. column]
                if cell then
                    icons[row .. ":" .. column] = AddTalentIcon(rowGroup, cell)
                else
                    AddBlank(rowGroup)
                end
            end
        end

        -- Arrows from prerequisites: gold once the prerequisite has all its points.
        local pool = GetLinePool(group.content)
        local used = 0
        for _, cell in ipairs(tree.cells) do
            if cell.prereqRow and cell.prereqColumn then
                local key = cell.prereqRow .. ":" .. cell.prereqColumn
                local fromIcon, toIcon = icons[key], icons[cell.row .. ":" .. cell.column]
                local prereq = byPosition[key]
                if fromIcon and toIcon and prereq then
                    used = DrawPrereqLine(pool, used, group.content, fromIcon, toIcon,
                        cell.prereqRow == cell.row, prereq.rank >= prereq.maxRank)
                end
            end
        end
    end
end

---Open a window showing a talent string as trees.
---@param title string
---@param talentString string
---@param classFile string|nil The build's class, e.g. "MAGE"; the player's class if nil.
function Env.ShowTalentWindow(title, talentString, classFile)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(title)
    frame:SetStatusText(talentString)
    if Env.MakeOpaque then Env.MakeOpaque(frame) end
    frame:SetLayout("Fill")
    -- Wide enough for three 4-column trees side by side.
    frame:SetWidth(3 * (4 * CELL_WIDTH + TREE_PADDING) + 90)
    frame:SetHeight(600)
    Env.SetMinSize(frame, 3 * (4 * CELL_WIDTH + TREE_PADDING) + 90, 360)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    frame:AddChild(scroll)
    Env.AddTalentTrees(scroll, talentString, classFile)
    -- Lay out again once the window has its final size, or the first layout can wrap the trees.
    C_Timer.After(0, function()
        if scroll.frame:IsShown() then
            scroll:DoLayout()
            frame:DoLayout()
        end
    end)
end
