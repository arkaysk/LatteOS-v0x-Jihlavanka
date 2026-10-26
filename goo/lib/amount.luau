-- An amount in units or money, written loosely and in Slovak too, put the way Qalculate reads it (qalc; lib/lens.luau
-- runs it): "100 eur na doláre" → "100 EUR to USD", "5 km v míľach" → "5 km to mi", "15 % z 80" → "15% * 80".
-- Returns nothing when the line asks for no conversion and no share of something: an app's name with a number in it
-- ("2048 game") is not to be worked out. Plain Lua as well as Luau, so that tests/test_bin.py can run it.
local CONNECT = { na = true, v = true, vo = true, ["do"] = true, ako = true, to = true, into = true }
-- the start of a word → what Qalculate calls it; the longer before the shorter that begins the same way
local WORDS = {
    { "eur", "EUR" }, { "dolár", "USD" }, { "dolar", "USD" }, { "korún", "CZK" }, { "korun", "CZK" }, { "kč", "CZK" },
    { "libier", "GBP" }, { "libra", "GBP" }, { "libry", "GBP" }, { "zlot", "PLN" }, { "forint", "HUF" }, { "frank", "CHF" },
    { "bitcoin", "BTC" },
    { "kilometr", "km" }, { "centimetr", "cm" }, { "milimetr", "mm" }, { "metr", "m" }, { "míľ", "mi" }, { "míl", "mi" },
    { "palc", "in" }, { "palec", "in" }, { "stôp", "ft" }, { "stopa", "ft" }, { "stopy", "ft" },
    { "kilogram", "kg" }, { "kil", "kg" }, { "kíl", "kg" }, { "gram", "g" }, { "litr", "L" },
    { "celzi", "°C" }, { "fahrenheit", "°F" }, { "stupň", "" }, { "stupn", "" },
    { "hodín", "h" }, { "hodin", "h" }, { "minút", "min" }, { "minut", "min" }, { "sekúnd", "s" }, { "sekund", "s" },
}
local CODES = { eur = 1, usd = 1, czk = 1, gbp = 1, pln = 1, huf = 1, chf = 1, jpy = 1, btc = 1, cad = 1, aud = 1, sek = 1,
                nok = 1, dkk = 1, cny = 1, uah = 1, rub = 1 }
local ASKING = { "koľko je", "kolko je", "koľko", "kolko", "prepočítaj", "prepocitaj", "preveď", "prevod" }

return function(line)
    local s = " " .. line:lower() .. " "
    for _, w in ipairs(ASKING) do s = s:gsub(" " .. w .. " ", " ", 1) end
    s = s:gsub("[%?=]+%s*$", " "):gsub("→", " to "):gsub("=>", " to ")
    -- a share: 15 % z 80, 15% of 80
    s = s:gsub("(%d)%s*%%%s*z%s+", "%1%% * "):gsub("(%d)%s*%%%s*of%s+", "%1%% * ")
    s = s:gsub("[%a\128-\255]+", function(w)
        if CONNECT[w] then return "to" end
        if CODES[w] then return w:upper() end
        for _, p in ipairs(WORDS) do
            if w:sub(1, #p[1]) == p[1] then return p[2] end
        end
        return w
    end)
    s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if not s:find("%d") or not (s:find(" to ") or s:find("%% %*")) then return nil end
    return s
end
