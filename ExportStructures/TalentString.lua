local Env = select(2, ...)

-- Borrowed from rating buster!!
-- As of Classic Patch 3.4.0, GetTalentInfo indices no longer correlate
-- to their positions in the tree. Building a talent cache ordered by
-- tier then column allows us to replicate the previous behavior.
local orderedTalentCache = {}
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("SPELLS_CHANGED")
    f:SetScript("OnEvent", function()
        local temp = {}
        for tab = 1, GetNumTalentTabs() do
            temp[tab] = {}
            local products = {}
            for i = 1, GetNumTalents(tab) do
                local name, _, tier, column = GetTalentInfo(tab, i)
                local product = (tier - 1) * 4 + column
                temp[tab][product] = i
                table.insert(products, product)
            end

            table.sort(products)

            orderedTalentCache[tab] = {}
            local j = 1
            for _, product in ipairs(products) do
                orderedTalentCache[tab][j] = temp[tab][product]
                j = j + 1
            end
        end
        f:UnregisterEvent("SPELLS_CHANGED")
    end)
end

---Create a string in the format "000..000-000..000-000..000".
---@return string
local function CreateTalentString()
    local tabs = {}
    for tab = 1, GetNumTalentTabs() do
        local talents = {}
        for i = 1, GetNumTalents(tab) do
            local currRank = select(5, GetTalentInfo(tab, orderedTalentCache[tab][i]))
            table.insert(talents, tostring(currRank))
        end
        table.insert(tabs, table.concat(talents))
    end
    return table.concat(tabs, "-")
end

Env.CreateTalentString = CreateTalentString
