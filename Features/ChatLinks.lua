-- Gear set chat links (Forever): "Link" on a gear set puts [WowSims: Set Name] in chat. For other
-- WowSims users that text becomes a link; clicking it asks the sender's addon for the set, which
-- opens in their Import tab. Players without WowSims just see the plain text.
--
-- Messages use AceComm with the prefix "WowSimsLink", whispered:
--   "REQ\t<set name>"           asks for a set. Only answered for sets linked in the last hour.
--   "SET\t<set name>\t<json>"   the set, as the export JSON. Only kept if we asked for it.
-- Settings in WSEDB.global.chatLinks = { enabled = true }.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceComm = LibStub("AceComm-3.0", true)
local L = Env.L

local ChatLinks = {}

local PREFIX = "WowSimsLink"
local LINK_TYPE = "garrmission:wowsims" -- a link type the game ignores when clicked, so we handle it
local SHARE_FOR = 3600                  -- seconds a linked set can be requested
local ANSWER_WINDOW = 60                -- seconds we wait for a requested set

local linked = {}  -- [set name] = time we linked it
local asked = {}   -- [sender .. "\t" .. set name] = time we asked

local CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL",
}

---@return table options { enabled = true }
function ChatLinks:GetOptions()
    local options = Env.GetOrCreateTable(self.db.global, "chatLinks")
    if options.enabled == nil then options.enabled = true end
    return options
end

local function Send(message, target)
    if not AceComm then return false end
    return (pcall(AceComm.SendCommMessage, ChatLinks, PREFIX, message, "WHISPER", target, "BULK"))
end

---Put [WowSims: name] into the chat box.
---@param setName string
function ChatLinks:LinkSet(setName)
    local text = "[WowSims: " .. setName .. "]"
    linked[setName] = GetTime()
    local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if editBox then
        editBox:Insert(text)
    elseif ChatFrame_OpenChat then
        ChatFrame_OpenChat(text)
    end
end

---Ask a player's addon for a set they linked.
local function Request(sender, setName)
    if sender == UnitName("player") or (Ambiguate and Ambiguate(sender, "none") == UnitName("player")) then
        -- Our own link: open it straight away.
        local json = Env.GearSets and Env.GearSets:Export(setName)
        if json and Env.SimImport then
            Env.SimImport.Load(json)
            if Env.Settings then Env.Settings:OpenTab(Env.SimImport.tab.value) end
        end
        return
    end
    asked[sender .. "\t" .. setName] = GetTime()
    if Send("REQ\t" .. setName, sender) then
        Env.FeaturePrint(L["Asking %s for \"%s\"..."]:format(Ambiguate and Ambiguate(sender, "short") or sender, setName))
    end
end

local function OnComm(_, message, distribution, sender)
    if distribution ~= "WHISPER" or type(message) ~= "string" then return end
    local kind, setName, json = strsplit("\t", message, 3)
    if kind == "REQ" and setName then
        local when = linked[setName]
        if not when or GetTime() - when > SHARE_FOR then return end
        local export = Env.GearSets and Env.GearSets:Export(setName)
        if export then Send("SET\t" .. setName .. "\t" .. export, sender) end
    elseif kind == "SET" and setName and json then
        local key = sender .. "\t" .. setName
        if not asked[key] or GetTime() - asked[key] > ANSWER_WINDOW then return end
        asked[key] = nil
        local ok, err = Env.SimImport.Load(json)
        if ok == false then
            Env.FeaturePrint(err or L["That set couldn't be read."])
            return
        end
        if Env.Settings then Env.Settings:OpenTab(Env.SimImport.tab.value) end
    end
end

---Chat filter: turn [WowSims: name] into a clickable link that remembers the sender.
local function Filter(_, _, message, sender, ...)
    if type(message) ~= "string" or not ChatLinks.db or not ChatLinks:GetOptions().enabled then return false end
    local ok, changed = pcall(function()
        if not message:find("[WowSims: ", 1, true) then return nil end
        return (message:gsub("%[WowSims: ([^%]|]+)%]", function(setName)
            return ("|cff00ccff|H%s:%s:%s|h[WowSims: %s]|h|r"):format(LINK_TYPE, sender, setName, setName)
        end))
    end)
    if ok and changed and changed ~= message then
        return false, changed, sender, ...
    end
    return false
end

function ChatLinks:Initialize(db)
    self.db = db
    if AceComm then
        AceComm:Embed(self)
        self:RegisterComm(PREFIX, OnComm)
    end
    if ChatFrame_AddMessageEventFilter then
        for _, event in ipairs(CHAT_EVENTS) do
            pcall(ChatFrame_AddMessageEventFilter, event, Filter)
        end
    end
    if SetItemRef then
        hooksecurefunc("SetItemRef", function(link)
            if type(link) ~= "string" or link:sub(1, #LINK_TYPE + 1) ~= LINK_TYPE .. ":" then return end
            local sender, setName = link:sub(#LINK_TYPE + 2):match("^([^:]+):(.+)$")
            if sender and setName then Request(sender, setName) end
        end)
    end
end

Env.AddOptions("chatLinks", 55, L["Chat links"], {
    enabled = Env.Toggle(1, L["Make [WowSims: ...] gear set links in chat clickable"],
        L["Clicking one asks the sender's WowSims for the set and opens it in the Import tab."],
        function() return ChatLinks:GetOptions().enabled end,
        function(value) ChatLinks:GetOptions().enabled = value end),
})

Env.ChatLinks = ChatLinks
Env.RegisterFeature(ChatLinks)
