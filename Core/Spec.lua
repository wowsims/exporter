local Env = select(2, ...)

local specializations = {}

---Try to find spec. Returns empty strings if spec could not be found.
---@param unit string "player" or the inspected unit
---@return string specName The name of the spec, e.g. "feral".
---@return string simPath The path of the spec's page on the sim, e.g. "druid/feralcat". See Env.GetSimPath.
function Env.GetSpec(unit)
    local playerClass = select(2, UnitClass(unit))

    if specializations[playerClass] then
        local flavor = Env.Flavor
        if flavor.GetSpecializationID then
            local specId = flavor.GetSpecializationID(unit)
            for _, specData in ipairs(specializations[playerClass]) do
                if specData.specId == specId then
                    return specData.spec, Env.GetSimPath(playerClass, specData.spec, specData.role)
                end
            end
        else
            local spentTalentPoints = flavor.CountPointsPerTree(unit)
            for _, specData in ipairs(specializations[playerClass]) do
                if specData.isCurrentSpec(spentTalentPoints) then
                    return specData.spec, Env.GetSimPath(playerClass, specData.spec, specData.role)
                end
            end
        end
    end

    return "", ""
end

---Add spec to detection list. Specs are checked in the order they are added and the first match
---wins, so add a variant (e.g. a tank build) before the spec it would otherwise be taken for.
---@param playerClass string
---@param spec string The name of the spec, e.g. "feral".
---@param checkFunc (fun(spentTanlents:number[]):boolean)|nil Not used by flavors that match by specId.
---@param specId integer|nil The SpecializationID of the spec
---@param role string|nil "tank", "healer" or "dps", when the spec name alone doesn't say. See Env.GetSpecRole.
function Env.AddSpec(playerClass, spec, checkFunc, specId, role)
    playerClass = playerClass:upper()
    specializations[playerClass] = specializations[playerClass] or {}
    table.insert(specializations[playerClass], {
        spec = spec,
        isCurrentSpec = checkFunc,
        specId = specId,
        role = role,
    })
end

---Call fn for every registered spec, in registration order.
---@param fn fun(playerClass:string, spec:string, role:string|nil)
function Env.ForEachSpec(fn)
    local classes = {}
    for playerClass in pairs(specializations) do
        table.insert(classes, playerClass)
    end
    table.sort(classes)
    for _, playerClass in ipairs(classes) do
        for _, specData in ipairs(specializations[playerClass]) do
            fn(playerClass, specData.spec, specData.role)
        end
    end
end
