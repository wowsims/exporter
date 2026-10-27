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
                local name, _, tier, column, _, _, _, avail, _ = GetTalentInfo(tab, i)
                if avail then -- sometimes indices are empty ...
                    local product = (tier - 1) * 4 + column
                    temp[tab][product] = i
                    table.insert(products, product)
                end
            end

            table.sort(products)

            orderedTalentCache[tab] = {}
            local j = 1
            for _, product in ipairs(products) do
                if product then
                    orderedTalentCache[tab][j] = temp[tab][product]
                    j = j + 1
                end
            end
        end
        f:UnregisterEvent("SPELLS_CHANGED")
    end)
end

---Get current talent rank, treating talents sequentially ordered.
---@param tab integer The tree numer. 1-3
---@param num integer The talent index, counted from left to right, line by line.
---@return integer currentRank
function Env.GetTalentRankOrdered(tab, num)
    return select(5, GetTalentInfo(tab, orderedTalentCache[tab][num]))
end

function Env.GetNumTalentsFixed(tab)
    return #orderedTalentCache[tab]
end

---Create a string in the format "000..000-000..000-000..000". Used for Pre-Mists classic
---@return string
function Env.CreateClassicTalentString()
    local GetTalentRank = Env.GetTalentRankOrdered
    local GetNumTalents = Env.GetNumTalentsFixed
    local tabs = {}
    for tab = 1, GetNumTalentTabs() do
        local talents = {}
        for i = 1, GetNumTalents(tab) do
            local currRank = GetTalentRank(tab, i)
            table.insert(talents, tostring(currRank))
        end
        table.insert(tabs, table.concat(talents))
    end
    return table.concat(tabs, "-")
end

---Counts spent talent points per tree.
---@param unit string "player", or "target" for the inspect target.
---@return table pointsPerTreeTable { tree1Count, tree2Count, tree3Count }
function Env.CountClassicPointsPerTree(unit)
    local isInspect = unit == "target"
    local trees = {}

    for tab = 1, GetNumTalentTabs(isInspect) do
        trees[tab] = 0
        for i = 1, GetNumTalents(tab, isInspect) do
            local _, _, _, _, currentRank = GetTalentInfo(tab, i, isInspect)
            trees[tab] = trees[tab] + currentRank
        end
    end

    return trees
end
