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

---Attempt to infer an inspected player's professions from gear
---@param equipmentSpec table
---@return table
local GetItemNumSockets = C_Item.GetItemNumSockets
function Env.InferProfessionsFromGear(equipmentSpec)
    local professions = {}
    if equipmentSpec:GetItemInSlot(INVSLOT_FINGER1):GetEnchant() or equipmentSpec:GetItemInSlot(INVSLOT_FINGER2):GetEnchant() then
        table.insert(professions,{name = "Enchanting", level = 600})
    end
    if #equipmentSpec:GetItemInSlot(INVSLOT_HAND):GetGems() > GetItemNumSockets(equipmentSpec:GetItemInSlot(INVSLOT_HAND):GetId()) or
       #equipmentSpec:GetItemInSlot(INVSLOT_WRIST):GetGems() > GetItemNumSockets(equipmentSpec:GetItemInSlot(INVSLOT_WRIST):GetId()) then
        table.insert(professions,{name = "Blacksmithing", level = 600})
    end
    if table.contains({4880,4881,4882}, equipmentSpec:GetItemInSlot(INVSLOT_LEGS):GetEnchant()) or table.contains({4875,4877,4878,4879}, equipmentSpec:GetItemInSlot(INVSLOT_WRIST):GetEnchant()) then
        table.insert(professions,{name = "Leatherworking", level = 600})
    end
    if table.contains({4895,4896}, equipmentSpec:GetItemInSlot(INVSLOT_LEGS):GetEnchant()) or table.contains({4892,4893,4894}, equipmentSpec:GetItemInSlot(INVSLOT_BACK):GetEnchant()) then
        table.insert(professions,{name = "Tailoring", level = 600})
    end
    if equipmentSpec:GetItemInSlot(INVSLOT_HAND):GetTinker() ~= nil then
        table.insert(professions,{name = "Engineering", level = 600})
    end
    for _, item in ipairs(equipmentSpec.items) do
        if table.contains({83141,83147,83150,83151,83152}, item:GetGems()) then
            table.insert(professions,{name = "Jewelcrafting", level = 600})
            break
        end
    end
    if table.contains({4912,4913,4914,4915}, equipmentSpec:GetItemInSlot(INVSLOT_SHOULDER):GetEnchant()) then
        table.insert(professions,{name = "Inscription", level = 600})
    end
    if #professions > 2 then
        error("Too many professions detected !")
    end
    return professions
end
