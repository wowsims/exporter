-- Stat weights: paste the sim's Pawn export ("Export > Pawn" on the sim) and show a WowSims score,
-- and the change against what's equipped, on item tooltips. Only displays numbers the player made
-- in the sim; it never picks or equips anything.
--
-- Weights are kept in WSEDB.global.statWeights = {
--     scales = { [name] = { class = "Shaman", weights = { Agility = 2.1, ... } } },
--     active = { [classFile] = name }, -- the scale used per class
--     showOnTooltips = true,
-- }

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local StatWeights = {}

-- Pawn stat names, as the sims write them, to the stat keys GetItemStats returns.
-- Each client only returns the keys it has, so one table serves every version.
local statKeysByPawnName = {
    Strength = { "ITEM_MOD_STRENGTH_SHORT" },
    Agility = { "ITEM_MOD_AGILITY_SHORT" },
    Stamina = { "ITEM_MOD_STAMINA_SHORT" },
    Intellect = { "ITEM_MOD_INTELLECT_SHORT" },
    Spirit = { "ITEM_MOD_SPIRIT_SHORT" },
    Ap = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_MELEE_ATTACK_POWER_SHORT" },
    Rap = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
    SpellDamage = { "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_SPELL_POWER_SHORT" },
    SpellPower = { "ITEM_MOD_SPELL_POWER_SHORT" },
    Healing = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
    HitRating = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_MELEE_RATING_SHORT" },
    SpellHitRating = { "ITEM_MOD_HIT_SPELL_RATING_SHORT" },
    CritRating = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_MELEE_RATING_SHORT" },
    SpellCritRating = { "ITEM_MOD_CRIT_SPELL_RATING_SHORT" },
    HasteRating = { "ITEM_MOD_HASTE_RATING_SHORT" },
    SpellHasteRating = { "ITEM_MOD_HASTE_SPELL_RATING_SHORT" },
    ExpertiseRating = { "ITEM_MOD_EXPERTISE_RATING_SHORT" },
    MasteryRating = { "ITEM_MOD_MASTERY_RATING_SHORT" },
    ArmorPenetration = { "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT" },
    SpellPenetration = { "ITEM_MOD_SPELL_PENETRATION_SHORT" },
    Mp5 = { "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_POWER_REGEN0_SHORT" },
    Armor = { "RESISTANCE0_NAME" },
    DodgeRating = { "ITEM_MOD_DODGE_RATING_SHORT" },
    ParryRating = { "ITEM_MOD_PARRY_RATING_SHORT" },
    BlockRating = { "ITEM_MOD_BLOCK_RATING_SHORT" },
    BlockValue = { "ITEM_MOD_BLOCK_VALUE_SHORT" },
    DefenseRating = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
    ResilienceRating = { "ITEM_MOD_RESILIENCE_RATING_SHORT" },
    PvpPower = { "ITEM_MOD_PVP_POWER_SHORT" },
}
local WEAPON_DPS_KEY = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"

-- Readable names for Pawn stat names that aren't plain words.
local statDisplayNames = {
    Ap = "Attack Power", Rap = "Ranged Attack Power", SpellDamage = "Spell Damage", SpellPower = "Spell Power",
    HitRating = "Hit", SpellHitRating = "Spell Hit", CritRating = "Crit", SpellCritRating = "Spell Crit",
    HasteRating = "Haste", SpellHasteRating = "Spell Haste", ExpertiseRating = "Expertise",
    MasteryRating = "Mastery", ArmorPenetration = "Armor Penetration", SpellPenetration = "Spell Penetration",
    Mp5 = "MP5", DodgeRating = "Dodge", ParryRating = "Parry", BlockRating = "Block", BlockValue = "Block Value",
    DefenseRating = "Defense", ResilienceRating = "Resilience", PvpPower = "PvP Power",
    MeleeDps = "Melee Weapon DPS", RangedDps = "Ranged Weapon DPS",
}

---Weights as text, highest first, e.g. "Agility 2.10, Attack Power 1.00".
---@param weights table<string, number>
---@return string
local function DescribeWeights(weights)
    local names = {}
    for name in pairs(weights) do table.insert(names, name) end
    table.sort(names, function(a, b)
        if weights[a] ~= weights[b] then return weights[a] > weights[b] end
        return a < b
    end)
    local parts = {}
    for _, name in ipairs(names) do
        table.insert(parts, ("%s |cffffffff%.2f|r"):format(statDisplayNames[name] or name, weights[name]))
    end
    return table.concat(parts, ",  ")
end

local scoreCache = {}

---@return table
function StatWeights:GetData()
    local data = Env.GetOrCreateTable(self.db.global, "statWeights")
    Env.GetOrCreateTable(data, "scales")
    Env.GetOrCreateTable(data, "active")
    if data.showOnTooltips == nil then data.showOnTooltips = true end
    return data
end

---Turn a class name from a Pawn string ("Death Knight") into the client's class file ("DEATHKNIGHT").
---@param className string
---@return string
local function ClassFileFromName(className)
    return (className:upper():gsub("[^A-Z]", ""))
end

---Read a Pawn string such as `( Pawn: v1: "Name": Class=Shaman,Agility=2.100,... )`.
---@param text string
---@return string|nil name
---@return string|nil className
---@return table<string, number>|nil weights
function StatWeights.ParsePawnString(text)
    text = text and strtrim(text) or ""
    if not text:find("Pawn:", 1, true) then return nil end
    local name = text:match('"([^"]+)"')
    local className = text:match("Class=([^,%)]+)")
    if not name or not className then return nil end

    local weights, count = {}, 0
    local body = text:match('"[^"]+"%s*:%s*(.-)%s*%)%s*$') or text
    for key, value in body:gmatch("([%a%d]+)%s*=%s*(%-?[%d%.]+)") do
        if key ~= "Class" then
            weights[key] = tonumber(value)
            count = count + 1
        end
    end
    if count == 0 then return nil, "empty" end
    return name, strtrim(className), weights
end

---Add a scale from a Pawn string and make it the active one for its class.
---@param text string
---@return boolean added
function StatWeights:AddFromPawnString(text)
    local name, className, weights = StatWeights.ParsePawnString(text)
    if not name and className == "empty" then
        Env.FeaturePrint(L["That Pawn string has no weights. Run Stat Weights in the sim first, then export Pawn again."])
        return false
    elseif not name then
        Env.FeaturePrint(L["That isn't a Pawn string. In the sim, use Export > Pawn and copy all of it."])
        return false
    end
    local data = self:GetData()
    data.scales[name] = { class = className, weights = weights }
    data.active[ClassFileFromName(className)] = name
    wipe(scoreCache)
    Env.FeaturePrint(L["Added stat weights \"%s\" for %s."]:format(name, className))
    return true
end

---@param name string
function StatWeights:Delete(name)
    local data = self:GetData()
    local scale = data.scales[name]
    if not scale then return end
    data.scales[name] = nil
    local classFile = ClassFileFromName(scale.class)
    if data.active[classFile] == name then data.active[classFile] = nil end
    wipe(scoreCache)
end

---@param name string
function StatWeights:SetActive(name)
    local data = self:GetData()
    local scale = data.scales[name]
    if not scale then return end
    data.active[ClassFileFromName(scale.class)] = name
    wipe(scoreCache)
end

---The active scale for the player's class.
---@return string|nil name
---@return table|nil scale
function StatWeights:GetActiveScale()
    local data = self:GetData()
    local _, classFile = UnitClass("player")
    local name = data.active[classFile]
    return name, name and data.scales[name]
end

---Score an item with a scale.
---@param itemLink string
---@param scale table
---@return number|nil score nil if the client has no stats for the item yet.
function StatWeights.ScoreItem(itemLink, scale)
    local getStats = (C_Item and C_Item.GetItemStats) or GetItemStats
    local ok, stats = pcall(getStats, itemLink)
    if not ok or not stats then return nil end

    local score = 0
    for pawnName, weight in pairs(scale.weights) do
        local keys = statKeysByPawnName[pawnName]
        if keys then
            for _, key in ipairs(keys) do
                local value = stats[key]
                if value then
                    score = score + value * weight
                    break -- one key per stat, so a stat the client lists twice isn't counted twice
                end
            end
        end
    end

    local dps = stats[WEAPON_DPS_KEY]
    if dps then
        local equipLoc = Env.GetItemEquipLoc(itemLink)
        local weight = Env.IsRangedEquipLoc(equipLoc) and scale.weights.RangedDps or scale.weights.MeleeDps
        score = score + dps * (weight or 0)
    end
    return score
end

local function CachedScore(itemLink, scaleName, scale)
    local key = scaleName .. "|" .. itemLink
    local score = scoreCache[key]
    if score == nil then
        score = StatWeights.ScoreItem(itemLink, scale)
        if score then scoreCache[key] = score end
    end
    return score
end

---Score of the weakest equipped item an item would replace.
---@param itemLink string
---@return number|nil score nil if nothing comparable is equipped.
local function EquippedScore(itemLink, scaleName, scale)
    local lowest, lowestLink
    for _, slotId in ipairs(Env.GetSlotsForEquipLoc(Env.GetItemEquipLoc(itemLink))) do
        local equipped = GetInventoryItemLink("player", slotId)
        local score = equipped and CachedScore(equipped, scaleName, scale)
        if score and (not lowest or score < lowest) then
            lowest, lowestLink = score, equipped
        end
    end
    return lowest, lowestLink
end

---Add the score lines to an item tooltip.
---@param tooltip table GameTooltip or similar.
local UP_ICON = "|TInterface\\Buttons\\UI-MicroStream-Green:14:14|t"
local DOWN_ICON = "|TInterface\\Buttons\\UI-MicroStream-Red:14:14|t"

---Whether an item is the one worn in one of its slots.
local function IsEquipped(itemLink)
    for _, slotId in ipairs(Env.GetSlotsForEquipLoc(Env.GetItemEquipLoc(itemLink))) do
        if GetInventoryItemLink("player", slotId) == itemLink then return true end
    end
    return false
end

local function AddScoreToTooltip(tooltip)
    if not StatWeights.db or not StatWeights:GetData().showOnTooltips then return end
    if not tooltip.GetItem then return end
    -- In Forever, values can be restricted during combat. Any failure just leaves the tooltip as it is.
    pcall(function()
        local _, itemLink = tooltip:GetItem()
        if not itemLink then return end
        if #Env.GetSlotsForEquipLoc(Env.GetItemEquipLoc(itemLink)) == 0 then return end

        local scaleName, scale = StatWeights:GetActiveScale()
        if not scale then
            tooltip:AddLine("|cff00ccffWowSims|r " .. L["upgrade scores: add stat weights in /wowsims"], 0.6, 0.6, 0.6)
            tooltip:Show()
            return
        end
        local score = CachedScore(itemLink, scaleName, scale)
        if not score or score <= 0 then return end

        tooltip:AddLine(" ")
        tooltip:AddDoubleLine("|cff00ccffWowSims|r " .. scaleName, ("%.1f"):format(score), 1, 1, 1, 1, 1, 1)

        if IsEquipped(itemLink) then
            tooltip:AddLine(L["Equipped"], 0.6, 0.6, 0.6)
        else
            local current, currentLink = EquippedScore(itemLink, scaleName, scale)
            if not current then
                tooltip:AddLine(UP_ICON .. " " .. L["Upgrade: that slot is empty"], 0.12, 1, 0)
            elseif current > 0 then
                local change = (score - current) / current * 100
                local against = currentLink and (currentLink:match("%[(.-)%]") or currentLink) or ""
                if change >= 0.05 then
                    tooltip:AddLine(UP_ICON .. " " .. L["Upgrade: +%.1f%% over %s"]:format(change, against), 0.12, 1, 0)
                elseif change <= -0.05 then
                    tooltip:AddLine(DOWN_ICON .. " " .. L["Downgrade: %.1f%% vs %s"]:format(change, against), 1, 0.25, 0.25)
                else
                    tooltip:AddLine(L["Same score as %s"]:format(against), 0.8, 0.8, 0.8)
                end
            end
        end
        tooltip:Show()
    end)
end

local function HookTooltips()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip or tooltip == ShoppingTooltip1 or tooltip == ShoppingTooltip2 then
                AddScoreToTooltip(tooltip)
            end
        end)
    else
        for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
            tooltip:HookScript("OnTooltipSetItem", AddScoreToTooltip)
        end
    end
end

---@param container table The tab group to fill.
local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Refresh()
        container:SelectTab(StatWeights.tab.value)
    end

    local data = StatWeights:GetData()

    local add = Env.AddSection(scroll, L["Add stat weights"])
    Env.AddHint(add, L["In the sim: run Stat Weights, then Export > Pawn. Paste the whole line here and click Accept. Gear tooltips then show a WowSims score and whether it's an upgrade."])

    local pasteBox = AceGUI:Create("MultiLineEditBox")
    pasteBox:SetLabel(L["Pawn string"])
    pasteBox:SetFullWidth(true)
    pasteBox:SetNumLines(3)
    pasteBox:SetCallback("OnEnterPressed", function(widget, _, text)
        if StatWeights:AddFromPawnString(text) then Refresh() end
    end)
    add:AddChild(pasteBox)

    local tooltipToggle = AceGUI:Create("CheckBox")
    tooltipToggle:SetLabel(L["Show scores on item tooltips"])
    tooltipToggle:SetFullWidth(true)
    tooltipToggle:SetValue(data.showOnTooltips)
    tooltipToggle:SetCallback("OnValueChanged", function(_, _, value)
        data.showOnTooltips = value
    end)
    add:AddChild(tooltipToggle)

    local names = {}
    for name in pairs(data.scales) do table.insert(names, name) end
    table.sort(names)

    local heading = AceGUI:Create("Heading")
    heading:SetText(L["Your stat weights (%d)"]:format(#names))
    heading:SetFullWidth(true)
    scroll:AddChild(heading)

    if #names == 0 then
        Env.AddHint(scroll, L["No stat weights yet."])
        return
    end

    for _, name in ipairs(names) do
        local scale = data.scales[name]
        local isActive = data.active[ClassFileFromName(scale.class)] == name
        local count = 0
        for _ in pairs(scale.weights) do count = count + 1 end

        local group = AceGUI:Create("InlineGroup")
        group:SetTitle(name)
        group:SetFullWidth(true)
        group:SetLayout("Flow")
        scroll:AddChild(group)

        local info = AceGUI:Create("Label")
        local classFile = ClassFileFromName(scale.class)
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        local className = color and ("|c%s%s|r"):format(color.colorStr or "ffffffff", scale.class) or scale.class
        info:SetText(("%s  |cff9d9d9d·  %s|r"):format(className, L["%d stats"]:format(count))
            .. (isActive and ("   |cff1eff00" .. L["Active"] .. "|r") or ""))
        info:SetWidth(320)
        group:AddChild(info)

        local weightsLabel = AceGUI:Create("Label")
        weightsLabel:SetText("|cffbbbbbb" .. DescribeWeights(scale.weights) .. "|r")
        weightsLabel:SetFullWidth(true)

        if not isActive then
            local useButton = AceGUI:Create("Button")
            useButton:SetText(L["Use"])
            useButton:SetWidth(90)
            useButton:SetCallback("OnClick", function()
                StatWeights:SetActive(name)
                Refresh()
            end)
            group:AddChild(useButton)
        end

        local deleteButton = AceGUI:Create("Button")
        deleteButton:SetText(L["Delete"])
        deleteButton:SetWidth(90)
        deleteButton:SetCallback("OnClick", function()
            StatWeights:Delete(name)
            Refresh()
        end)
        group:AddChild(deleteButton)

        group:AddChild(weightsLabel)
    end
end

---How much better an item scores than the equipped item it would replace, with the active weights.
---@param itemLink string
---@return number|nil percent Positive for an upgrade; nil if it can't be scored or compared.
function StatWeights:GetUpgradePercent(itemLink)
    if not self.db then return nil end
    if #Env.GetSlotsForEquipLoc(Env.GetItemEquipLoc(itemLink)) == 0 then return nil end
    local scaleName, scale = self:GetActiveScale()
    if not scale then return nil end
    local score = CachedScore(itemLink, scaleName, scale)
    if not score or score <= 0 then return nil end
    local current = EquippedScore(itemLink, scaleName, scale)
    if not current then return 100 end -- nothing equipped there
    if current <= 0 then return nil end
    return (score - current) / current * 100
end

StatWeights.tab = { value = "statweights", text = L["Stat Weights"], Create = CreateTab }

function StatWeights:Initialize(db)
    self.db = db
    HookTooltips()
end

Env.StatWeights = StatWeights
Env.RegisterFeature(StatWeights)
