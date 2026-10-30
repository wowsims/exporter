#!/usr/bin/env node
// Snapshot test for every game version the addon supports.
//
// For each flavor, loads the addon's files in TOC order (honouring AllowLoadGameType) into fengari
// with the fake client in wow_mock.lua, runs the login and export flows, and compares the result
// with snapshots/<flavor>.txt. Pass --update to rewrite the snapshots after an intended change.
//
// Usage: node tools/test/snapshots.js [--update]

const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..', '..');
const SNAPSHOT_DIR = path.join(__dirname, 'snapshots');
const update = process.argv.includes('--update');

// Flavor -> the AllowLoadGameType value its client loads.
const FLAVORS = {
	era: 'vanilla',
	sod: 'vanilla',
	tbc: 'tbc',
	wrath: 'wrath',
	cata: 'cata',
	mists: 'mists',
	forever: 'camelot',
};

// AllowLoadGameType values each client recognises. A client loads a file whose types it recognises
// none of, so the classic clients, which predate Forever, load the Forever files and rely on their
// IS_FOREVER guard.
const CLASSIC_GAME_TYPES = ['vanilla', 'tbc', 'wrath', 'cata', 'mists'];
const knownGameTypes = gameType => (gameType === 'camelot' ? [...CLASSIC_GAME_TYPES, 'camelot'] : CLASSIC_GAME_TYPES);

const tocFiles = gameType =>
	fs
		.readFileSync(path.join(ROOT, 'WowSimsExporter.toc'), 'utf8')
		.split(/\r?\n/)
		.map(line => line.trim())
		.filter(line => line && !line.startsWith('#') && !line.endsWith('.xml'))
		.filter(line => {
			const match = line.match(/\[AllowLoadGameType ([^\]]+)\]/);
			if (!match) return true;
			const types = match[1].split(',').map(type => type.trim());
			const known = knownGameTypes(gameType);
			return types.includes(gameType) || !types.some(type => known.includes(type));
		})
		.map(line => line.replace(/\s*\[.*$/, '').replace(/\\/g, '/'));

const check = status => {
	if (status !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
};

// The first TraitDefinition ID of each Forever talent tree, as a Lua table literal, read from the
// generated table so the fake Forever client always matches it.
const foreverFirstTalents = () => {
	const source = fs.readFileSync(path.join(ROOT, 'Flavors', 'Forever', 'Talents.lua'), 'utf8');
	const block = source.slice(source.indexOf('-- BEGIN GENERATED TALENTS'), source.indexOf('-- END GENERATED TALENTS'));
	const classes = [...block.matchAll(/^\s{4}([A-Z]+) = \{\r?\n((?:\s{8}\{[^\n]*\r?\n)+)/gm)].map(([, cls, trees]) => {
		const firstIds = [...trees.matchAll(/^\s{8}\{ (\d+)/gm)].map(match => match[1]);
		if (firstIds.length !== 3) throw new Error(`expected 3 Forever talent trees for ${cls}, found ${firstIds.length}`);
		return `${cls} = { ${firstIds.join(', ')} }`;
	});
	if (classes.length === 0) throw new Error('no Forever talent table found in Flavors/Forever/Talents.lua');
	return `FOREVER_FIRST_TALENTS = { ${classes.join(', ')} }`;
};

let L;
const runFlavor = (flavor, gameType) => {
	L = lauxlib.luaL_newstate();
	lualib.luaL_openlibs(L);
	lua.lua_pushstring(L, to_luastring(flavor));
	lua.lua_setglobal(L, to_luastring('FLAVOR'));
	check(lauxlib.luaL_dostring(L, to_luastring(foreverFirstTalents())));
	check(lauxlib.luaL_dofile(L, to_luastring(path.join(__dirname, 'wow_mock.lua'))));

	const runner = `
local root, files = ...
local list = {}
for file in files:gmatch("[^\\n]+") do list[#list + 1] = file end
return MOCK.RunScenario(root, list)
`;
	check(lauxlib.luaL_loadstring(L, to_luastring(runner)));
	lua.lua_pushstring(L, to_luastring(ROOT));
	lua.lua_pushstring(L, to_luastring(tocFiles(gameType).join('\n')));
	check(lua.lua_pcall(L, 2, 1, 0));
	// The export must be JSON; show it pretty-printed so a change is readable in the snapshot diff.
	return lua.lua_tojsstring(L, -1).replace(/<json>([^]*?)<\/json>/g, (_, json) => JSON.stringify(JSON.parse(json), null, 2));
};

const firstDifference = (expected, actual) => {
	const a = expected.split('\n');
	const b = actual.split('\n');
	for (let i = 0; i < Math.max(a.length, b.length); i++) {
		if (a[i] !== b[i]) return `line ${i + 1}:\n  expected: ${a[i]}\n  actual:   ${b[i]}`;
	}
	return '';
};

fs.mkdirSync(SNAPSHOT_DIR, { recursive: true });
let failed = 0;
for (const [flavor, gameType] of Object.entries(FLAVORS)) {
	const file = path.join(SNAPSHOT_DIR, `${flavor}.txt`);
	let actual;
	try {
		actual = runFlavor(flavor, gameType);
	} catch (error) {
		failed++;
		console.log(`FAIL ${flavor}: ${error.message}`);
		continue;
	}
	if (update) {
		fs.writeFileSync(file, actual);
		console.log(`wrote ${path.relative(ROOT, file)}`);
		continue;
	}
	const expected = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
	if (expected === actual) {
		console.log(`ok   ${flavor}`);
	} else {
		failed++;
		console.log(`FAIL ${flavor}: differs from ${path.relative(ROOT, file)} at ${firstDifference(expected, actual)}`);
	}
}
process.exit(failed === 0 ? 0 : 1);
