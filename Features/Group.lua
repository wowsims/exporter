-- Group tab (Forever): see who in your group has WowSims and ask everyone for their exports at
-- once. No inspect range needed; exports arrive in the Inspect tab's history.
--
-- Messages go through AceComm (split and throttled) with the prefix "WowSimsSync":
--   "REQ"         asks the group or guild for exports. Only answered from GUILD/PARTY/RAID/INSTANCE.
--   "EXP\t<json>" an export, whispered back. Only kept if we asked in the last few minutes.
-- Sharing can be turned off: WSEDB.global.groupSync = { share = true }.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local AceGUI = LibStub("AceGUI-3.0")
local AceComm = LibStub("AceComm-3.0", true)
local L = Env.L

local Group = {}

local PREFIX = "WowSimsSync"
local ANSWER_WINDOW = 180 -- seconds after asking that exports are accepted
local ASK_THROTTLE = 20
local ALLOWED_REQUEST_CHANNELS = { GUILD = true, PARTY = true, RAID = true, INSTANCE_CHAT = true }

local lastAsk = 0
local pendingReplies = {} -- senders to answer once combat ends
local received = {}       -- [name] = time, this session
local refreshTab          -- set while the tab is open

function Group:GetOptions()
    local options = Env.GetOrCreateTable(self.db.global, "groupSync")
    if options.share == nil then options.share = true end
    return options
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

local function Send(message, channel, target)
    if not AceComm then return false end
    local ok = pcall(AceComm.SendCommMessage, Group, PREFIX, message, channel, target, "BULK")
    return ok
end

local function Refresh()
    if refreshTab then refreshTab() end
end

---Ask the group (or the guild) for their exports.
---@param channel string|nil "GUILD", or nil for the current group.
function Group:Ask(channel)
    channel = channel or GroupChannel()
    if not channel then
        Env.FeaturePrint(L["You're not in a group."])
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        Env.FeaturePrint(L["Try again out of combat."])
        return
    end
    local now = GetTime()
    if now - lastAsk < ASK_THROTTLE then
        Env.FeaturePrint(L["Please wait a few seconds before asking again."])
        return
    end
    lastAsk = now
    if Send("REQ", channel) then
        Env.FeaturePrint(L["Asked for exports. They'll show up in the Inspect tab as they arrive."])
    end
    if Env.VersionCheck then Env.VersionCheck:Ping(channel) end
end

local function Answer(sender)
    if InCombatLockdown and InCombatLockdown() then
        pendingReplies[sender] = true
        return
    end
    local json = Group.addon and Group.addon:BuildExport(false, true)
    if json and Send("EXP\t" .. json, "WHISPER", sender) then
        Env.FeaturePrint(L["Sent your export to %s."]:format(Ambiguate and Ambiguate(sender, "short") or sender))
    end
end

local function IsMe(sender)
    local short = Ambiguate and Ambiguate(sender, "none") or sender
    return (short:match("^[^%-]+") or short) == UnitName("player")
end

local function OnComm(_, message, distribution, sender)
    if type(message) ~= "string" or not sender or IsMe(sender) then return end
    if message == "REQ" then
        if ALLOWED_REQUEST_CHANNELS[distribution] and Group:GetOptions().share then Answer(sender) end
        return
    end
    local json = message:match("^EXP\t(.+)$")
    if json and distribution == "WHISPER" and GetTime() - lastAsk <= ANSWER_WINDOW then
        local data = Env.Encoding and Env.Encoding.DecodeJSON(json)
        if type(data) ~= "table" or type(data.name) ~= "string" then return end
        local inspect = Env.InspectFeature
        if inspect and inspect.AddToHistory and inspect.db then
            inspect.AddToHistory(json, { name = data.name, class = data.class, level = data.level })
        end
        received[data.name] = time()
        received[(data.name:match("^%S+"))] = time()
        Refresh()
    end
end

---Members of the current group, without the player: { name, unit, classFile }.
local function GetMembers()
    local members = {}
    local count = GetNumGroupMembers and GetNumGroupMembers() or 0
    local prefix = IsInRaid and IsInRaid() and "raid" or "party"
    local last = prefix == "raid" and count or count - 1
    for i = 1, last do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local name, extra = UnitName(unit)
            -- Forever: the second name part is the surname.
            if Env.Flavor.namesHaveSurnames and extra and extra ~= "" then name = name .. " " .. extra end
            local _, classFile = UnitClass(unit)
            table.insert(members, { name = name, unit = unit, classFile = classFile })
        end
    end
    table.sort(members, function(a, b) return a.name < b.name end)
    return members
end

local function CreateTab(container)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    local function Build()
        scroll:ReleaseChildren()
        local inspect = Env.InspectFeature

        local ask = Env.AddSection(scroll, L["Ask for exports"])
        Env.AddHint(ask, L["Everyone in your group or guild with WowSims sends you their export, from anywhere. They arrive in the Inspect tab's history, ready to copy into the sim."])
        local function AddButton(parent, text, width, onClick, disabled)
            local button = AceGUI:Create("Button")
            button:SetText(text)
            button:SetWidth(width)
            button:SetDisabled(disabled and true or false)
            button:SetCallback("OnClick", onClick)
            parent:AddChild(button)
        end
        AddButton(ask, L["Ask my group"], 150, function() Group:Ask() end, not GroupChannel())
        AddButton(ask, L["Ask my guild"], 150, function() Group:Ask("GUILD") end, not (IsInGuild and IsInGuild()))
        if inspect and inspect.tab then
            AddButton(ask, L["Open Inspect history"], 170, function() container:SelectTab(inspect.tab.value) end)
        end

        local share = AceGUI:Create("CheckBox")
        share:SetLabel(L["Share my export when my group or guild asks"])
        share:SetFullWidth(true)
        share:SetValue(Group:GetOptions().share)
        share:SetCallback("OnValueChanged", function(_, _, value) Group:GetOptions().share = value end)
        ask:AddChild(share)

        local members = GetMembers()
        local roster = Env.AddSection(scroll, L["Your group (%d)"]:format(#members))
        if #members == 0 then
            Env.AddHint(roster, L["Join a group to see who has WowSims."])
        else
            for _, member in ipairs(members) do
                local row = AceGUI:Create("SimpleGroup")
                row:SetFullWidth(true)
                row:SetLayout("Flow")
                roster:AddChild(row)
                if inspect and inspect.AddClassIcon then inspect.AddClassIcon(row, member.classFile, 22) end

                local version = Env.VersionCheck and Env.VersionCheck:GetVersion(member.name)
                local gotAt = received[member.name] or received[(member.name:match("^%S+"))]
                local status
                if gotAt then
                    status = "|cff1eff00" .. L["Export received"] .. "|r  |cff9d9d9d" .. Env.Ago(gotAt) .. "|r"
                elseif version then
                    status = "|cffffd100WowSims " .. version .. "|r"
                else
                    status = "|cff9d9d9d" .. L["No WowSims seen"] .. "|r"
                end
                local name = inspect and inspect.ClassColored and inspect.ClassColored(member.name, member.classFile) or member.name
                local label = AceGUI:Create("Label")
                label:SetText(("%s\n%s"):format(name, status))
                label:SetWidth(300)
                row:AddChild(label)
            end
        end

        AddButton(scroll, L["Who has WowSims?"], 170, function()
            if Env.VersionCheck then Env.VersionCheck:Ping() end
            C_Timer.After(3, Refresh)
        end, not GroupChannel())
        scroll:DoLayout()
    end

    -- Rebuild only while this tab's scroll frame is still the one on screen (widgets are pooled).
    refreshTab = function()
        if container.children and container.children[1] == scroll and scroll.frame:IsShown() then
            Build()
        else
            refreshTab = nil
        end
    end
    Build()
end

Group.tab = { value = "group", text = L["Group"], Create = CreateTab }

function Group:Initialize(db, addon)
    self.db = db
    self.addon = addon
    if AceComm then
        AceComm:Embed(self)
        self:RegisterComm(PREFIX, OnComm)
    end
    Env.RegisterFeatureEvent("PLAYER_REGEN_ENABLED", function()
        for sender in pairs(pendingReplies) do
            pendingReplies[sender] = nil
            Answer(sender)
        end
    end)
    Env.RegisterFeatureEvent("GROUP_ROSTER_UPDATE", Refresh)
    if Env.VersionCheck then
        Env.VersionCheck.onSeen = function() Refresh() end
    end
end

Env.GroupFeature = Group
Env.RegisterFeature(Group)
