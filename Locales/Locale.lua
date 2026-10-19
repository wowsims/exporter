-- Lightweight localization support.
--
-- Strings are keyed by their English text. Every locale file calls
-- Env.RegisterLocale(locale, strings); enUS is always registered as the base,
-- and the table matching the client locale (GetLocale()) overrides it.
-- Any key missing from both falls back to the key itself.

local Env = select(2, ...)

local clientLocale = GetLocale()

local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

---Register translated strings for a locale.
---@param locale string Locale code, e.g. "enUS" or "zhCN".
---@param strings table<string, string|boolean> Map of English key -> translation. `true` means "same as key".
function Env.RegisterLocale(locale, strings)
    if locale ~= "enUS" and locale ~= clientLocale then return end
    for key, value in pairs(strings) do
        if value == true then
            value = key
        end
        rawset(L, key, value)
    end
end

Env.L = L
Env.LOCALE = clientLocale
