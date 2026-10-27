local Env = select(2, ...)

-- table extension contains
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

---Return the index of the biggest value in a numerically keyed table of numbers.
---@param table number[]
function Env.TableMaxValIndex(table)
    local idxMax = 1
    for i = 2, #table do
        if table[i] > table[idxMax] then
            idxMax = i
        end
    end
    return idxMax
end

local statToStatId = {
    str = 1,
    strength = 1,
    agi = 2,
    agility = 2,
    stam = 3,
    stm = 3,
    stamina = 3,
    int = 4,
    intellect = 4,
    spi = 5,
    spirit = 5,
}

---Check if stat1 is bigger than stat2.
---Accepts short (agi) or full stat names (agility)
---@param stat1 string
---@param stat2 string
---@return boolean
function Env.StatBiggerThanStat(stat1, stat2)
    local statId1 = statToStatId[stat1:lower()]
    local statId2 = statToStatId[stat2:lower()]
    assert(statId1 and statId2, "Invalid stat identifiers provided!")
    return select(2, UnitStat("player", statId1)) > select(2, UnitStat("player", statId2))
end
