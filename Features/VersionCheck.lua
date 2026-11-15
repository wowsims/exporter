-- Version check: WowSims users in your guild and group tell each other which version they run.
-- If someone has a newer one, you get one chat message per session telling you to update.
--
-- Messages use the addon prefix "WowSims": "V1:<version>", e.g. "V1:v4.0.0-test12".
-- - Sent to the guild a few seconds after login, and to the group when it changes (throttled).
-- - Someone with an older version gets a whisper back so they find out too (throttled per player).
-- - Nothing is sent in combat; the client's addon message limits are respected with pcall.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local L = Env.L

local VersionCheck = {}

local PREFIX = "WowSims"
local GROUP_THROTTLE = 15   -- seconds between group broadcasts
local REPLY_THROTTLE = 120  -- seconds between whispers to the same player
local LOGIN_DELAY = 8

local notified = false
local lastGroupSend = 0
local lastReply = {}
VersionCheck.seen = {} -- [player] = version, from this session

---"v4.0.0-test11" -> { 4, 0, 0, 11 }; a release (no -testN) sorts after every test of the same
---number. Returns nil for unpackaged builds such as "@project-version@".
---@param version string|nil
---@return number[]|nil
local function ParseVersion(version)
    if type(version) ~= "string" then return nil end
    local major, minor, patch = version:match("(%d+)%.(%d+)%.?(%d*)")
    if not major then return nil end
    local test = version:match("%-test(%d+)") or version:match("%-beta(%d+)") or version:match("%-alpha(%d+)")
    return { tonumber(major), tonumber(minor), tonumber(patch) or 0, test and tonumber(test) or math.huge }
end

---@return number 1 if a is newer, -1 if b is newer, 0 if equal or unknown.
local function Compare(a, b)
    local pa, pb = ParseVersion(a), ParseVersion(b)
    if not pa or not pb then return 0 end
    for i = 1, 4 do
        if pa[i] ~= pb[i] then return pa[i] > pb[i] and 1 or -1 end
    end
    return 0
end
VersionCheck.Compare = Compare

local function Send(channel, target, kind)
    if not ParseVersion(Env.VERSION) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local sendFn = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not sendFn then return end
    pcall(sendFn, PREFIX, (kind or "V1") .. ":" .. Env.VERSION, channel, target)
end

local function GroupChannel()
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid and IsInRaid() then
        return "RAID"
    elseif IsInGroup and IsInGroup() then
        return "PARTY"
    end
end

local function SendToGroup()
    local channel = GroupChannel()
    if not channel then return end
    local now = GetTime()
    if now - lastGroupSend < GROUP_THROTTLE then return end
    lastGroupSend = now
    Send(channel)
end

local function IsMe(sender)
    local short = Ambiguate and Ambiguate(sender, "none") or sender
    short = short:match("^[^%-]+") or short
    return short == UnitName("player")
end

local function OnAddonMessage(_, prefix, message, _, sender)
    if prefix ~= PREFIX or type(message) ~= "string" or not sender or IsMe(sender) then return end
    local kind, version = message:match("^([VQ])1:(.+)$")
    if not version then return end
    VersionCheck.seen[sender] = version
    if VersionCheck.onSeen then pcall(VersionCheck.onSeen, sender, version) end

    -- "Q1" asks everyone to answer with their version (the Group tab's "Who has WowSims").
    if kind == "Q" then
        local now = GetTime()
        if now - (lastReply[sender] or 0) >= 10 then
            lastReply[sender] = now
            Send("WHISPER", sender)
        end
    end

    local result = Compare(version, Env.VERSION)
    if result > 0 and not notified and VersionCheck:GetOptions().notify then
        notified = true
        Env.FeaturePrint(L["A newer WowSims is out: %s (you have %s). Update it from CurseForge."]:format(version, Env.VERSION))
    elseif result < 0 then
        local now = GetTime()
        if now - (lastReply[sender] or 0) >= REPLY_THROTTLE then
            lastReply[sender] = now
            Send("WHISPER", sender)
        end
    end
end

---Ask the group (or guild) who has WowSims; answers fill VersionCheck.seen.
---@param channel string|nil "GUILD", or nil for the current group.
function VersionCheck:Ping(channel)
    channel = channel or GroupChannel()
    if channel then Send(channel, nil, "Q1") end
end

---The version a player runs, if they've told us this session.
---@param name string Name as shown, with or without realm or surname.
---@return string|nil
function VersionCheck:GetVersion(name)
    if not name then return nil end
    local first = name:match("^[^%s%-]+")
    for sender, version in pairs(self.seen) do
        if sender == name or sender:match("^[^%s%-]+") == first then return version end
    end
end

---Print who in your guild or group has WowSims this session.
function VersionCheck:PrintSeen()
    local names = {}
    for name in pairs(self.seen) do table.insert(names, name) end
    table.sort(names)
    Env.FeaturePrint(L["You have %s."]:format(tostring(Env.VERSION)))
    if #names == 0 then
        Env.FeaturePrint(L["No other WowSims users seen yet this session."])
        return
    end
    for _, name in ipairs(names) do
        local version = self.seen[name]
        local color = Compare(version, Env.VERSION) > 0 and "|cff1eff00" or (Compare(version, Env.VERSION) < 0 and "|cff9d9d9d" or "|cffffffff")
        Env.FeaturePrint(("%s: %s%s|r"):format(Ambiguate and Ambiguate(name, "short") or name, color, version))
    end
end

---@return table options { notify = true }
function VersionCheck:GetOptions()
    local options = Env.GetOrCreateTable(self.db.global, "versionCheck")
    if options.notify == nil then options.notify = true end
    return options
end

function VersionCheck:Initialize(db, addon)
    self.db = db
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(PREFIX)
    end
    Env.RegisterFeatureEvent("CHAT_MSG_ADDON", OnAddonMessage)
    Env.RegisterFeatureEvent("GROUP_ROSTER_UPDATE", SendToGroup)

    if C_Timer and C_Timer.After then
        C_Timer.After(LOGIN_DELAY, function()
            if IsInGuild and IsInGuild() then Send("GUILD") end
            SendToGroup()
        end)
    end

    if addon and addon.RegisterChatCommand then
        addon:RegisterChatCommand("wsversion", function() VersionCheck:PrintSeen() end)
    end
end

Env.VersionCheck = VersionCheck
Env.AddOptions("version", 60, L["Updates"], {
    notify = Env.Toggle(1, L["Tell me when a newer WowSims is out"], nil,
        function() return VersionCheck:GetOptions().notify end,
        function(value) VersionCheck:GetOptions().notify = value end),
})

Env.RegisterFeature(VersionCheck)
