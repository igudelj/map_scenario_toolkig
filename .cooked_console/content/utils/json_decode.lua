local function decodeJson(source)
    local index = 1
    local function skipWhitespace()
        while index <= #source and source:sub(index, index):match("%s") do index = index + 1 end
    end
    local function utf8(codepoint)
        if codepoint < 0x80 then return string.char(codepoint) end
        if codepoint < 0x800 then
            return string.char(0xC0 + math.floor(codepoint / 0x40), 0x80 + codepoint % 0x40)
        end
        if codepoint < 0x10000 then
            return string.char(0xE0 + math.floor(codepoint / 0x1000),
                0x80 + math.floor(codepoint / 0x40) % 0x40, 0x80 + codepoint % 0x40)
        end
        return string.char(0xF0 + math.floor(codepoint / 0x40000),
            0x80 + math.floor(codepoint / 0x1000) % 0x40,
            0x80 + math.floor(codepoint / 0x40) % 0x40, 0x80 + codepoint % 0x40)
    end
    local parseValue
    local function parseString()
        index = index + 1
        local parts = {}
        while index <= #source do
            local c = source:sub(index, index)
            index = index + 1
            if c == '"' then return table.concat(parts) end
            if c == '\\' then
                local escaped = source:sub(index, index)
                index = index + 1
                local simple = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f',
                    n = '\n', r = '\r', t = '\t' }
                if simple[escaped] then
                    parts[#parts + 1] = simple[escaped]
                elseif escaped == 'u' then
                    local hex = source:sub(index, index + 3)
                    if not hex:match('^%x%x%x%x$') then error('Invalid Unicode escape') end
                    index = index + 4
                    local codepoint = tonumber(hex, 16)
                    if codepoint >= 0xD800 and codepoint <= 0xDBFF then
                        if source:sub(index, index + 1) ~= '\\u' then error('Invalid Unicode surrogate pair') end
                        local lowHex = source:sub(index + 2, index + 5)
                        local low = tonumber(lowHex, 16)
                        if not low or low < 0xDC00 or low > 0xDFFF then error('Invalid Unicode surrogate pair') end
                        index = index + 6
                        codepoint = 0x10000 + (codepoint - 0xD800) * 0x400 + (low - 0xDC00)
                    elseif codepoint >= 0xDC00 and codepoint <= 0xDFFF then
                        error('Unexpected low Unicode surrogate')
                    end
                    parts[#parts + 1] = utf8(codepoint)
                else
                    error('Invalid JSON string escape')
                end
            else
                if string.byte(c) < 0x20 then error('Unescaped control character in string') end
                parts[#parts + 1] = c
            end
        end
        error('Unterminated JSON string')
    end
    local function parseArray()
        index = index + 1
        local result = {}
        skipWhitespace()
        if source:sub(index, index) == ']' then index = index + 1; return result end
        while true do
            result[#result + 1] = parseValue()
            skipWhitespace()
            local c = source:sub(index, index)
            if c == ']' then index = index + 1; return result end
            if c ~= ',' then error('Expected comma or closing bracket') end
            index = index + 1
        end
    end
    local function parseObject()
        index = index + 1
        local result = {}
        skipWhitespace()
        if source:sub(index, index) == '}' then index = index + 1; return result end
        while true do
            skipWhitespace()
            if source:sub(index, index) ~= '"' then error('Expected quoted object key') end
            local key = parseString()
            skipWhitespace()
            if source:sub(index, index) ~= ':' then error('Expected colon after object key') end
            index = index + 1
            result[key] = parseValue()
            skipWhitespace()
            local c = source:sub(index, index)
            if c == '}' then index = index + 1; return result end
            if c ~= ',' then error('Expected comma or closing brace') end
            index = index + 1
        end
    end
    parseValue = function()
        skipWhitespace()
        local c = source:sub(index, index)
        if c == '"' then return parseString() end
        if c == '{' then return parseObject() end
        if c == '[' then return parseArray() end
        if source:sub(index, index + 3) == 'true' then index = index + 4; return true end
        if source:sub(index, index + 4) == 'false' then index = index + 5; return false end
        if source:sub(index, index + 3) == 'null' then index = index + 4; return nil end
        local token = source:sub(index):match('^-?%d+%.?%d*[eE]?[+-]?%d*')
        if token and token ~= '' then
            local number = tonumber(token)
            if number then index = index + #token; return number end
        end
        error('Unexpected JSON value at character ' .. index)
    end
    local result = parseValue()
    skipWhitespace()
    if index <= #source then error('Unexpected trailing JSON content') end
    return result
end

return decodeJson
