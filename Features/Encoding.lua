-- Encoding helpers for reading the sim's exports and writing its saved-data text:
-- a small JSON reader, and "wowsims-saved:v1:" text (zlib-compressed JSON in base64).
-- Compression uses the client's C_EncodingUtil, so saved-data text only works where the client has it.

local _, Env = ...
-- WowSims features are Forever-only; other game versions keep the original exporter.
if not Env.IS_FOREVER then return end

local Encoding = {}
Env.Encoding = Encoding

--------------------------------------------------------------------------------
-- JSON reader
--------------------------------------------------------------------------------

local escapes = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

---Encode a code point as UTF-8.
local function Utf8(codePoint)
    if codePoint < 0x80 then
        return string.char(codePoint)
    elseif codePoint < 0x800 then
        return string.char(0xC0 + math.floor(codePoint / 0x40), 0x80 + codePoint % 0x40)
    elseif codePoint < 0x10000 then
        return string.char(0xE0 + math.floor(codePoint / 0x1000), 0x80 + math.floor(codePoint / 0x40) % 0x40,
            0x80 + codePoint % 0x40)
    end
    return string.char(0xF0 + math.floor(codePoint / 0x40000), 0x80 + math.floor(codePoint / 0x1000) % 0x40,
        0x80 + math.floor(codePoint / 0x40) % 0x40, 0x80 + codePoint % 0x40)
end

---Decode JSON text. null becomes nil; arrays keep their positions (a null leaves a gap).
---@param text string
---@return any value
---@return string|nil error
function Encoding.DecodeJSON(text)
    local pos = 1
    local ParseValue

    local function Fail(message)
        error({ jsonError = ("%s at character %d"):format(message, pos) })
    end

    local function SkipSpace()
        pos = text:find("[^ \t\r\n]", pos) or (#text + 1)
    end

    local function ParseString()
        pos = pos + 1 -- opening quote
        local parts = {}
        while true do
            local stop = text:find('["\\]', pos)
            if not stop then Fail("unterminated string") end
            table.insert(parts, text:sub(pos, stop - 1))
            if text:sub(stop, stop) == '"' then
                pos = stop + 1
                return table.concat(parts)
            end
            local escape = text:sub(stop + 1, stop + 1)
            if escape == "u" then
                local hex = text:sub(stop + 2, stop + 5)
                local codePoint = tonumber(hex, 16)
                if not codePoint then Fail("bad unicode escape") end
                table.insert(parts, Utf8(codePoint))
                pos = stop + 6
            elseif escapes[escape] then
                table.insert(parts, escapes[escape])
                pos = stop + 2
            else
                Fail("bad escape")
            end
        end
    end

    local function ParseNumber()
        local number = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
        if not number or number == "" then Fail("bad number") end
        pos = pos + #number
        return tonumber(number)
    end

    local function ParseArray()
        pos = pos + 1
        local array, index = {}, 0
        SkipSpace()
        if text:sub(pos, pos) == "]" then
            pos = pos + 1
            return array
        end
        while true do
            index = index + 1
            array[index] = ParseValue()
            SkipSpace()
            local char = text:sub(pos, pos)
            pos = pos + 1
            if char == "]" then return array end
            if char ~= "," then Fail("expected , or ]") end
        end
    end

    local function ParseObject()
        pos = pos + 1
        local object = {}
        SkipSpace()
        if text:sub(pos, pos) == "}" then
            pos = pos + 1
            return object
        end
        while true do
            SkipSpace()
            if text:sub(pos, pos) ~= '"' then Fail("expected a key") end
            local key = ParseString()
            SkipSpace()
            if text:sub(pos, pos) ~= ":" then Fail("expected :") end
            pos = pos + 1
            object[key] = ParseValue()
            SkipSpace()
            local char = text:sub(pos, pos)
            pos = pos + 1
            if char == "}" then return object end
            if char ~= "," then Fail("expected , or }") end
        end
    end

    function ParseValue()
        SkipSpace()
        local char = text:sub(pos, pos)
        if char == "{" then return ParseObject() end
        if char == "[" then return ParseArray() end
        if char == '"' then return ParseString() end
        if char == "-" or char:match("%d") then return ParseNumber() end
        if text:sub(pos, pos + 3) == "true" then pos = pos + 4 return true end
        if text:sub(pos, pos + 4) == "false" then pos = pos + 5 return false end
        if text:sub(pos, pos + 3) == "null" then pos = pos + 4 return nil end
        Fail("unexpected character")
    end

    local ok, result = pcall(function()
        local value = ParseValue()
        SkipSpace()
        if pos <= #text then Fail("extra text after the value") end
        return value
    end)
    if ok then return result, nil end
    if type(result) == "table" and result.jsonError then return nil, result.jsonError end
    return nil, tostring(result)
end

---Quote a string for JSON.
---@param value string
---@return string
function Encoding.QuoteJSON(value)
    return '"' .. value:gsub('[%c"\\]', function(char)
        if char == '"' then return '\\"' end
        if char == "\\" then return "\\\\" end
        if char == "\n" then return "\\n" end
        return ("\\u%04x"):format(char:byte())
    end) .. '"'
end

--------------------------------------------------------------------------------
-- zlib + base64 through C_EncodingUtil
--------------------------------------------------------------------------------

local SAVED_PREFIX = "wowsims-saved:v1:"

---Adler-32 checksum, the zlib trailer.
local function Adler32(data)
    local a, b = 1, 0
    for i = 1, #data do
        a = (a + data:byte(i)) % 65521
        b = (b + a) % 65521
    end
    return b * 65536 + a
end

local function Uint32BigEndian(value)
    return string.char(math.floor(value / 0x1000000) % 0x100, math.floor(value / 0x10000) % 0x100,
        math.floor(value / 0x100) % 0x100, value % 0x100)
end

-- How the client's compression maps to zlib, worked out once: "zlib" (a method that writes zlib),
-- "raw" (only raw deflate, wrapped by hand), or false (no compression available).
local compressionMode

local function GetCompressionMode()
    if compressionMode ~= nil then return compressionMode end
    compressionMode = false
    local util = C_EncodingUtil
    local methods = Enum and Enum.CompressionMethod
    if not (util and util.CompressString and util.EncodeBase64 and methods) then return compressionMode end

    if methods.Zlib then
        compressionMode = "zlib"
    elseif methods.Deflate then
        -- Some clients' Deflate already writes a zlib header (0x78); otherwise it's raw deflate.
        local ok, sample = pcall(util.CompressString, "wowsims", methods.Deflate)
        if ok and sample then
            compressionMode = (sample:byte(1) == 0x78) and "zlib-deflate" or "raw"
        end
    end
    return compressionMode
end

---Whether this client can write and read the sim's saved-data text.
---@return boolean
function Encoding.CanUseSavedDataText()
    return GetCompressionMode() ~= false
end

local function Compress(data)
    local mode = GetCompressionMode()
    local methods = Enum.CompressionMethod
    if mode == "zlib" then
        return C_EncodingUtil.CompressString(data, methods.Zlib)
    elseif mode == "zlib-deflate" then
        return C_EncodingUtil.CompressString(data, methods.Deflate)
    elseif mode == "raw" then
        return "\120\156" .. C_EncodingUtil.CompressString(data, methods.Deflate) .. Uint32BigEndian(Adler32(data))
    end
    return nil
end

local function Decompress(data)
    local mode = GetCompressionMode()
    local methods = Enum.CompressionMethod
    if mode == "zlib" then
        return C_EncodingUtil.DecompressString(data, methods.Zlib)
    elseif mode == "zlib-deflate" then
        return C_EncodingUtil.DecompressString(data, methods.Deflate)
    elseif mode == "raw" then
        return C_EncodingUtil.DecompressString(data:sub(3, -5), methods.Deflate)
    end
    return nil
end

---Write JSON as the sim's saved-data text.
---@param json string
---@return string|nil text
---@return string|nil error
function Encoding.EncodeSavedData(json)
    if not Encoding.CanUseSavedDataText() then
        return nil, "This game client can't compress data, which saved-data text needs."
    end
    local ok, compressed = pcall(Compress, json)
    if not ok or not compressed then return nil, "Compressing failed: " .. tostring(compressed) end
    return SAVED_PREFIX .. C_EncodingUtil.EncodeBase64(compressed)
end

---Whether text is the sim's saved-data text.
---@param text string
---@return boolean
function Encoding.IsSavedDataText(text)
    return text:match("^%s*wowsims%-saved:v%d+:") ~= nil
end

---Read the sim's saved-data text back into JSON.
---@param text string
---@return string|nil json
---@return string|nil error
function Encoding.DecodeSavedData(text)
    local version, body = strtrim(text):match("^wowsims%-saved:v(%d+):(.+)$")
    if not version then return nil, "Not saved-data text." end
    if version ~= "1" then return nil, "Saved-data version " .. version .. " is newer than this addon." end
    if not Encoding.CanUseSavedDataText() then
        return nil, "This game client can't decompress data, which saved-data text needs."
    end
    local ok, json = pcall(function()
        return Decompress(C_EncodingUtil.DecodeBase64(body))
    end)
    if not ok or not json then return nil, "The text is damaged or incomplete: " .. tostring(json) end
    return json
end
