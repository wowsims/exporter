#!/usr/bin/env node
// Checks the WoW Forever talent export in Flavors/Forever/Flavor.lua against wowsims/forever.
//
// Every talent string in the sim's spec presets and saved builds (ui/specs/<class>/**), plus one
// build per class with every talent maxed, is turned into mocked C_Traits data built from the sim's
// tree files. The addon's export must give back the same string the sim would write, and the same
// points per tree.
//
// Usage: node tools/test/forever_talents.js <path to wowsims/forever checkout>

const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const CLASSES = ['druid', 'hunter', 'mage', 'paladin', 'priest', 'rogue', 'shaman', 'warlock', 'warrior'];
const TALENTS_STRING = /talentsString"?\s*:\s*['"]([0-9-]*)['"]/g;

const foreverDir = process.argv[2];
if (!foreverDir) {
	console.error('Usage: node tools/test/forever_talents.js <path to wowsims/forever checkout>');
	process.exit(2);
}
const addonFile = path.join(__dirname, '..', '..', 'Flavors', 'Forever', 'Flavor.lua');

// Same rules as the sim's ui/sim/talents/talents_string.ts.
const parseTalentsString = (trees, talentsString) => {
	const treeStrings = talentsString.split('-');
	return trees.map((tree, treeIdx) =>
		tree.talents.map((talent, talentIdx) => {
			const raw = Number((treeStrings[treeIdx] ?? '').charAt(talentIdx));
			return Number.isFinite(raw) ? Math.min(talent.maxPoints, Math.max(0, raw)) : 0;
		}),
	);
};
const serializeTalentsString = points =>
	points
		.map(tree => tree.join('').replace(/0+$/g, ''))
		.join('-')
		.replace(/-+$/g, '');

const findFiles = (dir, test) =>
	fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) return findFiles(full, test);
		return test(entry.name) ? [full] : [];
	});

const collectTalentStrings = cls => {
	const specDir = path.join(foreverDir, 'ui', 'specs', cls);
	if (!fs.existsSync(specDir)) return [];
	const files = findFiles(specDir, name => name === 'presets.ts' || name.endsWith('.build.json'));
	const strings = new Set();
	for (const file of files) {
		for (const match of fs.readFileSync(file, 'utf8').matchAll(TALENTS_STRING)) {
			if (match[1] !== '') strings.add(match[1]);
		}
	}
	return [...strings];
};

// One Lua state with the addon file loaded. MOCK_CLASS and MOCK_NODES are set per case.
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const prelude = `
UnitClass = function() return MOCK_CLASS, MOCK_CLASS end
C_SpecializationInfo = {
    GetActiveSpecGroup = function() return 1 end,
    GetCombatConfigIDForSpecGroup = function() return 1 end,
}
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1 } } end,
    GetTreeNodes = function()
        local ids = {}
        for i = 1, #MOCK_NODES do ids[i] = i end
        return ids
    end,
    GetNodeInfo = function(_, nodeID)
        local node = MOCK_NODES[nodeID]
        return { ranksPurchased = node.rank, currentRank = node.rank, activeEntry = { entryID = nodeID } }
    end,
    GetEntryInfo = function(_, entryID) return { definitionID = MOCK_NODES[entryID].definitionID } end,
}
Env = {
    IS_FOREVER = true,
    AddSpec = function() end,
    TableMaxValIndex = function(t)
        local idxMax = 1
        for i = 2, #t do if t[i] > t[idxMax] then idxMax = i end end
        return idxMax
    end,
}
local chunk = assert(loadfile(...))
chunk("WowSimsExporter", Env)
`;
if (lauxlib.luaL_loadstring(L, to_luastring(prelude)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
lua.lua_pushstring(L, to_luastring(addonFile));
if (lua.lua_pcall(L, 1, 0, 0) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));

const runExport = (cls, nodes) => {
	const nodeList = nodes.map(n => `{ definitionID = ${n.definitionID}, rank = ${n.rank} }`).join(',\n');
	const code = `
MOCK_CLASS = "${cls.toUpperCase()}"
MOCK_NODES = { ${nodeList} }
local counts = Env.CountForeverPointsPerTree()
return Env.CreateForeverTalentString(), table.concat(counts, ",")
`;
	if (lauxlib.luaL_loadstring(L, to_luastring(code)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
	if (lua.lua_pcall(L, 0, 2, 0) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
	const result = { talents: lua.lua_tojsstring(L, -2), counts: lua.lua_tojsstring(L, -1) };
	lua.lua_pop(L, 2);
	return result;
};

// Deterministic shuffle so node order from the client never matters.
const shuffle = (items, seed) => {
	const out = [...items];
	let state = seed;
	for (let i = out.length - 1; i > 0; i--) {
		state = (state * 1103515245 + 12345) % 2147483648;
		const j = state % (i + 1);
		[out[i], out[j]] = [out[j], out[i]];
	}
	return out;
};

let passed = 0;
const failures = [];
for (const cls of CLASSES) {
	const trees = JSON.parse(fs.readFileSync(path.join(foreverDir, 'ui', 'sim', 'talents', 'trees', `${cls}.json`), 'utf8'));
	const maxed = serializeTalentsString(trees.map(tree => tree.talents.map(t => t.maxPoints)));
	const cases = [...collectTalentStrings(cls).map(s => ({ name: s, input: s })), { name: 'every talent maxed', input: maxed }];

	for (const [caseIdx, { name, input }] of cases.entries()) {
		const points = parseTalentsString(trees, input);
		// Every talent is a node, unpurchased ones at rank 0, as the client lists them.
		const nodes = trees.flatMap((tree, treeIdx) =>
			tree.talents.map((talent, talentIdx) => ({ definitionID: talent.definitionId, rank: points[treeIdx][talentIdx] })),
		);
		const expected = {
			talents: serializeTalentsString(points),
			counts: points.map(tree => tree.reduce((sum, rank) => sum + rank, 0)).join(','),
		};
		const got = runExport(cls, shuffle(nodes, caseIdx + 1));
		if (got.talents === expected.talents && got.counts === expected.counts) {
			passed++;
		} else {
			failures.push(`${cls} (${name}): expected ${expected.talents} [${expected.counts}], got ${got.talents} [${got.counts}]`);
		}
	}
}

for (const failure of failures) console.log(`FAIL ${failure}`);
console.log(`${passed} passed, ${failures.length} failed`);
process.exit(failures.length === 0 ? 0 : 1);
