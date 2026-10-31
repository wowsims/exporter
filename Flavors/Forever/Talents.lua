local Env = select(2, ...)
if not Env.IS_FOREVER then return end

-- The sim reads talents as a positional string: digit i of tree t is the i-th talent of tree t
-- in wowsims/forever ui/sim/talents/trees/<class>.json. Forever's client exposes talents through
-- C_Traits instead, so each tree is listed here by TraitDefinition ID in the sim's order.
-- Regenerate with tools/gen_forever_talents.py when the sim's trees change.
-- BEGIN GENERATED TALENTS
-- Source: wowsims/forever@eca41cc7ce8f
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
        { 135164, 134827, 134828, 134830, 134829, 134826, 134825, 142623, 134822, 142625, 134824, 134820, 134819, 134818, 142624, 134816, 134815 }, -- Holy
        { 135155, 135151, 135163, 135162, 135161, 142627, 135159, 142626, 135157, 142630, 135154, 135158, 135150, 135152, 142631, 135153 }, -- Protection
        { 135237, 135236, 135235, 135234, 135233, 135232, 135231, 135226, 135229, 135228, 135230, 135227, 135223, 135224, 142634, 142632, 135222 }, -- Retribution
    },
    PRIEST = {
        { 142599, 135380, 135379, 135378, 142598, 135367, 135375, 135372, 135374, 135376, 135373, 135371, 135368, 135369, 135364, 135365, 135370, 135366 }, -- Discipline
        { 135397, 135396, 142601, 135394, 135393, 135392, 135391, 135390, 135389, 135388, 135387, 135386, 135385, 135384, 135383, 135382, 135381 }, -- Holy
        { 142597, 135362, 135363, 135361, 135360, 135359, 135358, 135356, 135355, 135353, 135350, 135351, 135354, 135349, 142600, 135348, 135347 }, -- Shadow
    },
    ROGUE = {
        { 135272, 135253, 135252, 135251, 135250, 135269, 135289, 135247, 135246, 135244, 135245, 135243, 135248, 135239, 135241, 135240, 135242 }, -- Assassination
        { 135238, 135271, 145370, 135249, 135268, 135267, 135266, 135265, 135262, 135263, 138268, 135270, 135258, 135257, 135256, 135260, 135254 }, -- Combat
        { 135286, 135291, 135290, 135281, 135283, 135287, 135279, 135285, 135284, 142620, 135277, 135273, 135282, 135275, 135276, 135278, 142619, 135280, 142618 }, -- Subtlety
    },
    SHAMAN = {
        { 134234, 134233, 134230, 134228, 134232, 134231, 134229, 134226, 134225, 134224, 134223, 134222, 134221, 134220, 134227, 134219 }, -- Elemental
        { 134218, 134214, 134217, 134215, 134216, 134213, 134212, 134211, 134210, 134209, 134207, 134208, 134204, 134206, 134205, 134203, 134202, 134201 }, -- Enhancement
        { 134200, 134190, 134195, 134197, 134196, 134198, 134192, 134194, 134193, 134199, 134191, 134189, 134188, 134187, 134186, 134185 }, -- Restoration
    },
    WARLOCK = {
        { 135452, 135456, 135455, 135454, 135453, 135451, 135450, 135449, 135447, 135448, 142628, 135445, 135444, 135443, 135442, 135441, 135440 }, -- Affliction
        { 135436, 135439, 135438, 135437, 135433, 135435, 135434, 135430, 135432, 135431, 135429, 135428, 135426, 135427, 135425, 135423, 135424, 135422, 135421 }, -- Demonology
        { 135412, 135420, 135419, 135416, 135418, 135417, 135414, 135415, 135413, 135410, 135411, 135409, 135407, 135408, 135406, 135405 }, -- Destruction
    },
    WARRIOR = {
        { 135489, 135488, 135487, 135486, 135485, 135483, 135482, 135481, 135480, 135479, 135478, 141974, 135476, 135475, 142604, 135473, 135472 }, -- Arms
        { 135469, 135470, 142603, 135468, 135484, 135466, 135465, 135464, 135508, 135462, 135463, 135509, 135458, 135457, 135459, 145863, 135461 }, -- Fury
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

---Get the ranks of all purchased talents in the active spec group.
---Returns nil instead of failing when talents can't be read, so the rest of the export still works.
---@return table<integer, integer>|nil ranks TraitDefinition ID to rank, nil if the client has no talent data yet.
function Env.GetForeverTalentRanks()
    if not C_Traits then return nil end
    local configID = GetActiveTalentConfigID()
    if not configID then return nil end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not configInfo or not configInfo.treeIDs then return nil end

    local ranks = {}
    for _, treeID in ipairs(configInfo.treeIDs) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
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

---Get the player's talent ranks laid out like the sim's trees.
---@return integer[][] points Rank per talent, [treeIdx][talentIdx]. Empty if no talent data is available.
local function GetTalentPoints()
    local trees = talentDefinitionIds[select(2, UnitClass("player"))]
    local ranks = Env.GetForeverTalentRanks()
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
---@return string
function Env.CreateForeverTalentString()
    local treeStrings = {}
    for treeIdx, tree in ipairs(GetTalentPoints()) do
        treeStrings[treeIdx] = (table.concat(tree):gsub("0+$", ""))
    end
    return (table.concat(treeStrings, "-"):gsub("%-+$", ""))
end

---Counts spent talent points per tree.
---@return table pointsPerTreeTable { tree1Count, tree2Count, tree3Count }
function Env.CountForeverPointsPerTree()
    local counts = { 0, 0, 0 }
    for treeIdx, tree in ipairs(GetTalentPoints()) do
        for _, rank in ipairs(tree) do
            counts[treeIdx] = counts[treeIdx] + rank
        end
    end
    return counts
end
