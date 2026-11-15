-- Tutorial (Forever): a short tour of the WowSims window. Offered the first time the window opens;
-- replay it from Settings or with /wowsims tour. Each step opens a tab, makes its tab button glow
-- and shows a card with Back / Next / Close.
--
-- Data: WSEDB.global.tutorialSeen = true once the offer was answered or the tour finished.

local addonName, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local L = Env.L

local Tutorial = {}

local ICON = "Interface\\AddOns\\" .. addonName .. "\\Skins\\wowsims"

-- Steps whose tab doesn't exist on this client are skipped.
local STEPS = {
    { tab = "main", title = L["Export"],
      text = L["Click Generate Data, then copy the text into the sim: open wowsims.com, pick your class, click Import at the top right and choose the Addon tab."] },
    { tab = "gearsets", title = L["Gear Sets"],
      text = L["Save what you're wearing under a name. Equip it again with one click, compare it with your current gear, or send all your sets to the sim at once."] },
    { tab = "statweights", title = L["Stat Weights"],
      text = L["In the sim, run Stat Weights and export them as Pawn, then paste them here. Item tooltips then show how much of an upgrade each item is."] },
    { tab = "upgrades", title = L["Upgrades"],
      text = L["Items in your bags that beat what you're wearing, with an Equip button, plus your gear that's missing enchants or gems."] },
    { tab = "inspect", title = L["Inspect"],
      text = L["Target a player and click Inspect and export to get their gear and talents for the sim. You can also right-click a player's portrait and choose WowSims Export to sim."] },
    { tab = "group", title = L["Group"],
      text = L["Ask your whole group or guild for their exports at once, from anywhere. Everyone with WowSims sends theirs back."] },
    { tab = "simimport", title = L["Import"],
      text = L["Paste a build from the sim to see the gear on your character, how it scores against what you wear, and its talents. Save it as a gear set when you like it."] },
    { tab = "about", title = L["About"],
      text = L["Help, links and the addon settings, where you can turn any WowSims feature off. Right-click the minimap button for quick actions. You can replay this tour here any time."] },
}

local card, glow
local steps = {} -- STEPS that exist in the current window
local index = 0

local function TabButton(value)
    local tabGroup = Env.UI and Env.UI.tabGroup
    if not tabGroup or not tabGroup.tabs then return nil end
    for _, tab in ipairs(tabGroup.tabs) do
        if tab.value == value and tab:IsShown() then return tab end
    end
end

    -- The WowSims window is on the FULLSCREEN_DIALOG strata, so the card and glow sit above it.
local function CreateGlow()
    glow = CreateFrame("Frame", nil, UIParent)
    glow:SetFrameStrata("TOOLTIP")
    local texture = glow:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(1, 0.82, 0)
    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local alpha = pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0.3)
    alpha:SetDuration(0.6)
    glow.pulse = pulse
end

local function AddButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetText(text)
    button:SetSize(width, 22)
    return button
end

local function CreateCard()
    card = CreateFrame("Frame", "WowSimsTutorialCard", UIParent, "BackdropTemplate")
    card:SetSize(340, 150)
    card:SetFrameStrata("TOOLTIP")
    card:SetClampedToScreen(true)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    card:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
    card:SetBackdropBorderColor(1, 0.82, 0)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", 12, -12)
    icon:SetTexture(ICON)

    card.title = card:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    card.title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    card.title:SetPoint("RIGHT", -12, 0)
    card.title:SetJustifyH("LEFT")

    card.step = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    card.step:SetPoint("TOPRIGHT", -12, -14)

    card.text = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    card.text:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
    card.text:SetPoint("RIGHT", -12, 0)
    card.text:SetJustifyH("LEFT")
    card.text:SetJustifyV("TOP")
    card.text:SetSpacing(2)

    card.close = AddButton(card, L["Close"], 80)
    card.close:SetPoint("BOTTOMLEFT", 12, 10)
    card.next = AddButton(card, L["Next"], 90)
    card.next:SetPoint("BOTTOMRIGHT", -12, 10)
    card.back = AddButton(card, L["Previous"], 80)
    card.back:SetPoint("RIGHT", card.next, "LEFT", -6, 0)

    card.close:SetScript("OnClick", function() Tutorial:Stop(true) end)
    card.back:SetScript("OnClick", function() Tutorial:Show(index - 1) end)
    card.next:SetScript("OnClick", function()
        if card.onNext then card.onNext() else Tutorial:Show(index + 1) end
    end)
end

local function Layout()
    -- Grow the card to fit its text.
    local height = 12 + 28 + 10 + card.text:GetStringHeight() + 14 + 22 + 10
    card:SetHeight(math.max(120, height))
end

-- Beside the WowSims window, never on top of it, so its buttons stay clickable: to the right of
-- the window if the card fits there, otherwise to the left, lined up with the tab row.
local function PlaceNear(tabButton)
    card:ClearAllPoints()
    local window = _G["WowSimsExporter"]
    if not (window and window:IsShown()) then
        card:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        return
    end
    local gap = 12
    local roomRight = (UIParent:GetRight() or 0) - (window:GetRight() or 0)
    if roomRight >= card:GetWidth() + gap then
        card:SetPoint("TOPLEFT", window, "TOPRIGHT", gap, 0)
    else
        card:SetPoint("TOPRIGHT", window, "TOPLEFT", -gap, 0)
    end
    -- Line the card up with the highlighted tab when there is one.
    if tabButton and tabButton:GetTop() and window:GetTop() then
        local offset = tabButton:GetTop() - window:GetTop()
        local point, relativeTo, relativePoint, x = card:GetPoint(1)
        card:ClearAllPoints()
        card:SetPoint(point, relativeTo, relativePoint, x, offset)
    end
end

local function ShowGlow(tabButton)
    if not glow then CreateGlow() end
    if not tabButton then
        glow:Hide()
        glow.pulse:Stop()
        return
    end
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", tabButton, "TOPLEFT", -10, 10)
    glow:SetPoint("BOTTOMRIGHT", tabButton, "BOTTOMRIGHT", 10, -10)
    glow:Show()
    glow.pulse:Play()
end

---Show tour step i (1-based); past the last step the tour ends.
function Tutorial:Show(i)
    if not card then CreateCard() end
    if i < 1 then i = 1 end
    if i > #steps then
        self:Stop(true)
        Env.FeaturePrint(L["That's the tour! Replay it from the About tab or with /wowsims tour."])
        return
    end
    index = i
    local step = steps[i]
    card:Raise()
    local tabGroup = Env.UI and Env.UI.tabGroup
    if tabGroup then tabGroup:SelectTab(step.tab) end

    card.onNext = nil
    card.title:SetText(step.title)
    card.step:SetText(("%d / %d"):format(i, #steps))
    card.text:SetText(step.text)
    card.back:SetShown(i > 1)
    card.next:SetText(i == #steps and L["Done"] or L["Next"])
    card.close:SetText(L["Close"])

    local tabButton = TabButton(step.tab)
    ShowGlow(tabButton)
    PlaceNear(tabButton)
    Layout()
    card:Show()
end

---Start the tour from the first step, opening the window if needed.
function Tutorial:Start()
    if not (Env.UI and Env.UI.tabGroup) and self.addon then
        self.addon:OpenWindow("")
    end
    wipe(steps)
    for _, step in ipairs(STEPS) do
        if TabButton(step.tab) then table.insert(steps, step) end
    end
    if #steps == 0 then return end
    self.db.global.tutorialSeen = true
    self:Show(1)
end

---Hide the card and glow. markSeen: don't offer the tour again.
function Tutorial:Stop(markSeen)
    if card then card:Hide() end
    if glow then
        glow:Hide()
        glow.pulse:Stop()
    end
    if markSeen and self.db then self.db.global.tutorialSeen = true end
end

---Offer the tour the first time the window opens.
function Tutorial:OfferOnFirstOpen()
    if not self.db or self.db.global.tutorialSeen then return end
    if not card then CreateCard() end
    index = 0
    card.title:SetText(L["Welcome to WowSims!"])
    card.step:SetText("")
    card.text:SetText(L["Export your character to the sim, track upgrades, save gear sets and grab your group's gear. Want a quick tour? It takes a minute."])
    card.back:Hide()
    card.next:SetText(L["Take the tour"])
    card.close:SetText(L["Not now"])
    card.onNext = function()
        card.onNext = nil
        Tutorial:Start()
    end
    ShowGlow(nil)
    PlaceNear(nil)
    Layout()
    card:Show()
end

function Tutorial:Initialize(db, addon)
    self.db = db
    self.addon = addon
end

Env.Tutorial = Tutorial
Env.RegisterFeature(Tutorial)
