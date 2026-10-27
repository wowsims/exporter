local Env = select(2, ...)

local specializations = {}

---Try to find spec. Returns empty strings if spec could not be found.
---@param unit string "player" or the inspected unit
---@return string specName The name of the spec, e.g. "feral".
---@return string specUrl The URL part of the spec, e.g. "feral_druid"
function Env.GetSpec(unit)
    local playerClass = select(2, UnitClass(unit))

    if specializations[playerClass] then
        local flavor = Env.Flavor
        if flavor.GetSpecializationID then
            local specId = flavor.GetSpecializationID(unit)
            for _, specData in pairs(specializations[playerClass]) do
                if specData.specId == specId then
                    return specData.spec, specData.url
                end
            end
        else
            local spentTalentPoints = flavor.CountPointsPerTree(unit)
            for _, specData in pairs(specializations[playerClass]) do
                if specData.isCurrentSpec(spentTalentPoints) then
                    return specData.spec, specData.url
                end
            end
        end
    end

    return "", ""
end

---Add spec to detection list.
---@param playerClass string
---@param spec string The name of the spec, e.g. "feral".
---@param url string The URL part of the spec, e.g. "feral_druid"
---@param checkFunc fun(spentTanlents:number[]):boolean
---@param specId integer|nil The SpecializationID of the spec
function Env.AddSpec(playerClass, spec, url, checkFunc, specId)
    playerClass = playerClass:upper()
    specializations[playerClass] = specializations[playerClass] or {}
    table.insert(specializations[playerClass], {
        spec = spec,
        url = url,
        isCurrentSpec = checkFunc,
        specId = specId,
    })
end
