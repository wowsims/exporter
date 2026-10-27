local Env = select(2, ...)
if not Env.IS_CLASSIC_MISTS then return end

---Parse current item upgrade level from item tooltip.
---@param unit string
---@param itemSlot integer
---@return integer
function Env.GetItemUpgradeLevel(unit, itemSlot)
    WSEScanningTooltip:ClearLines()
    WSEScanningTooltip:SetInventoryItem(unit, itemSlot)
    local regions = { WSEScanningTooltip:GetRegions() }

    for i = 1, #regions do
        local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and text:find(ITEM_UPGRADE_TOOLTIP_FORMAT) then
                local pattern, _ = ITEM_UPGRADE_TOOLTIP_FORMAT:gsub("%%d","%(%%d%)")
                local _, _, curLevel, maxLevel = text:find(pattern)
                return tonumber(curLevel)
            end
        end
    end
    return -1
end


---Parse hand tinker from item tooltip.
---@param unit string
---@return integer
function Env.GetHandTinker(unit)
    WSEScanningTooltip:ClearLines()
    WSEScanningTooltip:SetInventoryItem(unit, INVSLOT_HAND)
    local regions = { WSEScanningTooltip:GetRegions() }

    local use_localized = ITEM_SPELL_TRIGGER_ONUSE
    local cooldown_m_localized = ITEM_COOLDOWN_TOTAL_MIN -- korean locale uses another string : ITEM_COOLDOWN_TOTAL
    local cooldown_s_localized = ITEM_COOLDOWN_TOTAL_SEC

    for i = 1, #regions do
        local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            -- some client have wierd character as separator, so hopefuly .?.? picks them all
            if text and text:find(use_localized..".+1.?.?920.+") then
                return 4898 -- Synapse Srping
            end
            if text and text:find(use_localized..".+2.?.?880.+") then
                return 4697 -- Phase Fingers
            end
            if text and text:find(use_localized..".+42.?.?000.+63.?.?000.+") then
                return 4698 -- Incendiary Fireworks Launcher
            end
        end
    end
    return 0
end

local GetItemNumSockets = C_Item.GetItemNumSockets

-- Gems only jewelcrafters can socket.
local jewelcraftingGems = { 83141, 83147, 83150, 83151, 83152 }

---Attempt to infer an inspected player's professions from gear
---@param equipmentSpec table
---@return table professions Empty if the gear suggests more than two, since then a guess is wrong.
function Env.InferProfessionsFromGear(equipmentSpec)
    local function Enchant(slotId)
        local item = equipmentSpec:GetItemInSlot(slotId)
        return item and item:GetEnchant()
    end
    -- Blacksmiths add a socket to their bracers and gloves.
    local function HasExtraSocket(slotId)
        local item = equipmentSpec:GetItemInSlot(slotId)
        return item ~= nil and #(item:GetGems() or {}) > GetItemNumSockets(item:GetId())
    end

    local professions = {}
    if Enchant(INVSLOT_FINGER1) or Enchant(INVSLOT_FINGER2) then
        table.insert(professions,{name = "Enchanting", level = 600})
    end
    if HasExtraSocket(INVSLOT_HAND) or HasExtraSocket(INVSLOT_WRIST) then
        table.insert(professions,{name = "Blacksmithing", level = 600})
    end
    if table.contains({4880,4881,4882}, Enchant(INVSLOT_LEGS)) or table.contains({4875,4877,4878,4879}, Enchant(INVSLOT_WRIST)) then
        table.insert(professions,{name = "Leatherworking", level = 600})
    end
    if table.contains({4895,4896}, Enchant(INVSLOT_LEGS)) or table.contains({4892,4893,4894}, Enchant(INVSLOT_BACK)) then
        table.insert(professions,{name = "Tailoring", level = 600})
    end
    local hands = equipmentSpec:GetItemInSlot(INVSLOT_HAND)
    if hands and hands:GetTinker() ~= nil then
        table.insert(professions,{name = "Engineering", level = 600})
    end
    -- pairs, not ipairs: empty slots leave gaps in items.
    local hasJewelcraftingGem = false
    for _, item in pairs(equipmentSpec.items) do
        for _, gemId in pairs(item:GetGems() or {}) do
            if table.contains(jewelcraftingGems, gemId) then
                hasJewelcraftingGem = true
            end
        end
    end
    if hasJewelcraftingGem then
        table.insert(professions,{name = "Jewelcrafting", level = 600})
    end
    if table.contains({4912,4913,4914,4915}, Enchant(INVSLOT_SHOULDER)) then
        table.insert(professions,{name = "Inscription", level = 600})
    end
    if #professions > 2 then
        return {}
    end
    return professions
end
