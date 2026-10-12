-- A line of arithmetic worked out: 2,5 * (3 + 4), 2^10, sqrt(2), 15 % of nothing more than that.
-- Returns the number, or nothing when the line is not a calculation: a word, a lone number, a mistake.
local FUNCTIONS = { sqrt = math.sqrt, abs = math.abs, sin = math.sin, cos = math.cos, tan = math.tan, ln = math.log, log = math.log10,
                    round = math.round, floor = math.floor, ceil = math.ceil }
local CONSTANTS = { pi = math.pi, e = math.exp(1) }

return function(line)
    local s = line:gsub("%s+", ""):gsub(",", "."):gsub("×", "*"):gsub("÷", "/"):lower()
    -- something has to be worked out: an operator between two things, or a function
    if not (s:find("[%d%)][%+%-%*/%^%%][%d%(%a%-]") or s:find("%a+%(")) then return nil end
    local at = 1
    local expr

    local function atom()
        local c = s:sub(at, at)
        if c == "(" then
            at += 1
            local v = expr()
            if s:sub(at, at) ~= ")" then error("unclosed") end
            at += 1
            return v
        elseif c == "-" then
            at += 1
            return -atom()
        end
        local number = s:match("^%d+%.?%d*", at) or s:match("^%.%d+", at)
        if number then
            at += #number
            return tonumber(number)
        end
        local name = s:match("^%a+", at)
        if not name then error("unexpected") end
        at += #name
        if s:sub(at, at) == "(" then
            local f = FUNCTIONS[name] or error("unknown")
            at += 1
            local v = expr()
            if s:sub(at, at) ~= ")" then error("unclosed") end
            at += 1
            return f(v)
        end
        return CONSTANTS[name] or error("unknown")
    end
    local function power()
        local v = atom()
        if s:sub(at, at) == "^" then at += 1 return v ^ power() end
        return v
    end
    local function product()
        local v = power()
        while true do
            local c = s:sub(at, at)
            if c == "*" then at += 1 v *= power()
            elseif c == "/" then at += 1 v /= power()
            elseif c == "%" then at += 1 v %= power()
            else return v end
        end
    end
    expr = function()
        local v = product()
        while true do
            local c = s:sub(at, at)
            if c == "+" then at += 1 v += product()
            elseif c == "-" then at += 1 v -= product()
            else return v end
        end
    end

    local ok, v = pcall(expr)
    if not ok or at <= #s or type(v) ~= "number" or v ~= v or math.abs(v) == math.huge then return nil end
    return v
end
