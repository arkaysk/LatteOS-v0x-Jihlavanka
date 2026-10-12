-- The apps whose name matches what was typed, best first: a match at the start of the name, then at the start
-- of a word, then anywhere, then in its id. Accents and case do not matter.
local fold = require("lib/fold")

return function(apps, typed, most)
    local want, hits = fold(typed), {}
    for _, a in ipairs(apps) do
        local name = fold(a.local_name or a.name)
        local at = name:find(want, 1, true)
        local score = at == 1 and 3 or (at and name:sub(at - 1, at - 1):match("[%s%-_]") and 2) or (at and 1)
            or (fold(a.id):find(want, 1, true) and 0.5) or 0
        if score > 0 then hits[#hits + 1] = { app = a, score = score, name = name } end
    end
    table.sort(hits, function(x, y) if x.score ~= y.score then return x.score > y.score end return x.name < y.name end)
    local found = {}
    for i = 1, math.min(#hits, most or 8) do found[i] = hits[i].app end
    return found
end
