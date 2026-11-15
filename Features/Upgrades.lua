-- Upgrades tab (Forever): items in your bags that your stat weights rate higher than what you wear,
-- with a button to equip each, and your equipped gear that's missing enchants or gems.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local L = Env.L

local Upgrades = {}

local MAX_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4

local function GetNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) end
    return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function GetLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
    return GetContainerItemLink and GetContainerItemLink(bag, slot)
end

---Whether the player can wear the item: its tooltip has no red lines (wrong armor type, level...).
local function CanWear(bag, slot)
    if not (C_TooltipInfo and C_TooltipInfo.GetBagItem) then return true end
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
    if not ok or not data or not data.lines then return true end
    for _, line in ipairs(data.lines) do
        local color = line.leftColor
        if color and color.r and color.r > 0.9 and color.g < 0.2 and color.b < 0.2 then return false end
    end
    return true
end

---Bag items that score higher than what they'd replace, best first.
---@return table[] upgrades { link, percent }
---@return boolean hasWeights
function Upgrades.FindBagUpgrades()
    local statWeights = Env.StatWeights
    if not statWeights or not statWeights:GetActiveScale() then return {}, false end
    local found, seen = {}, {}
    for bag = 0, MAX_BAG do
        for slot = 1, GetNumSlots(bag) or 0 do
            local link = GetLink(bag, slot)
            if link and not seen[link] then
                seen[link] = true
                local percent = statWeights:GetUpgradePercent(link)
                if percent and percent > 0.5 and CanWear(bag, slot) then
                    table.insert(found, { link = link, percent = percent })
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.percent > b.percent end)
    return found, true
end

local function Equip(link)
    if InCombatLockdown and InCombatLockdown() then
        Env.FeaturePrint(L["Can't change gear in combat."])
        return
    end
    local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if equip then equip(link) end
end

local function SlotName(slotId)
    local names = {
        [INVSLOT_HEAD or 1] = L["Head"], [INVSLOT_NECK or 2] = L["Neck"], [INVSLOT_SHOULDER or 3] = L["Shoulder"],
        [INVSLOT_CHEST or 5] = L["Chest"], [INVSLOT_WAIST or 6] = L["Waist"], [INVSLOT_LEGS or 7] = L["Legs"],
        [INVSLOT_FEET or 8] = L["Feet"], [INVSLOT_WRIST or 9] = L["Wrist"], [INVSLOT_HAND or 10] = L["Hands"],
        [INVSLOT_FINGER1 or 11] = L["Ring"], [INVSLOT_FINGER2 or 12] = L["Ring"],
        [INVSLOT_TRINKET1 or 13] = L["Trinket"], [INVSLOT_TRINKET2 or 14] = L["Trinket"],
        [INVSLOT_BACK or 15] = L["Back"], [INVSLOT_MAINHAND or 16] = L["Main Hand"],
        [INVSLOT_OFFHAND or 17] = L["Off Hand"], [INVSLOT_RANGED or 18] = L["Ranged"],
    }
    return names[slotId] or ""
end

local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Refresh()
        scroll:ReleaseChildren()

        -- Bag upgrades
        local bagSection = Env.AddSection(scroll, L["Upgrades in your bags"])
        local upgrades, hasWeights = Upgrades.FindBagUpgrades()
        if not hasWeights then
            Env.AddHint(bagSection, L["Add stat weights for your class on the Stat Weights tab first; upgrades are found with them."])
        elseif #upgrades == 0 then
            Env.AddHint(bagSection, L["Nothing in your bags beats what you're wearing."])
        else
            for _, upgrade in ipairs(upgrades) do
                local row = AceGUI:Create("SimpleGroup")
                row:SetFullWidth(true)
                row:SetLayout("Flow")
                bagSection:AddChild(row)

                Env.AddItemIcon(row, upgrade.link)
                local label = AceGUI:Create("InteractiveLabel")
                label:SetText(("%s\n|cff1eff00+%.1f%%|r"):format(upgrade.link, upgrade.percent))
                label:SetWidth(330)
                label:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(upgrade.link:match("|H(item:[^|]+)|h") or upgrade.link)
                    GameTooltip:Show()
                end)
                label:SetCallback("OnLeave", function() GameTooltip:Hide() end)
                row:AddChild(label)

                local button = AceGUI:Create("Button")
                button:SetText(L["Equip"])
                button:SetWidth(90)
                button:SetCallback("OnClick", function()
                    Equip(upgrade.link)
                    C_Timer.After(0.5, Refresh)
                end)
                row:AddChild(button)
            end
        end

        -- Enchants and gems
        local gearSection = Env.AddSection(scroll, L["Missing enchants and gems"])
        local problems = Env.ExportOptions and Env.ExportOptions.FindProblems and Env.ExportOptions.FindProblems() or {}
        if #problems == 0 then
            Env.AddHint(gearSection, L["All your gear is enchanted and gemmed."])
        else
            for _, problem in ipairs(problems) do
                local row = AceGUI:Create("SimpleGroup")
                row:SetFullWidth(true)
                row:SetLayout("Flow")
                gearSection:AddChild(row)

                Env.AddItemIcon(row, problem.link)
                local parts = {}
                if problem.noEnchant then table.insert(parts, "|cffff8040" .. L["No enchant"] .. "|r") end
                if problem.emptySockets > 0 then
                    table.insert(parts, "|cffff8040" .. L["%d empty socket(s)"]:format(problem.emptySockets) .. "|r")
                end
                local label = AceGUI:Create("Label")
                label:SetText(("|cffffd100%s|r  %s\n%s"):format(SlotName(problem.slotId), problem.link, table.concat(parts, ", ")))
                label:SetWidth(430)
                row:AddChild(label)
            end
        end

        local rescan = AceGUI:Create("Button")
        rescan:SetText(L["Check again"])
        rescan:SetWidth(140)
        rescan:SetCallback("OnClick", Refresh)
        scroll:AddChild(rescan)

        scroll:DoLayout()
    end

    Refresh()
end

Upgrades.tab = { value = "upgrades", text = L["Upgrades"], Create = CreateTab }

function Upgrades:Initialize(db)
    self.db = db
end

Env.UpgradesFeature = Upgrades
Env.RegisterFeature(Upgrades)
