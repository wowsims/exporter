#!/usr/bin/env node
// Checks Core/Json.lua against the output LibParse gave for the same values, which is what the sim's
// importer reads. The snapshot test covers the full exports; this covers the edge cases.
//
// Usage: node tools/test/json.js

const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..', '..');

// Lua expression -> expected JSON.
const CASES = [
	['{}', '[]'],
	['{ 1, 2, 3 }', '[1,2,3]'],
	['{ [1] = 1, [3] = 3 }', '[1,null,3]'],
	['{ b = 1, a = { } }', '{"a":[],"b":1}'],
	['{ 1, x = 2 }', '{"1":1,"x":2}'],
	['{ [0] = "zero" }', '{"0":"zero"}'],
	['{ [1.5] = true }', '{"1.5":true}'],
	['{ n = 3.0, f = 0.25, neg = -15, big = 123456789012 }', '{"big":123456789012,"f":0.25,"n":3,"neg":-15}'],
	['{ s = "a\\"b\\\\c/d\\n\\t\\1" }', '{"s":"a\\"b\\\\c\\/d\\n\\t\\u0001"}'],
	['{ t = true, f = false }', '{"f":false,"t":true}'],
	['setmetatable({ own = 1 }, { __index = { inherited = 2 } })', '{"own":1}'],
];

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const check = status => {
	if (status !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
};
check(lauxlib.luaL_dostring(L, to_luastring('Env = {}')));
check(lauxlib.luaL_loadfile(L, to_luastring(path.join(ROOT, 'Core', 'Json.lua'))));
lua.lua_pushstring(L, to_luastring('WowSimsExporter'));
lua.lua_getglobal(L, to_luastring('Env'));
check(lua.lua_pcall(L, 2, 0, 0));

let failed = 0;
for (const [value, expected] of CASES) {
	check(lauxlib.luaL_dostring(L, to_luastring(`return Env.JSONEncode(${value})`)));
	const actual = lua.lua_tojsstring(L, -1);
	lua.lua_pop(L, 1);
	if (actual === expected) {
		console.log(`ok   ${value}`);
	} else {
		failed++;
		console.log(`FAIL ${value}\n  expected: ${expected}\n  actual:   ${actual}`);
	}
}

const unsupported = lauxlib.luaL_dostring(L, to_luastring('return Env.JSONEncode({ f = print })'));
if (unsupported === lua.LUA_OK) {
	failed++;
	console.log('FAIL a function value should be an error');
} else {
	console.log('ok   a function value is an error');
}

process.exit(failed === 0 ? 0 : 1);
