-- Saved variables, in place of AceDB.
--
-- Kept in the layout AceDB used, so data saved by older versions carries over, and back again on a
-- downgrade: { profileKeys = { ["Name - Realm"] = "Default" }, profiles = { Default = {...} } }.
-- Each character keeps the profile it had; new characters share "Default".

local Env = select(2, ...)

local function FillDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = type(value) == "table" and FillDefaults({}, value) or value
        elseif type(value) == "table" and type(target[key]) == "table" then
            FillDefaults(target[key], value)
        end
    end
    return target
end

---Open the saved variable `name`. Call it once saved variables have loaded (from OnInitialize).
---@param name string
---@param defaults table Values for keys the profile doesn't have yet.
---@return { profile: table }
function Env.NewDatabase(name, defaults)
    local sv = _G[name] or {}
    _G[name] = sv
    sv.profileKeys = sv.profileKeys or {}
    sv.profiles = sv.profiles or {}

    local charKey = UnitName("player") .. " - " .. GetRealmName()
    local profileName = sv.profileKeys[charKey] or "Default"
    sv.profileKeys[charKey] = profileName
    sv.profiles[profileName] = FillDefaults(sv.profiles[profileName] or {}, defaults)

    return { profile = sv.profiles[profileName] }
end
