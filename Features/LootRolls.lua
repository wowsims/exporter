-- Loot roll hints (Forever): when a group loot roll starts, score the item with your active stat
-- weights. If it's an upgrade, show "WowSims: +3.2%" on the roll window and print a chat line.
--
-- Settings in WSEDB.global.lootRolls = { onFrame = true, inChat = true }.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local L = Env.L

local LootRolls = {}

local MIN_PERCENT = 0.5 -- smaller changes aren't worth calling an upgrade
local RETRIES = 6       -- item data may still be loading when the roll starts

---@return table options { onFrame, inChat }
function LootRolls:GetOptions()
    local options = Env.GetOrCreateTable(self.db.global, "lootRolls")
    if options.onFrame == nil then options.onFrame = true end
    if options.inChat == nil then options.inChat = true end
    return options
end

---The roll windows on screen: GroupLootFrame1-4 on older clients, GroupLootContainer's frames on
---the retail client.
local function RollFrames()
    local frames = {}
    for i = 1, 4 do
        local frame = _G["GroupLootFrame" .. i]
        if frame then table.insert(frames, frame) end
    end
    if GroupLootContainer and type(GroupLootContainer.rollFrames) == "table" then
        for _, frame in pairs(GroupLootContainer.rollFrames) do
            if type(frame) == "table" then table.insert(frames, frame) end
        end
    end
    return frames
end

local function ShowOnFrame(rollID, text)
    for _, frame in ipairs(RollFrames()) do
        if frame.rollID == rollID and frame.CreateFontString then
            if not frame.wowsimsText then
                frame.wowsimsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                frame.wowsimsText:SetPoint("BOTTOM", frame, "TOP", 0, 2)
                -- Roll windows are reused for later rolls; clear the hint with the window.
                frame:HookScript("OnHide", function(self) self.wowsimsText:SetText("") end)
            end
            frame.wowsimsText:SetText(text)
            return
        end
    end
end

---Whether the player may need on the roll (false for gear their class can't use). Unknown: true.
local function CanNeed(rollID)
    if not GetLootRollItemInfo then return true end
    local canNeed = select(6, GetLootRollItemInfo(rollID))
    return canNeed ~= false
end

local function Check(rollID, triesLeft)
    local statWeights = Env.StatWeights
    if not statWeights or not statWeights:GetActiveScale() then return end
    local link = GetLootRollItemLink and GetLootRollItemLink(rollID)
    if not link then return end

    local percent = statWeights:GetUpgradePercent(link)
    if percent == nil then
        -- Not equippable, or the item's stats haven't loaded yet: try again shortly.
        local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        if triesLeft > 0 and not (getInfo and getInfo(link)) then
            C_Timer.After(0.5, function() Check(rollID, triesLeft - 1) end)
        end
        return
    end
    if percent < MIN_PERCENT or not CanNeed(rollID) then return end

    local options = LootRolls:GetOptions()
    local text = ("|cff1eff00WowSims: +%.1f%%|r"):format(percent)
    if options.onFrame then ShowOnFrame(rollID, text) end
    if options.inChat then
        Env.FeaturePrint(L["%s is a %.1f%% upgrade for you."]:format(link, percent))
    end
end

function LootRolls:Initialize(db)
    self.db = db
    Env.RegisterFeatureEvent("START_LOOT_ROLL", function(_, rollID)
        local options = LootRolls:GetOptions()
        if not (options.onFrame or options.inChat) or not rollID then return end
        -- The roll window is set up after the event; check a moment later.
        C_Timer.After(0.2, function() Check(rollID, RETRIES) end)
    end)
end

Env.AddOptions("lootRolls", 30, L["Loot rolls"], {
    onFrame = Env.Toggle(1, L["Show upgrade hints on loot roll windows"], L["Uses your active stat weights."],
        function() return LootRolls:GetOptions().onFrame end,
        function(value) LootRolls:GetOptions().onFrame = value end),
    inChat = Env.Toggle(2, L["Also print upgrade hints in chat"], nil,
        function() return LootRolls:GetOptions().inChat end,
        function(value) LootRolls:GetOptions().inChat = value end),
})

Env.LootRolls = LootRolls
Env.RegisterFeature(LootRolls)
