local Env = select(2, ...)

-- Builds the path of a spec's page on the sim, following the URL rules of the sim codebase the
-- flavor links to. Each codebase uses one of three layouts:
--
--   flat        wowsims/classic, sod and wotlk: one page per folder, named "<spec>_<class>", e.g.
--               "elemental_shaman". Classes whose specs share a sim use the class alone, e.g.
--               "hunter", and their tanks "tank_<class>" or "protection_<class>".
--   class_spec  wowsims/cata and mop: "<class>/<spec>" for every spec, e.g. "hunter/marksmanship".
--   class_role  wowsims/tbc-new and forever: "<class>/<spec>" where a spec has its own sim,
--               otherwise one per role, e.g. "priest/healer" or "mage/dps".
--
-- A flavor lists the pages its sim serves in simPages, and only a listed page is ever linked, so
-- a link can't point at a page that doesn't exist. Without a match the link is the sim root.

-- Role of a spec name when AddSpec doesn't give one.
local defaultRoles = {
    protection = "tank",
    feral_bear = "tank",
    guardian = "tank",
    brewmaster = "tank",
    warlocktank = "tank",
    warden = "tank",
    tank = "tank",
    restoration = "healer",
    holy = "healer",
    disc = "healer",
    holy_disc = "healer",
    mistweaver = "healer",
}

---@class SimLayout
---@field classNames table<string, string> The sim's name for a class, where it differs from ours.
---@field specNames table<string, string> The sim's name for a spec, where it differs from ours.
---@field candidates fun(class:string, spec:string, role:string):string[] Pages to try, in order.

---@type table<string, SimLayout>
local layouts = {
    flat = {
        classNames = {},
        specNames = {
            feral_bear = "feral_tank",
            holy_disc = "healing",
        },
        candidates = function(class, spec, role)
            local pages = { spec .. "_" .. class }
            if role == "tank" then
                table.insert(pages, "tank_" .. class)
                table.insert(pages, "protection_" .. class)
            elseif role == "healer" then
                table.insert(pages, "healing_" .. class)
            end
            table.insert(pages, class)
            return pages
        end,
    },
    class_spec = {
        classNames = {
            deathknight = "death_knight",
        },
        specNames = {
            marksman = "marksmanship",
            disc = "discipline",
        },
        candidates = function(class, spec)
            return { class .. "/" .. spec }
        end,
    },
    class_role = {
        classNames = {
            deathknight = "death_knight",
        },
        specNames = {
            feral = "feralcat",
            feral_bear = "feralbear",
            guardian = "feralbear",
        },
        candidates = function(class, spec, role)
            local pages = { class .. "/" .. spec }
            if role == "tank" then
                table.insert(pages, class .. "/protection")
            elseif role == "healer" then
                table.insert(pages, class .. "/healer")
            end
            table.insert(pages, class .. "/dps")
            return pages
        end,
    },
}

---Role of a spec, for picking a shared page.
---@param spec string
---@param role string|nil Overrides the default for the spec name.
---@return string role "tank", "healer" or "dps".
function Env.GetSpecRole(spec, role)
    return role or defaultRoles[spec] or "dps"
end

---Get the path of a spec's page on the current flavor's sim.
---@param class string Class token in any case, e.g. "DEATHKNIGHT".
---@param spec string Spec name as given to AddSpec, e.g. "marksman".
---@param role string|nil Overrides the role the spec name implies.
---@return string path e.g. "hunter/marksmanship", or "" if the sim has no page for the spec.
function Env.GetSimPath(class, spec, role)
    local flavor = Env.Flavor
    local layout = layouts[flavor.simLayout]
    if not layout or spec == "" then return "" end

    class = class:lower()
    class = layout.classNames[class] or class
    local simSpec = layout.specNames[spec] or spec
    for _, page in ipairs(layout.candidates(class, simSpec, Env.GetSpecRole(spec, role))) do
        if flavor.simPages[page] then
            return page
        end
    end
    return ""
end
