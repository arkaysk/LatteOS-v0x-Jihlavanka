-- An amount in units or money, written loosely, put the way Qalculate reads it (qalc; lib/lens.luau runs it):
-- "100 eur to dollars" → "100 EUR to USD", "15 % of 80" → "15% * 80". The words of the user's language come from
-- goo/lang/<code>-amount.json (`words`): what joins the two sides ("connect"), what a share is of ("of"), the starts of
-- words for units and money ("names", the longer before the shorter that begins the same way) and the questions put
-- before it ("asking"). Returns nothing when the line asks for no conversion and no share: an app's name with a number
-- in it ("2048 game") is not to be worked out. Plain Lua as well as Luau, so that tests/test_bin.py can run it.
local CODES = { eur = 1, usd = 1, czk = 1, gbp = 1, pln = 1, huf = 1, chf = 1, jpy = 1, btc = 1, cad = 1, aud = 1, sek = 1,
                nok = 1, dkk = 1, cny = 1, uah = 1, rub = 1 }

return function(line, words)
    words = type(words) == "table" and words or {}
    local connect = { to = true, into = true }
    for _, w in ipairs(words.connect or {}) do connect[w] = true end
    local s = " " .. line:lower() .. " "
    for _, w in ipairs(words.asking or {}) do s = s:gsub(" " .. w .. " ", " ", 1) end
    s = s:gsub("[%?=]+%s*$", " "):gsub("→", " to "):gsub("=>", " to ")
    -- Raycast 2.12's phrasings, put as Qalculate reads them (each sets `said`: such a line is worked out even with no conversion in it)
    s = (s:gsub("^%s+", ""):gsub("%s+$", ""))
    s = s:gsub("(%d) €", "%1€"):gsub("(%d) £", "%1£")       -- 500 € is one thing for the forms below
    local said = false
    -- the phrases of the user's language for the forms below ("discount", "tip", "root"…: goo/lang/<code>-amount.json), the English ones always
    local function phrases(key, english)
        local list = { english }                                             -- the English one is already a pattern
        for _, w in ipairs(type(words[key]) == "table" and words[key] or {}) do
            list[#list + 1] = (w:gsub("[%%%.%-%+%*%?%[%]%(%)%^%$]", "%%%0"):gsub("%s+", "%%s+"))   -- the user's: letters, with any gap between words
        end
        return list
    end
    local function rule(pattern, with)
        local out, n = s:gsub(pattern, with)
        if n > 0 then s, said = out, true end
    end
    for _, w in ipairs(phrases("iswhat", "is%s+what%s*%%")) do rule("^(.-)%s+" .. w .. "$", "(%1) to %%") end                  -- 1/8 is what %
    for _, w in ipairs(phrases("asof", "as%s*%%%s+of")) do rule("^(.-)%s+" .. w .. "%s+(.+)$", "((%1) / (%2)) to %%") end     -- 750 m as % of 3 km
    for _, w in ipairs(phrases("cuberoot", "cube%s+root%s+of")) do rule("%f[%a]" .. w .. "%s+([%d%.,]+)", "cbrt(%1)") end
    for _, w in ipairs(phrases("root", "square%s+root%s+of")) do rule("%f[%a]" .. w .. "%s+([%d%.,]+)", "sqrt(%1)") end
    rule("([%d%.,]+)%s+power%s+([%d%.,]+)", "%1^%2")                                -- 2 power 10
    rule("(.-)%s+to%s+nearest%s+(%a+)$", function(x, w)                              -- 3.14159 to nearest hundredth
        local n = ({ whole = 0, integer = 0, tenth = 1, hundredth = 2, thousandth = 3 })[w]
        if n then return "(round((" .. x .. ") * 10^" .. n .. ") / 10^" .. n .. ")" end
    end)
    for _, w in ipairs(phrases("fraction", "as%s+fraction")) do rule("%f[%a]" .. w .. "%f[%A]", "to fraction") end   -- 1.75 as fraction
    rule("%f[%a]as%s+mixed%f[%A]", "to fraction")
    rule("(%S+)%s+at%s+(%d[%d%.]*)%s*%%%s+for%s+(%d+)%s+years?%s*(%a*)%s*(%a*)", function(sum, rate, years, _, how)   -- $1000 at 5% for 10 years compounded annually
        local f = ({ annually = 1, yearly = 1, semiannually = 2, quarterly = 4, monthly = 12, daily = 365 })[how] or 1
        return sum .. " * (1 + " .. tonumber(rate) / 100 / f .. ")^(" .. years .. " * " .. f .. ")"
    end)
    -- in function arguments a comma separates (min(3, 5)): Qalculate, in a language with a decimal comma, wants a semicolon there
    s = s:gsub("(%a+)%(([^%(%)]-)%)", function(fn, args)
        if ({ min = 1, max = 1, gcd = 1, lcm = 1, round = 1, sum = 1, mod = 1, pow = 1, rem = 1 })[fn] and args:find(",") then said = true return fn .. "(" .. args:gsub("%s*,%s*", "; ") .. ")" end
    end)
    for _, w in ipairs(phrases("discount", "discount%s+off")) do rule("(%d[%d%.]*)%s*%%%s*" .. w .. "%s+(%S+)", "%2 - %1%%") end   -- 20% discount off $500
    rule("(%d[%d%.]*)%s*%%%s*off%s+(%S+)", "%2 - %1%%")                            -- 20% off 80
    for _, w in ipairs(phrases("tip", "gratuity%s+on")) do rule("(%d[%d%.]*)%s*%%%s*" .. w .. "%s+(%S+)", "%2 + %1%%") end   -- 5% gratuity on $95
    rule("(%d[%d%.]*)%s*%%%s*tip%s+on%s+(%S+)", "%2 + %1%%")
    for _, w in ipairs(phrases("split", "split")) do rule("^(.-)%s+" .. w .. "%s+(%d+)$", "(%1) / %2") end                                    -- 25% off $60 split 3
    rule("(%d[%d%.]*)%s*(f[eo]+t)%s+(%d[%d%.]*)%s*(inch[es]*)", "%1 ft + %3 inch")      -- 5 feet 3 inches in cm
    rule("(%d[%d%.]*)%s*ft%s+(%d[%d%.]*)%s*in%f[%A]", "%1 ft + %2 inch")
    rule("%f[%a]kilos?%f[%A]", "kg")                                               -- kilo is kg
    rule("%f[%a]yr%f[%A]", "year")                                                 -- unit shorthands
    rule("%f[%a]mo%f[%A]", "month")
    for _, f in ipairs({ "sin", "cos", "tan", "cot", "sec", "csc" }) do            -- the degree variants: cotd(45), acotd(1)
        rule("%f[%a]" .. f .. "d%(([^%)]*)%)", f .. "(%1 deg)")
        rule("%f[%a]a" .. f .. "d%(([^%)]*)%)", "(a" .. f .. "(%1) * 180 / pi)")
    end
    s = s:gsub("%f[%a](%a%a%a)(%d[%d%.]*k?)%f[%A]", function(code, n) if CODES[code] then said = true return n .. " " .. code end end)   -- USD1K → 1K USD
    rule("(%d[%d%.]*)k%f[%A]", "(%1 * 1000)")                                      -- 10k = 10,000 (10 K = kelvin)
    -- "12% of $321 in jpy": `in` joins the two sides unless a number stands before it (5 in to cm: inches)
    s = s:gsub("(%S+) in ", function(prev) if not prev:match("^[%d%.,]+$") then return prev .. " to " end end)
    -- a share: 15 % of 80
    for _, w in ipairs({ "of", table.unpack(words.of or {}) }) do s = s:gsub("(%d)%s*%%%s*" .. w .. "%s+", "%1%% * ") end
    s = s:gsub("[%a\128-\255]+", function(w)
        if connect[w] then return "to" end
        if CODES[w] then return w:upper() end
        for _, p in ipairs(words.names or {}) do
            if w:sub(1, #p[1]) == p[1] then return p[2] end
        end
        return w
    end)
    s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    s = s:gsub("(%d)€", "%1 €"):gsub("(%d)£", "%1 £")         -- unglued again
    if not s:find("%d") then return nil end
    if said or s:find(" to ") or s:find("%% %*") then return s end
    -- what Qalculate works out without a conversion: a percentage (150 + 20%), a date (tomorrow + 3 days), units added (2 h + 30 min)
    if s:find("%d%s*%%") or s:find("%f[%a]today%f[%A]") or s:find("%f[%a]tomorrow%f[%A]") or s:find("%f[%a]yesterday%f[%A]") or s:find("%f[%a]now%f[%A]")
       or s:find("%d%s*%a+%s*[%+%-]%s*%d") then return s end
    return nil
end
