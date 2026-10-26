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
    if not s:find("%d") or not (s:find(" to ") or s:find("%% %*")) then return nil end
    return s
end
