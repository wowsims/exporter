local Env = select(2, ...)

-- SkillLine.db2
local professionSkillLineIDs = {
    Blacksmithing  = 164,
    Leatherworking = 165,
    Alchemy        = 171,
    Herbalism      = 182,
    Mining         = 186,
    Tailoring      = 197,
    Engineering    = 202,
    Enchanting     = 333,
    Skinning       = 393,
    Jewelcrafting  = 755,
    Inscription    = 773,
}

Env.professionNames = {}
Env.professionEngNameBySkillLine = {}
for engName, skillLine in pairs(professionSkillLineIDs) do
    Env.professionEngNameBySkillLine[skillLine] = engName
    local localizedName = C_TradeSkillUI.GetTradeSkillDisplayName(skillLine)
    if localizedName then
        Env.professionNames[localizedName] = {
            skillLine = skillLine,
            engName = engName
        }
    end
end

Env.profInspectTable = Env.profInspectTable or {}
function Env.AddInspectedProfessions(name, entry)
    Env.profInspectTable[name] = entry
end

---Read the player's professions from the skill lines.
---@return table[]
local function GetSkillLineProfessions()
    local professions = {}
    local professionNames = Env.professionNames
    for i = 1, GetNumSkillLines() do
        local name, _, _, skillLevel = GetSkillLineInfo(i)
        if professionNames[name] then
            table.insert(professions, {
                name = professionNames[name].engName,
                level = skillLevel,
            })
        end
    end

    return professions
end

---Create professions table.
---@param isInspect boolean
function Env.CreateProfessionEntry(isInspect)
    if isInspect then
        local unit = Env.inspectUnit
        return Env.profInspectTable[UnitName(unit)] or {}
    end
    local GetProfessions = Env.Flavor.GetProfessions or GetSkillLineProfessions
    return GetProfessions()
end
