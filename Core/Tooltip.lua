local Env = select(2, ...)

CreateFrame("GameTooltip", "WSEScanningTooltip", nil, "GameTooltipTemplate")
WSEScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local baseItemLink = "item:9333:"
C_Item.RequestLoadItemDataByID(baseItemLink)

---@return table<integer, string>
local function GetBaseItemText()
    WSEScanningTooltip:ClearLines()
    WSEScanningTooltip:SetHyperlink(baseItemLink)
    local regions = { WSEScanningTooltip:GetRegions() }

    local itemText = {}

    for i = 1, #regions do
        local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text then
                itemText[i] = text
            end
        end
    end

    return itemText
end

local baseItemText

---Get the localized text of a given enchantID as it will appear in an tooltip
---@param enchantID integer
---@return string
function Env.GetEnchantText(enchantID)
    if not baseItemText then
        baseItemText = GetBaseItemText()
    end

    WSEScanningTooltip:ClearLines()
    WSEScanningTooltip:SetHyperlink(baseItemLink .. enchantID)
    local regions = { WSEScanningTooltip:GetRegions() }

    for i = 1, #regions do
        local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and baseItemText[i] ~= text then
                return text
            end
        end
    end

    return ""
end
