-- What matches what was typed, best first, as Tinycast's launcher ranks (6B.32). Accents and case do not matter.
--   find(items, typed, most, opts)  items: apps ({ name, local_name, id, keywords }) or anything with `name`;
--   opts: { visits = { [key] = { anchor, terms } }, aliases = { [key] = text }, key = function(item) }
-- Each name is aligned with what is typed letter by letter: the first letter on the first counts 4, a letter at the start
-- of a word 3 (after a space, a hyphen, a dot, a slash…, at a capital after a small letter — OrbStack —, at a letter
-- after a digit — 1Password), any other 2, one letter not next to the one before loses 1. The order: the user's alias
-- exactly, a name exactly, then what was opened lately for something like this (learned: each opening counts more the
-- newer it is, halving every 10 days, and the last three things typed for it lead for 17 days), then the alignment,
-- then how often and lately it was opened. A word of the name with one letter wrong is found too, last.
local fold = require("lib/fold")

local DAY = 86400
local LAMBDA = math.log(2) / (10 * DAY)

-- a name as letters with where its words start: the original for capitals and digits, folded for comparing
local SEPARATORS = { [" "] = true, ["\t"] = true, ["-"] = true, ["."] = true, ["/"] = true, ["("] = true, [")"] = true,
                     ["["] = true, ["]"] = true, ["_"] = true }
local function letters(name)
    local out, starts, prev = {}, {}, nil
    for _, code in utf8.codes(name) do
        local ch = utf8.char(code)
        local f = fold(ch)
        local upper = ch:match("^%u$") ~= nil
        local start = prev == nil or SEPARATORS[prev] or (upper and prev:match("^%l$") ~= nil)
                      or (ch:match("^%a$") ~= nil and prev:match("^%d$") ~= nil)
        out[#out + 1], starts[#starts + 1] = f, start
        prev = ch
    end
    return out, starts
end

-- the best alignment of `want` (folded) over a name: its points, or nil where not every letter is found in order
local function align(name, want)
    local text, starts = letters(name)
    local q = {}
    for _, code in utf8.codes(want) do local c = utf8.char(code) if not SEPARATORS[c] then q[#q + 1] = c end end
    if #q == 0 then return nil end
    -- best[j]: the best score with the last letter matched at j; a running maximum keeps it O(name)
    local prev = {}
    for i = 1, #q do
        local cur, run = {}, nil
        for j = 1, #text do
            if i > 1 and j >= 2 and prev[j - 2] ~= nil then run = math.max(run or -math.huge, prev[j - 2]) end
            if text[j] == q[i] then
                local pts = (i == 1 and j == 1) and 4 or (starts[j] and 3 or 2)
                if i == 1 then cur[j] = pts
                else
                    local adjacent = prev[j - 1]
                    local apart = run and (run - 1) or nil
                    local best = adjacent and apart and math.max(adjacent, apart) or adjacent or apart
                    if best then cur[j] = best + pts end
                end
            end
        end
        prev = cur
    end
    local best
    for _, v in pairs(prev) do best = math.max(best or -math.huge, v) end
    return best
end

-- whether two words are at most one letter apart: one changed, left out or put in
local function one_off(a, b)
    if math.abs(#a - #b) > 1 then return false end
    local i = 1
    while i <= math.min(#a, #b) and a:sub(i, i) == b:sub(i, i) do i += 1 end
    if #a == #b then return a:sub(i + 1) == b:sub(i + 1) end
    if #a > #b then return a:sub(i + 1) == b:sub(i) end
    return a:sub(i) == b:sub(i + 1)
end
local function near(name, want)
    if #want < 4 then return false end
    for word in fold(name):gmatch("[^%s%-_]+") do
        for len = #want - 1, #want + 1 do if one_off(word:sub(1, len), want) then return true end end
    end
    return false
end

-- how much it was opened, now: e^(λ(anchor − t)), never below 1
local function frecency(v, now) return v and math.max(1, math.exp(LAMBDA * ((v.anchor or 0) - now))) or 1 end

local M = {}
-- an opening of `key`, with what was typed for it (LensShore's launches)
function M.visit(visits, key, typed, now)
    now = now or os.time()
    local v = visits[key] or { anchor = 0, terms = {} }
    v.anchor = now + math.log(frecency(v, now) + 100) / LAMBDA
    v.last = now
    local t = fold(typed or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t ~= "" then
        for i = #v.terms, 1, -1 do if v.terms[i] == t then table.remove(v.terms, i) end end
        table.insert(v.terms, 1, t)
        while #v.terms > 3 do table.remove(v.terms) end
    end
    visits[key] = v
end
-- what was opened, how much it counts now (the empty field's suggestions, most launched)
M.frecency = frecency

local function rank(items, typed, most, opts)
    opts = opts or {}
    local want = fold(typed):gsub("^%s+", ""):gsub("%s+$", "")
    local now, visits, aliases = os.time(), opts.visits or {}, opts.aliases or {}
    local key = opts.key or function(a) return a.id or a.name end
    local hits = {}
    for _, a in ipairs(items) do
        local k = key(a)
        local alias = aliases[k] and fold(aliases[k]) or nil
        local tier, score = 9, nil
        for _, n in ipairs({ a.local_name or false, a.name or false }) do
            if n then
                local s = align(n, want)
                if s and (not score or s > score) then score = s end
                if fold(n) == want then tier = math.min(tier, 2) end
            end
        end
        if alias then
            if alias == want then tier = 1
            elseif alias:sub(1, #want) == want then tier = math.min(tier, 3) score = math.max(score or 0, 100) end
        end
        -- the words an app's launcher gives (Keywords=, "browser;web;"), or a list
        local kw = a.keywords
        if type(kw) == "string" then local l = {} for w in kw:gmatch("[^;,]+") do l[#l + 1] = w end kw = l end
        for _, w in ipairs(type(kw) == "table" and kw or {}) do
            local s = align(w, want)
            if s then score = math.max(score or 0, s - 1) end
        end
        if not score and a.id and fold(a.id):find(want, 1, true) then score = 0.5 end
        if not score and near(a.local_name or a.name or "", want) then score = 0.2 end
        if score or tier < 9 then
            local v = visits[k]
            local f = frecency(v, now)
            if tier == 9 and v and f > 1 and v.last and now - v.last < 17 * DAY then
                for _, t in ipairs(v.terms or {}) do
                    if t:sub(1, #want) == want or want:sub(1, #t) == t then tier = 4 break end
                end
            end
            hits[#hits + 1] = { item = a, tier = tier, score = score or 0, f = f, name = fold(a.local_name or a.name or "") }
        end
    end
    table.sort(hits, function(x, y)
        if x.tier ~= y.tier then return x.tier < y.tier end
        if x.tier == 4 and x.f ~= y.f then return x.f > y.f end
        if x.score ~= y.score then return x.score > y.score end
        if x.f ~= y.f then return x.f > y.f end
        return x.name < y.name
    end)
    local found = {}
    for i = 1, math.min(#hits, most or 8) do found[i] = hits[i].item end
    return found
end

return setmetatable(M, { __call = function(_, ...) return rank(...) end })
