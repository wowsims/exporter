-- A small addon object in place of AceAddon and its AceEvent, AceConsole, AceHook and AceComm mixins.
-- It keeps their method names and handler signatures, so the rest of the addon reads the same.

local addonName, Env = ...

-- AceComm prefixes a message whose first byte is one of its control bytes with this one.
local COMM_ESCAPE = "\004"

---Call a handler given as a function, with `...`, or as a method name on `addon`, with `addon, ...`.
local function Dispatch(addon, handler, ...)
    if type(handler) == "string" then
        return addon[handler](addon, ...)
    end
    return handler(...)
end

---Create the addon object. Its OnInitialize method runs once the addon and its saved variables load.
---@param name string Shown at the start of every Print.
function Env.NewAddon(name)
    local addon = {}
    local events, hooks, comms = {}, {}, {}
    local frame = CreateFrame("Frame")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" and ... == addonName then
            if not events.ADDON_LOADED then frame:UnregisterEvent("ADDON_LOADED") end
            if addon.OnInitialize then addon:OnInitialize() end
        elseif event == "CHAT_MSG_ADDON" then
            local prefix, message, distribution, sender = ...
            if comms[prefix] then
                if message:find("^" .. COMM_ESCAPE) then
                    message = message:sub(2)
                elseif message:find("^[\001-\009]") then
                    -- Part of a message too long for one; this addon never sends those.
                    return
                end
                Dispatch(addon, comms[prefix], prefix, message, distribution, Ambiguate(sender, "none"))
            end
        end
        if events[event] then
            Dispatch(addon, events[event], event, ...)
        end
    end)
    frame:RegisterEvent("ADDON_LOADED")

    ---Call `handler(event, ...)`, or the method `addon:handler(event, ...)`, when `event` fires.
    ---@param event string
    ---@param handler string|function|nil Defaults to the method named after the event.
    function addon:RegisterEvent(event, handler)
        events[event] = handler or event
        frame:RegisterEvent(event)
    end

    function addon:UnregisterEvent(event)
        events[event] = nil
        if event ~= "CHAT_MSG_ADDON" or not next(comms) then
            frame:UnregisterEvent(event)
        end
    end

    ---Register `/command`, calling `addon:method(input)` with the rest of the line.
    ---@param command string
    ---@param method string
    function addon:RegisterChatCommand(command, method)
        local key = addonName:upper() .. "_" .. command:upper()
        SlashCmdList[key] = function(input, editBox)
            self[method](self, input, editBox)
        end
        _G["SLASH_" .. key .. "1"] = "/" .. command:lower()
    end

    function addon:Print(...)
        local parts = { "|cff33ff99" .. name .. "|r:" }
        for i = 1, select("#", ...) do
            table.insert(parts, tostring((select(i, ...))))
        end
        DEFAULT_CHAT_FRAME:AddMessage(table.concat(parts, " "))
    end

    ---Call `handler` after the global function `target` runs, until Unhook.
    ---@param target string
    ---@param handler string|function
    function addon:SecureHook(target, handler)
        if hooks[target] == nil then
            -- A secure hook can't be removed, so an unhooked one stays in place and does nothing.
            hooksecurefunc(target, function(...)
                if hooks[target] then Dispatch(self, hooks[target], ...) end
            end)
        end
        hooks[target] = handler
    end

    function addon:Unhook(target)
        if hooks[target] then hooks[target] = false end
    end

    ---Receive addon messages sent with `prefix`, as
    ---`addon:method(prefix, message, distribution, sender)`.
    ---@param prefix string
    ---@param method string|nil Defaults to OnCommReceived.
    function addon:RegisterComm(prefix, method)
        comms[prefix] = method or "OnCommReceived"
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
        frame:RegisterEvent("CHAT_MSG_ADDON")
    end

    ---Send an addon message, in the same format AceComm uses for a message that fits in one.
    ---@param prefix string
    ---@param text string At most 254 bytes.
    ---@param distribution string
    ---@param target string|nil
    function addon:SendCommMessage(prefix, text, distribution, target)
        if text:find("^[\001-\009]") then
            text = COMM_ESCAPE .. text
        end
        C_ChatInfo.SendAddonMessage(prefix, text, distribution, target)
    end

    return addon
end
