-- Paper doll (Forever): show a set of items like the character sheet, slots around a model of
-- the player wearing them. Used by the Import tab.
--
-- The doll is a plain frame placed inside an AceGUI SimpleGroup. AceGUI reuses widgets, so a
-- doll is put back in a pool when its group hides, and the next view takes it from there.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

-- How far the camera sits from the model; above 1 pulls back so the head isn't cut off.
local CAMERA_DISTANCE = 1.6

local SLOT_SIZE = 37
local SLOT_STEP = 44
local DOLL_HEIGHT = 8 * SLOT_STEP + SLOT_SIZE + 24

local leftSlots = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local rightSlots = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
local bottomSlots = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot" }

local statusLines = {
    equipped = { L["You're wearing this"], 0.12, 1, 0 },
    bags = { L["In your bags"], 1, 0.82, 0 },
    bank = { L["In your bank"], 1, 0.82, 0 },
    missing = { L["Not in your bags"], 1, 0.3, 0.3 },
}

local pool = {}

---Slot ID and empty-slot texture of a slot name, nil if the client has no such slot.
local function SlotInfo(slotName)
    local ok, slotId, texture = pcall(GetInventorySlotInfo, slotName)
    if ok and slotId then return slotId, texture end
    return nil
end

local function CreateSlotButton(doll, slotName)
    local slotId, emptyTexture = SlotInfo(slotName)
    if not slotId then return nil end

    local button = CreateFrame("Button", nil, doll)
    button:SetSize(SLOT_SIZE, SLOT_SIZE)
    button.slotId, button.emptyTexture = slotId, emptyTexture
    button.slotLabel = _G[slotName:upper()] or slotName

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    button.border:SetAllPoints()
    button.bag = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.bag:SetSize(14, 14)
    button.bag:SetPoint("BOTTOMRIGHT", -1, 1)
    button.bag:SetTexture("Interface\\Buttons\\Button-Backpack-Up")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.hyperlink then
            GameTooltip:SetHyperlink(self.hyperlink)
            local status = statusLines[self.where]
            if status then GameTooltip:AddLine(status[1], status[2], status[3], status[4]) end
        else
            GameTooltip:SetText(self.slotLabel)
            GameTooltip:AddLine(L["Nothing in this slot"], 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function CreateDoll()
    local doll = CreateFrame("Frame", nil, UIParent)
    doll:SetHeight(DOLL_HEIGHT)
    doll.buttons = {}

    for i, slotName in ipairs(leftSlots) do
        local button = CreateSlotButton(doll, slotName)
        if button then
            button:SetPoint("TOPLEFT", 8, -4 - (i - 1) * SLOT_STEP)
            table.insert(doll.buttons, button)
        end
    end
    for i, slotName in ipairs(rightSlots) do
        local button = CreateSlotButton(doll, slotName)
        if button then
            button:SetPoint("TOPRIGHT", -8, -4 - (i - 1) * SLOT_STEP)
            table.insert(doll.buttons, button)
        end
    end
    local bottom = {}
    for _, slotName in ipairs(bottomSlots) do
        local button = CreateSlotButton(doll, slotName)
        if button then
            table.insert(bottom, button)
            table.insert(doll.buttons, button)
        end
    end
    for i, button in ipairs(bottom) do
        button:SetPoint("BOTTOM", (i - (#bottom + 1) / 2) * SLOT_STEP, 4)
    end

    local model = CreateFrame("DressUpModel", nil, doll)
    model:SetPoint("TOPLEFT", SLOT_SIZE + 24, -4)
    model:SetPoint("BOTTOMRIGHT", -(SLOT_SIZE + 24), SLOT_SIZE + 12)
    doll.model = model

    -- Drag to turn the model, mouse wheel to zoom, like the dressing room.
    model.zoom = 1
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseDown", function(self)
        self.turning = true
        self.lastX = GetCursorPosition()
    end)
    model:SetScript("OnMouseUp", function(self) self.turning = false end)
    model:SetScript("OnHide", function(self) self.turning = false end)
    model:SetScript("OnUpdate", function(self)
        if not self.turning then return end
        local x = GetCursorPosition()
        self:SetFacing((self:GetFacing() or 0) + (x - (self.lastX or x)) * 0.02)
        self.lastX = x
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.min(1.6, math.max(0.6, self.zoom - delta * 0.1))
        pcall(self.SetCamDistanceScale, self, self.zoom * CAMERA_DISTANCE)
    end)
    return doll
end

local function AcquireDoll()
    for _, doll in ipairs(pool) do
        if not doll.inUse then return doll end
    end
    local doll = CreateDoll()
    table.insert(pool, doll)
    return doll
end

local function ReleaseDoll(doll)
    doll.inUse = false
    doll:Hide()
    doll:ClearAllPoints()
    doll:SetParent(UIParent)
end

---Fill a doll's slots and dress its model.
---@param rows table[] { slotId, id, where = "equipped"|"bags"|"missing", link }
local function UpdateDoll(doll, rows)
    local rowBySlot = {}
    for _, row in ipairs(rows) do rowBySlot[row.slotId] = row end
    local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon

    for _, button in ipairs(doll.buttons) do
        local row = rowBySlot[button.slotId]
        if row then
            button.hyperlink = row.link and (row.link:match("|H(item:[^|]+)|h") or row.link) or ("item:" .. row.id)
            button.where = row.where
            button.icon:SetTexture(getIcon(row.id) or 134400)
            local missing = row.where == "missing"
            button.icon:SetDesaturated(missing)
            if missing then button.icon:SetVertexColor(1, 0.4, 0.4) else button.icon:SetVertexColor(1, 1, 1) end
            local color = not missing and Env.GetItemQualityColor(row.id)
            if color then
                button.border:SetVertexColor(color.r, color.g, color.b)
                button.border:Show()
            else
                button.border:Hide()
            end
            button.bag:SetShown(row.where == "bags")
        else
            button.hyperlink, button.where = nil, nil
            button.icon:SetTexture(button.emptyTexture)
            button.icon:SetDesaturated(false)
            button.icon:SetVertexColor(1, 1, 1)
            button.border:Hide()
            button.bag:Hide()
        end
    end

    -- Dress the model in every imported item, owned or not, to preview the whole set.
    local function Dress()
        pcall(function()
            local model = doll.model
            model:SetUnit("player")
            -- Full body, camera pulled back, centered.
            if model.SetPortraitZoom then model:SetPortraitZoom(0) end
            if model.SetCamDistanceScale then model:SetCamDistanceScale((model.zoom or 1) * CAMERA_DISTANCE) end
            if model.SetPosition then model:SetPosition(0, 0, 0) end
            model:Undress()
            for _, row in ipairs(rows) do
                doll.model:TryOn(row.link or ("item:" .. row.id))
            end
        end)
    end
    Dress()
    -- The model loads in the background; dress it again once it has.
    C_Timer.After(0.3, Dress)
end

---Add a paper doll of items to an AceGUI container.
---@param container table AceGUI container (Flow layout).
---@param rows table[] { slotId, id, where, link } as the Import tab matches them.
function Env.AddPaperDoll(container, rows)
    local holder = AceGUI:Create("SimpleGroup")
    holder:SetFullWidth(true)
    -- The doll isn't an AceGUI child, so stop AceGUI from shrinking the group to its
    -- (empty) children; otherwise the scroll frame thinks the tab is shorter than it is.
    holder.noAutoHeight = true
    holder:SetLayout("Fill")
    holder:SetHeight(DOLL_HEIGHT)
    container:AddChild(holder)

    local doll = AcquireDoll()
    doll.inUse = true
    doll:SetParent(holder.content)
    doll:ClearAllPoints()
    doll:SetAllPoints(holder.content)
    doll:Show()
    UpdateDoll(doll, rows)

    -- Give the doll back when this group is hidden or reused.
    holder.frame.wowsimsDoll = doll
    holder.frame.wowsimsHolder = holder
    if not holder.frame.wowsimsDollHooked then
        holder.frame.wowsimsDollHooked = true
        holder.frame:HookScript("OnHide", function(frame)
            if frame.wowsimsDoll then
                ReleaseDoll(frame.wowsimsDoll)
                frame.wowsimsDoll = nil
                -- AceGUI reuses this group elsewhere; let it size itself again there.
                if frame.wowsimsHolder then frame.wowsimsHolder.noAutoHeight = nil end
            end
        end)
    end
end
