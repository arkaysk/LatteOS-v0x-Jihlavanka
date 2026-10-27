-- The apps whose name matches what was typed, best first: a match at the start of the name, then at the start
-- of a word, then anywhere, then in its id, then a word of the name with one letter wrong. Both names count, the
-- one in the user's language and the one the app has everywhere ("Files" finds Súbory). Accents and case do not matter.
local fold = require("lib/fold")

-- whether two words are at most one letter apart: one changed, left out or put in
local function one_off(a, b)
    if math.abs(#a - #b) > 1 then return false end
    local i = 1
    while i <= math.min(#a, #b) and a:sub(i, i) == b:sub(i, i) do i += 1 end
    if #a == #b then return a:sub(i + 1) == b:sub(i + 1) end
    if #a > #b then return a:sub(i + 1) == b:sub(i) end
    return a:sub(i) == b:sub(i + 1)
end
-- whether `word` begins with `want` but for one slip (only from four letters on: shorter, everything is near)
local function near(word, want)
    if #want < 4 then return false end
    for len = #want - 1, #want + 1 do
        if one_off(word:sub(1, len), want) then return true end
    end
    return false
end

local function score_of(name, want)
    local at = name:find(want, 1, true)
    if at == 1 then return 3 end
    if at then return name:sub(at - 1, at - 1):match("[%s%-_]") and 2 or 1 end
    for word in name:gmatch("[^%s%-_]+") do if near(word, want) then return 0.4 end end
    return 0
end

return function(apps, typed, most)
    local want, hits = fold(typed), {}
    for _, a in ipairs(apps) do
        local name = fold(a.local_name or a.name)
        local score = math.max(score_of(name, want), a.local_name and score_of(fold(a.name or ""), want) or 0,
                               fold(a.id):find(want, 1, true) and 0.5 or 0)
        if score > 0 then hits[#hits + 1] = { app = a, score = score, name = name } end
    end
    table.sort(hits, function(x, y) if x.score ~= y.score then return x.score > y.score end return x.name < y.name end)
    local found = {}
    for i = 1, math.min(#hits, most or 8) do found[i] = hits[i].app end
    return found
end
