local Env = select(2, ...)
if not Env.IS_CLASSIC_MISTS then return end

---Create a string in the format "000000". Used for Mists classic
---@return string
function Env.CreateMistsTalentString(isInspect)
    local unit = isInspect and Env.inspectUnit or "player"
    local GetTalentInfo = C_SpecializationInfo.GetTalentInfo
    local activeSpecGroup = C_SpecializationInfo.GetActiveSpecGroup(isInspect)
    local talents = {}
    for row = 1, MAX_NUM_TALENT_TIERS do
        local found = false
        for column = 1, 3 do
            local talentInfo = GetTalentInfo({
                isInspect = isInspect,
                target = unit,
                groupIndex = activeSpecGroup,
                tier = row,
                column = column,
            })
            if talentInfo.selected then
                found = true
                table.insert(talents, tostring(column))
                break
            end
        end
        if not found then
            table.insert(talents, tostring(0))
        end
    end
    return table.concat(talents)
end
