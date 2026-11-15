-- JSON encoding for the export, in place of LibParse.
--
-- Matches what LibParse wrote, which is what the sim's importer has always read: a table whose keys
-- are all positive integers is an array up to its highest index (gaps are null, and an empty table
-- is []), any other table is an object. Object keys are sorted so the output is deterministic.

local Env = select(2, ...)

local escapes = {
    ["\b"] = "\\b",
    ["\t"] = "\\t",
    ["\n"] = "\\n",
    ["\f"] = "\\f",
    ["\r"] = "\\r",
    ['"'] = '\\"',
    ["\\"] = "\\\\",
    ["/"] = "\\/",
}

local function EncodeString(s)
    local escaped = s:gsub('[%c\\"/]', function(c)
        return escapes[c] or ("\\u%04X"):format(c:byte())
    end)
    return '"' .. escaped .. '"'
end

local Encode

local function EncodeTable(t, out)
    local keys, isArray, count = {}, true, 0
    for key in pairs(t) do
        if type(key) == "number" and key > 0 and key % 1 == 0 then
            count = math.max(count, key)
        else
            isArray = false
        end
        table.insert(keys, key)
    end

    if isArray then
        table.insert(out, "[")
        for i = 1, count do
            if i > 1 then table.insert(out, ",") end
            Encode(t[i], out)
        end
        table.insert(out, "]")
        return
    end

    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    table.insert(out, "{")
    for i, key in ipairs(keys) do
        if i > 1 then table.insert(out, ",") end
        table.insert(out, EncodeString(tostring(key)))
        table.insert(out, ":")
        Encode(t[key], out)
    end
    table.insert(out, "}")
end

function Encode(value, out)
    local valueType = type(value)
    if valueType == "nil" then
        table.insert(out, "null")
    elseif valueType == "boolean" then
        table.insert(out, tostring(value))
    elseif valueType == "number" then
        -- WoW's tostring format, written out so integers never come out as "1.0".
        table.insert(out, ("%.14g"):format(value))
    elseif valueType == "string" then
        table.insert(out, EncodeString(value))
    elseif valueType == "table" then
        EncodeTable(value, out)
    else
        error(("Encoding of %s unsupported"):format(tostring(value)))
    end
end

---Encode a value as JSON.
---@param value any
---@return string
function Env.JSONEncode(value)
    local out = {}
    Encode(value, out)
    return table.concat(out)
end
