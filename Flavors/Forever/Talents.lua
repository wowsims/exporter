local Env = select(2, ...)
if not Env.IS_FOREVER then return end

-- The sim reads talents as a positional string: digit i of tree t is the i-th talent of tree t
-- in wowsims/forever ui/sim/talents/trees/<class>.json. Forever's client exposes talents through
-- C_Traits instead, so each tree is listed here by TraitDefinition ID in the sim's order.
-- Regenerate with tools/gen_forever_talents.py when the sim's trees change.
-- BEGIN GENERATED TALENTS
-- Source: wowsims/forever@8298ab833f02
local talentDefinitionIds = {
    DRUID = {
        { 134384, 134385, 134386, 134392, 134388, 134390, 134387, 134389, 134391, 134393, 134394, 142590, 134395, 134396, 134397, 134398 }, -- Balance
        { 134399, 134400, 134404, 134401, 134402, 134403, 134406, 134409, 134405, 134407, 134413, 134410, 134412, 134408, 134416, 134411, 134414, 134415, 134417, 145859 }, -- Feral Combat
        { 134418, 134419, 134383, 134381, 134380, 134378, 134377, 134379, 134376, 134375, 134373, 134382, 134372, 134370, 134374, 134371 }, -- Restoration
    },
    HUNTER = {
        { 134422, 134438, 134437, 134436, 134434, 134435, 134432, 134431, 134430, 134429, 134428, 134427, 134426, 134425, 134424, 134423 }, -- Beast Mastery
        { 134478, 134477, 134476, 142622, 134474, 134473, 134470, 134471, 134472, 134469, 134467, 134464, 134466, 134465, 134463, 134462 }, -- Marksmanship
        { 134461, 134460, 134459, 134458, 134457, 134455, 134456, 134452, 134451, 134453, 142607, 134454, 134448, 134450, 142606, 134446, 142605, 134449 }, -- Survival
    },
    MAGE = {
        { 135345, 135343, 135332, 135342, 135341, 135340, 135339, 135338, 135337, 135336, 135335, 135334, 135333, 145958, 135331, 135330, 135329, 135328 }, -- Arcane
        { 135326, 135325, 135324, 135323, 135322, 135319, 135321, 135320, 135327, 135318, 135317, 135316, 135315, 135314, 135313, 135312, 135311 }, -- Fire
        { 135310, 135309, 135308, 135307, 135304, 135305, 135306, 135302, 135301, 135297, 135300, 135299, 135298, 135295, 135296, 135294, 135293, 135292 }, -- Frost
    },
    PALADIN = {
        { 134830, 145961, 134828, 142623, 134829, 134822, 134820, 134824, 135234, 134819, 142625, 134825, 142624, 134818, 145962, 134816, 134815 }, -- Holy
        { 134827, 135151, 135163, 135162, 135157, 135150, 135158, 142626, 135155, 142630, 135159, 135161, 135164, 135153, 135152, 142631, 142627 }, -- Protection
        { 135237, 135236, 135235, 135233, 135231, 135232, 134826, 135226, 135229, 135228, 135230, 135227, 145960, 135224, 135223, 142634, 135222 }, -- Retribution
    },
    PRIEST = {
        { 142599, 135380, 135379, 135378, 142598, 135367, 135375, 135372, 135374, 135376, 135373, 135371, 135368, 135369, 135364, 135365, 135370, 135366 }, -- Discipline
        { 135397, 135396, 142601, 135394, 135393, 135392, 135391, 135390, 135389, 135388, 135387, 135386, 135385, 135384, 135383, 135382, 135381 }, -- Holy
        { 142597, 135362, 135363, 135361, 135360, 135359, 135358, 135356, 135355, 135353, 135350, 135351, 135354, 135349, 142600, 135348, 135347 }, -- Shadow
    },
    ROGUE = {
        { 135272, 135253, 135252, 135251, 135247, 135269, 135250, 135248, 135246, 135244, 135245, 135243, 145964, 135242, 135241, 135240, 135239 }, -- Assassination
        { 135238, 135271, 145370, 135249, 135268, 135267, 135262, 135266, 135265, 135289, 135263, 138268, 135256, 135260, 145965, 135258, 135257, 135270, 135254 }, -- Combat
        { 135281, 135291, 135290, 135275, 135286, 135279, 135287, 135285, 135273, 135282, 135283, 135284, 142619, 135277, 135276, 135278, 135280, 142618 }, -- Subtlety
    },
    SHAMAN = {
        { 134234, 134233, 134230, 134228, 134232, 134231, 134229, 134226, 134225, 134224, 134223, 134222, 134221, 134220, 134227, 134219 }, -- Elemental
        { 134218, 134214, 134217, 134215, 134216, 134212, 134211, 134210, 134209, 134207, 134208, 134204, 134213, 134206, 134205, 134203, 134202, 134201 }, -- Enhancement
        { 134200, 134190, 134195, 134197, 134196, 134198, 134192, 134194, 134193, 134199, 134191, 134189, 134188, 134187, 134186, 134185 }, -- Restoration
    },
    WARLOCK = {
        { 135452, 135456, 135455, 135454, 135453, 135451, 135450, 135449, 135447, 135448, 142628, 135445, 135444, 135443, 135442, 135441, 135440 }, -- Affliction
        { 135436, 135439, 135438, 135437, 135433, 135435, 135434, 135430, 135432, 135431, 135429, 135428, 135426, 135427, 135425, 135423, 135424, 135422, 135421 }, -- Demonology
        { 135412, 135420, 135419, 135416, 135418, 135417, 135414, 135415, 135413, 135410, 135411, 135409, 135407, 135408, 135406, 135405 }, -- Destruction
    },
    WARRIOR = {
        { 135489, 135488, 135487, 135486, 135485, 135483, 135482, 135481, 135480, 135479, 135478, 141974, 135476, 135475, 142604, 135473, 135472 }, -- Arms
        { 135469, 135470, 142603, 135468, 135484, 135466, 135465, 135462, 135464, 145966, 135463, 135509, 135458, 145863, 135457, 135508, 135459, 135461 }, -- Fury
        { 135505, 135507, 145864, 135506, 135500, 135503, 135501, 135502, 135498, 142602, 135499, 135497, 135494, 135495, 135496, 135492, 135493, 135490 }, -- Protection
    },
}
-- END GENERATED TALENTS

---Get the active talent config. C_ClassTalents is the documented API; the spec group lookup is a fallback.
---@return integer|nil configID nil if the client has no talent config API.
local function GetActiveTalentConfigID()
    if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        return C_ClassTalents.GetActiveConfigID()
    end
    if C_SpecializationInfo and C_SpecializationInfo.GetCombatConfigIDForSpecGroup then
        local specGroup = C_SpecializationInfo.GetActiveSpecGroup and C_SpecializationInfo.GetActiveSpecGroup() or 1
        return C_SpecializationInfo.GetCombatConfigIDForSpecGroup(specGroup)
    end
    return nil
end

-- The retail client keeps an inspected player's talents in a special config, the one Blizzard's own
-- inspect talent window reads. It holds data after NotifyInspect(unit) and INSPECT_READY, until the
-- inspect is cleared. -1 is the value of the constant on retail clients, used if it isn't defined.
local INSPECT_CONFIG_ID = Constants and Constants.TraitConsts
    and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1

-- Set while counting points for spec detection, so AddSpec checks that read ranks
-- (Env.GetForeverTalentRanks) read the same player as the count.
local countingInspect = false

---Whether spec detection is currently counting an inspected player's talents.
---@return boolean
function Env.IsForeverCountingInspect()
    return countingInspect
end

---Get the config ID to read talents from.
---@param isInspect boolean|nil
---@return integer|nil configID
local function GetTalentConfigID(isInspect)
    if isInspect then return INSPECT_CONFIG_ID end
    return GetActiveTalentConfigID()
end

---Get the ranks of all purchased talents in the active spec group, or of the inspected player.
---Returns nil instead of failing when talents can't be read, so the rest of the export still works.
---@param isInspect boolean|nil Read the inspected player instead of the player.
---@return table<integer, integer>|nil ranks TraitDefinition ID to rank, nil if the client has no talent data yet.
function Env.GetForeverTalentRanks(isInspect)
    if not C_Traits then return nil end
    local configID = GetTalentConfigID(isInspect)
    if not configID then return nil end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs then return nil end

    local ranks = {}
    for _, treeID in ipairs(configInfo.treeIDs) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
            local node = C_Traits.GetNodeInfo(configID, nodeID)
            -- currentRank also counts ranks granted without spending points.
            local rank = node and (node.currentRank or node.ranksPurchased) or 0
            if rank > 0 and node.activeEntry then
                local entry = C_Traits.GetEntryInfo(configID, node.activeEntry.entryID)
                if entry and entry.definitionID then
                    ranks[entry.definitionID] = rank
                end
            end
        end
    end
    return ranks
end

---Get a player's talent ranks laid out like the sim's trees.
---@param isInspect boolean|nil Read the inspected player (Env.inspectUnit) instead of the player.
---@return integer[][] points Rank per talent, [treeIdx][talentIdx]. Empty if no talent data is available.
local function GetTalentPoints(isInspect)
    local unit = isInspect and Env.inspectUnit or "player"
    local trees = talentDefinitionIds[select(2, UnitClass(unit))]
    local ranks = Env.GetForeverTalentRanks(isInspect)
    if not trees or not ranks then return {} end

    local points = {}
    for treeIdx, definitionIds in ipairs(trees) do
        points[treeIdx] = {}
        for talentIdx, definitionId in ipairs(definitionIds) do
            points[treeIdx][talentIdx] = ranks[definitionId] or 0
        end
    end
    return points
end

---Create a talent string in the sim's format, e.g. "0500032-05-3". Trailing zeroes of each tree
---and trailing dashes are trimmed, the same as the sim serializes it.
---@param isInspect boolean|nil Read the inspected player instead of the player.
---@return string
function Env.CreateForeverTalentString(isInspect)
    local treeStrings = {}
    for treeIdx, tree in ipairs(GetTalentPoints(isInspect)) do
        treeStrings[treeIdx] = (table.concat(tree):gsub("0+$", ""))
    end
    return (table.concat(treeStrings, "-"):gsub("%-+$", ""))
end

---Counts spent talent points per tree.
---@param unit string|nil "player" or the inspected unit.
---@return table pointsPerTreeTable { tree1Count, tree2Count, tree3Count }
function Env.CountForeverPointsPerTree(unit)
    local isInspect = unit ~= nil and unit ~= "player"
    countingInspect = isInspect
    local counts = { 0, 0, 0 }
    for treeIdx, tree in ipairs(GetTalentPoints(isInspect)) do
        for _, rank in ipairs(tree) do
            counts[treeIdx] = counts[treeIdx] + rank
        end
    end
    return counts
end

---Describe what the client gives for an inspected player's talents, for /wse inspectdebug.
---@return string[] lines
function Env.DescribeForeverInspectTalents()
    local lines = {}
    local function add(text) table.insert(lines, text) end
    if not C_Traits then
        add("C_Traits: missing")
        return lines
    end
    add(("Inspect config ID: %s"):format(tostring(INSPECT_CONFIG_ID)))
    local configInfo = C_Traits.GetConfigInfo(INSPECT_CONFIG_ID)
    if not configInfo then
        add("GetConfigInfo: nil (no inspect talent data from the client)")
        return lines
    end
    local treeIDs = configInfo.treeIDs or {}
    add(("Trees: %d (%s)"):format(#treeIDs, table.concat(treeIDs, ", ")))
    local nodeCount = 0
    for _, treeID in ipairs(treeIDs) do
        nodeCount = nodeCount + #(C_Traits.GetTreeNodes(treeID) or {})
    end
    add(("Nodes: %d"):format(nodeCount))
    local ranks = Env.GetForeverTalentRanks(true) or {}
    local known, unknown, total = 0, 0, 0
    local class = select(2, UnitClass(Env.inspectUnit or "target"))
    local inSim = {}
    for _, tree in ipairs(talentDefinitionIds[class] or {}) do
        for _, definitionId in ipairs(tree) do inSim[definitionId] = true end
    end
    for definitionId, rank in pairs(ranks) do
        total = total + rank
        if inSim[definitionId] then known = known + 1 else unknown = unknown + 1 end
    end
    add(("Talents with points: %d in the sim's trees, %d not (%d points)"):format(known, unknown, total))
    add(("Talent string: %s"):format(Env.CreateForeverTalentString(true)))
    return lines
end

---Split a sim talent string ("0500032-05-3") into one rank string per tree.
---@param talentString string
---@return string[]
local function SplitTalentString(talentString)
    local trees = {}
    for tree in (talentString .. "-"):gmatch("([^-]*)-") do
        table.insert(trees, tree)
    end
    return trees
end

---Map each talent definition of the active config to the node and entry that buy it.
---@param configID integer
---@param configInfo table
---@return table<integer, table> nodeByDefinition { nodeID, entryID, isChoice }
local function MapDefinitionsToNodes(configID, configInfo)
    local nodeByDefinition = {}
    for _, treeID in ipairs(configInfo.treeIDs or {}) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
            local node = C_Traits.GetNodeInfo(configID, nodeID)
            local entryIDs = node and node.entryIDs or {}
            for _, entryID in ipairs(entryIDs) do
                local entry = C_Traits.GetEntryInfo(configID, entryID)
                if entry and entry.definitionID then
                    nodeByDefinition[entry.definitionID] = {
                        nodeID = nodeID, entryID = entryID, isChoice = #entryIDs > 1,
                    }
                end
            end
        end
    end
    return nodeByDefinition
end

---Ranks the player has bought in a node for one entry.
local function PurchasedRanks(configID, target)
    local node = C_Traits.GetNodeInfo(configID, target.nodeID)
    if not node then return 0 end
    if target.isChoice and not (node.activeEntry and node.activeEntry.entryID == target.entryID) then
        return 0
    end
    return node.ranksPurchased or 0
end

local function CommitTalents(configID)
    if C_ClassTalents and C_ClassTalents.CommitConfig then
        local ok, result = pcall(C_ClassTalents.CommitConfig)
        if ok and result then return true end
    end
    local ok, result = pcall(C_Traits.CommitConfig, configID)
    return ok and result
end

---Whether the player has learned dual specialization (a second talent group).
---@return boolean
local function HasDualSpec()
    for _, getCount in ipairs({ GetNumTalentGroups, GetNumSpecGroups }) do
        if getCount then
            local ok, count = pcall(getCount)
            if ok and count and count > 1 then return true end
        end
    end
    return false
end

---Learn the talents of a sim talent string with the player's unspent points. Only works out of
---combat. Talents can't be unlearned outside a class trainer, so a build that needs points moved
---is refused with directions instead of resetting anything.
---@param talentString string
---@return boolean ok
---@return string message For the player.
function Env.ApplyForeverTalentString(talentString)
    if InCombatLockdown() then return false, "You can't change talents in combat." end
    if not C_Traits then return false, "This client has no talent API." end
    local trees = talentDefinitionIds[select(2, UnitClass("player"))]
    local configID = GetActiveTalentConfigID()
    local configInfo = configID and C_Traits.GetConfigInfo(configID)
    if not trees or not configInfo then return false, "Your talents can't be read right now." end

    local nodeByDefinition = MapDefinitionsToNodes(configID, configInfo)
    local wanted, wantedRank, unknown = {}, {}, 0
    local treeStrings = SplitTalentString(talentString or "")
    for treeIdx, definitionIds in ipairs(trees) do
        local ranks = treeStrings[treeIdx] or ""
        for talentIdx, definitionId in ipairs(definitionIds) do
            local rank = tonumber(ranks:sub(talentIdx, talentIdx)) or 0
            if rank > 0 then
                if nodeByDefinition[definitionId] then
                    table.insert(wanted, { target = nodeByDefinition[definitionId], rank = rank })
                    wantedRank[definitionId] = rank
                else
                    unknown = unknown + 1
                end
            end
        end
    end
    if #wanted == 0 then return false, "That talent string has no talents for your class." end

    local current = Env.GetForeverTalentRanks() or {}
    local needsReset = false
    for definitionId, rank in pairs(current) do
        if rank > (wantedRank[definitionId] or 0) then needsReset = true end
    end
    if needsReset then
        local message = "Your current talents don't fit this build, and talents can only be reset at a class trainer. "
            .. "Visit your class trainer to reset your talents, then apply the build again."
        if HasDualSpec() then
            message = message .. " Or switch to your other specialization and apply it there."
        end
        return false, message
    end

    -- Buy in tree order, in passes, so a talent locked behind tier points or a prerequisite
    -- gets bought once those are in.
    local progress, passes = true, 0
    while progress and passes < 60 do
        progress, passes = false, passes + 1
        for _, want in ipairs(wanted) do
            local target = want.target
            local have = PurchasedRanks(configID, target)
            if target.isChoice and have == 0 then
                if C_Traits.SetSelection(configID, target.nodeID, target.entryID) then
                    progress = true
                    have = PurchasedRanks(configID, target)
                end
            end
            while have < want.rank and C_Traits.PurchaseRank(configID, target.nodeID) do
                have = have + 1
                progress = true
            end
        end
    end

    local learned, total = 0, 0
    for _, want in ipairs(wanted) do
        total = total + want.rank
        learned = learned + math.min(want.rank, PurchasedRanks(configID, want.target))
    end
    if learned == 0 then
        if C_Traits.RollbackConfig then C_Traits.RollbackConfig(configID) end
        return false, "No talents could be learned. Do you have unspent points?"
    end
    if not CommitTalents(configID) then
        return false, "The game didn't accept the talent change."
    end

    local message = ("Learned %d of %d talent points."):format(learned, total)
    if learned < total then
        message = message .. " The rest need more levels or points."
    end
    if unknown > 0 then
        message = message .. (" %d talents in the string aren't in your trees."):format(unknown)
    end
    return true, message
end

---Lay out a talent string as a class's trees, for showing it like the talent window.
---Uses the trees built into the addon (Flavors/Forever/TalentTrees.lua), so it works for any class.
---@param talentString string
---@param classFile string|nil e.g. "MAGE"; the player's class if nil.
---@return table[]|nil trees { name, columns, rows, cells = { { row, column, spellID, icon, rank, maxRank, name } } }
---@return string|nil error
function Env.GetForeverTalentLayout(talentString, classFile)
    classFile = (classFile or select(2, UnitClass("player"))):upper()
    local trees = Env.ForeverTalentTrees and Env.ForeverTalentTrees[classFile]
    if not trees then return nil, ("No talent trees for %s."):format(classFile) end

    local treeStrings = SplitTalentString(talentString or "")
    local getTexture = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
    local layout = {}
    for treeIdx, treeData in ipairs(trees) do
        local tree = { name = treeData.name, cells = {}, rows = 0, columns = 4 }
        local ranks = treeStrings[treeIdx] or ""
        for talentIdx, talent in ipairs(treeData.talents) do
            local row, column, spellID, maxRank, name = talent[1], talent[2], talent[3], talent[4], talent[5]
            table.insert(tree.cells, {
                row = row, column = column, name = name,
                spellID = spellID ~= 0 and spellID or nil,
                icon = (spellID ~= 0 and getTexture(spellID)) or 134400,
                rank = tonumber(ranks:sub(talentIdx, talentIdx)) or 0,
                maxRank = maxRank,
                prereqRow = talent[6],
                prereqColumn = talent[7],
            })
            tree.rows = math.max(tree.rows, row)
            tree.columns = math.max(tree.columns, column)
        end
        table.insert(layout, tree)
    end
    return layout
end
