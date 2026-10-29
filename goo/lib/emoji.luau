-- LensShore's Emoji (6B.28), as Raycast's Emoji & Symbols and Tinycast's emoji picker do it: every emoji and Unicode
-- symbol (bin/latte-emoji: Unicode's list, CLDR's names in the user's language and English, pictures drawn from the
-- colour emoji font), in a grid of pages turned to the side (the user, 29. 10.: the wheel stays the tape's). A category
-- filter; Pinned and Frequently used first in the overview; search over names and words, every word starting a word,
-- the full name first; a default skin tone and the tones on each; the user's own keywords; 6 to 10 columns. Beside
-- it kaomoji, and GIFs (lib/gif.luau). What a row does is given by LensShore (`env`): paste, copy, render, save.
local fold = require("lib/fold")
local ctx = require("lib/ctx")
local M = {}
local function N(s) return s end
-- capitals for a heading, the Slovak and Czech letters with accents too (string.upper knows only a–z)
local UPPER = { ["\u{E1}"] = "\u{C1}", ["\u{E4}"] = "\u{C4}", ["\u{10D}"] = "\u{10C}", ["\u{10F}"] = "\u{10E}",
                ["\u{E9}"] = "\u{C9}", ["\u{11B}"] = "\u{11A}", ["\u{ED}"] = "\u{CD}", ["\u{13A}"] = "\u{139}",
                ["\u{13E}"] = "\u{13D}", ["\u{148}"] = "\u{147}", ["\u{F3}"] = "\u{D3}", ["\u{F4}"] = "\u{D4}",
                ["\u{F6}"] = "\u{D6}", ["\u{155}"] = "\u{154}", ["\u{159}"] = "\u{158}", ["\u{161}"] = "\u{160}",
                ["\u{165}"] = "\u{164}", ["\u{FA}"] = "\u{DA}", ["\u{16F}"] = "\u{16E}", ["\u{FC}"] = "\u{DC}",
                ["\u{FD}"] = "\u{DD}", ["\u{17E}"] = "\u{17D}" }
local function upper(s) return (s:gsub("[\xC3-\xC5][\x80-\xBF]", UPPER):upper()) end

-- the categories, in Unicode's order; the symbols' kinds are latte-emoji's
local GROUPS = {
    { "Smileys & Emotion", N("Smileys and emotion") }, { "People & Body", N("People and body") },
    { "Animals & Nature", N("Animals and nature") }, { "Food & Drink", N("Food and drink") },
    { "Travel & Places", N("Travel and places") }, { "Activities", N("Activities") }, { "Objects", N("Objects") },
    { "Symbols", N("Signs") }, { "Flags", N("Flags") },
}
local SYMBOL_GROUPS = {
    { "Arrows", N("Arrows") }, { "Math", N("Mathematics") }, { "Currency", N("Currency") }, { "Punctuation", N("Punctuation") },
    { "Letterlike", N("Letterlike symbols") }, { "Numbers", N("Numbers and fractions") }, { "Greek", N("Greek letters") },
    { "Shapes", N("Shapes") }, { "Technical", N("Technical") }, { "Box drawing", N("Box drawing") }, { "Dingbats", N("Dingbats") },
}
local KAOMOJI = {
    { N("Joy"), { "(◕‿◕)", "(^_^)/", "(^o^)", "(✿◠‿◠)", "ヽ(•‿•)ノ", "(＾▽＾)", "\\(^o^)/", "(•‿•)", "(￣▽￣)", "(*^‿^*)", "o(≧▽≦)o", "(ᵔᴥᵔ)" } },
    { N("Love"), { "(｡♥‿♥｡)", "(づ｡◕‿‿◕｡)づ", "(♡˙︶˙♡)", "(´♡‿♡`)", "(っ˘з(˘⌣˘ )", "♡(˃͈ દ ˂͈ ༶ )", "(◍•ᴗ•◍)❤", "(灬º‿º灬)♡", "(˘︶˘).｡*♡" } },
    { N("Sadness"), { "(•_•)", "(;_;)", "(T_T)", "(╥﹏╥)", "(︶︹︺)", "(ノ_<。)", "(´；ω；`)", "(-_-;)", "(._.)" } },
    { N("Anger"), { "(╯°□°)╯︵ ┻━┻", "┬─┬ノ( º _ ºノ)", "(ง •̀_•́)ง", "(¬_¬)", "(`皿´)", "ヽ(`Д´)ﾉ", "(ಠ_ಠ)", "(눈_눈)", "(╬ಠ益ಠ)" } },
    { N("Surprise"), { "(⊙_⊙)", "(°o°)", "(O_O)", "(ﾟДﾟ)", "Σ(°△°|||)", "(◎_◎;)", "w(°ｏ°)w", "(⊙﹏⊙)", "(・o・)" } },
    { N("Shrug and the rest"), { "¯\\_(ツ)_/¯", "(¬‿¬)", "(⌐■_■)", "( ˘▽˘)っ♨", "(￣ー￣)", "( •_•)>⌐■-■", "(°ロ°)☝", "(ー_ー)zzz", "(｀・ω・´)" } },
    { N("Animals"), { "ʕ•ᴥ•ʔ", "ʕ´•ᴥ•`ʔ", "(=^･ω･^=)", "(^・ω・^ )", "∪･ω･∪", "(•ㅅ•)", "(・⊝・)", "<コ:彡", "~>°)～～～" } },
}
local TONE_NAMES = { N("Default tone"), N("Light skin tone"), N("Medium-light skin tone"), N("Medium skin tone"), N("Medium-dark skin tone"), N("Dark skin tone") }

local all, by_c = nil, {}                    -- latte-emoji's list, and each by its character
local tone_png, tone_asked = {}, {}          -- a tone's picture: its character → path
local st = { tab = "emoji", cat = "all", page = 1, kpage = 1, zoom = nil, editing = nil, query = nil }

function M.load(done)
    if all then return done() end
    run("latte-emoji", {}, function(out)
        local ok, list = pcall(json.decode, out or "")
        all = ok and type(list) == "table" and list or {}
        for i, e in ipairs(all) do
            e.at, by_c[e.c] = i, e
            e.fname = fold(e.name)
            local w = {}
            for j, x in ipairs(e.words or {}) do w[j] = fold(x) end
            e.fwords = w
        end
        done()
    end)
end
function M.reset() st.tab, st.cat, st.page, st.editing = "emoji", "all", 1, nil end
function M.editing() return st.editing end

local function columns(env) return st.zoom or math.clamp(tonumber(env.settings.lens_emoji_cols) or 8, 6, 10) end
local function tone(env) return math.clamp(tonumber(env.settings.lens_emoji_tone) or 0, 0, 5) end
local function pinned(env) env.kept.emoji_pins = env.kept.emoji_pins or {} return env.kept.emoji_pins end
local function words_of(env) env.kept.emoji_words = env.kept.emoji_words or {} return env.kept.emoji_words end
-- the character as it is pasted: in the default skin tone, where the emoji takes tones
local function char(e, env) local t = tone(env) return (t > 0 and e.tones and e.tones[t]) or e.c end
local function picture(e, env)
    local c = char(e, env)
    return c == e.c and e.png or tone_png[c] or e.png
end
-- the pictures of one tone are drawn once, when the tone is first wanted (latte-emoji png)
local function want_tone(env)
    local t = tone(env)
    if t == 0 or tone_asked[t] or not all then return end
    tone_asked[t] = true
    local list = {}
    for _, e in ipairs(all) do if e.tones and e.tones[t] then list[#list + 1] = e.tones[t] end end
    local args = { "png" }
    for _, c in ipairs(list) do args[#args + 1] = c end
    run("latte-emoji", args, function(out)
        local i = 0
        for line in (out or ""):gmatch("[^\n]+") do i += 1 if list[i] then tone_png[list[i]] = line end end
        env.render(true)
    end)
end

local function remember(e, env)
    local recent = env.kept.emoji or {}
    local i = table.find(recent, e.c)
    if i then table.remove(recent, i) end
    table.insert(recent, 1, e.c)
    while #recent > 20 do table.remove(recent) end
    env.kept.emoji = recent
    env.save()
end
local function unicode(c)
    local out = {}
    for _, code in utf8.codes(c) do if code ~= 0xFE0F then out[#out + 1] = string.format("U+%04X", code) end end
    return table.concat(out, " ")
end
local function paste(e, env, c, keep) remember(e, env) env.paste(c or char(e, env), keep) end
local function copy(e, env, c) remember(e, env) env.copy(c or char(e, env)) end
local function primary(e, env) if env.settings.lens_emoji_enter == "copy" then copy(e, env) else paste(e, env) end end

-- the actions of one, as Raycast's: on its right button and Ctrl+K
local function actions(e, env)
    local pins = pinned(env)
    local at = table.find(pins, e.c)
    local copying = env.settings.lens_emoji_enter == "copy"
    local rows = {
        { label = env.main, glyph = "clipboard", keys = not copying and "↵" or "Ctrl+↵", run = function() env.close() paste(e, env) end },
        { label = tr("Copy"), glyph = "copy", keys = copying and "↵" or "Ctrl+↵", run = function() env.close() copy(e, env) end },
        { label = tr("Paste and keep LensShore open"), glyph = "clipboard", run = function() env.close() paste(e, env, nil, true) end },
    }
    if e.tones then
        local function tones(act)
            local sub = {}
            for t = 0, 5 do
                local c = t == 0 and e.c or e.tones[t]
                sub[#sub + 1] = { label = tr(TONE_NAMES[t + 1]), icon = t == 0 and e.png or tone_png[c] or "", run = function() env.close() act(e, env, c) end }
            end
            return sub
        end
        rows[#rows + 1] = { label = tr("Paste with skin tone…"), glyph = "palette", sub = tones(paste), line = true }
        rows[#rows + 1] = { label = tr("Copy with skin tone…"), glyph = "palette", sub = tones(copy) }
    end
    rows[#rows + 1] = { label = tr("Copy the Unicode code"), glyph = "code", line = not e.tones, run = function() env.close() env.copy(unicode(char(e, env))) end }
    rows[#rows + 1] = { label = at and tr("Unpin") or tr("Pin"), glyph = "pin", keys = "Ctrl+.", line = true,
                        run = function() if at then table.remove(pins, at) else pins[#pins + 1] = e.c end env.save() env.render(true) end }
    if at and at > 1 then rows[#rows + 1] = { label = tr("Move up"), glyph = "arrow-up", run = function() pins[at], pins[at - 1] = pins[at - 1], pins[at] env.save() env.render(true) end } end
    if at and at < #pins then rows[#rows + 1] = { label = tr("Move down"), glyph = "arrow-down", run = function() pins[at], pins[at + 1] = pins[at + 1], pins[at] env.save() env.render(true) end } end
    rows[#rows + 1] = { label = tr("Edit the keywords…"), glyph = "pencil", keys = "Ctrl+E", line = true, run = function() M.edit(e, env) end }
    return rows
end

function M.edit(e, env)
    st.editing = e
    env.set_text(words_of(env)[e.c] or "")
    env.render(true)
end
-- Enter while the keywords are being edited: they are kept (comma-separated, as typed)
function M.save_words(text, env)
    local e = st.editing
    st.editing = nil
    if not e then return end
    local w = words_of(env)
    w[e.c] = (text:gsub("^%s+", ""):gsub("%s+$", "")) ~= "" and text or nil
    env.save()
    env.set_text("")
end

-- search, as Tinycast's: every word of what is typed starts a word of the name or of a keyword (the user's own
-- included), in any order; ":+1:" is "+1". The full name first, then the name's first word, then a keyword that is
-- exactly that, then the rest; what was used lately breaks the ties, then Unicode's order.
local function starts_word(text, w) return (" " .. text):find("[%s%-:]" .. w:gsub("%p", "%%%0"), 1) ~= nil end
local function search(q, env)
    local qq = fold(q):gsub("^:(.-):$", "%1"):gsub("^%s+", ""):gsub("%s+$", "")
    local parts = {}
    for w in qq:gmatch("%S+") do parts[#parts + 1] = w end
    if #parts == 0 then return {} end
    local own, recent = words_of(env), {}
    for i, c in ipairs(env.kept.emoji or {}) do recent[c] = i end
    local hits = {}
    for _, e in ipairs(all) do
        local extra = own[e.c] and fold(own[e.c]) or nil
        local ok, in_name = true, true
        for _, w in ipairs(parts) do
            local found = starts_word(e.fname, w)
            if not found then
                in_name = false
                for _, k in ipairs(e.fwords) do if starts_word(k, w) then found = true break end end
                if not found and extra then found = starts_word(extra, w) end
            end
            if not found then ok = false break end
        end
        if ok then
            local score = 5
            if e.fname == qq then score = 0
            elseif e.fname:sub(1, #qq) == qq and (e.fname:sub(#qq + 1, #qq + 1) == "" or e.fname:sub(#qq + 1, #qq + 1):match("[%s,]")) then score = 1
            elseif table.find(e.fwords, qq) or (extra and table.find(extra:split(","), qq)) then score = 2
            elseif in_name then score = 3 end
            hits[#hits + 1] = { e = e, score = score, used = recent[e.c] or 1000 }
        end
    end
    table.sort(hits, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        if a.used ~= b.used then return a.used < b.used end
        return a.e.at < b.e.at
    end)
    local out = {}
    for i, h in ipairs(hits) do out[i] = h.e end
    return out
end

-- the blocks of what the filter and the search show: { label, items }, in order
local function blocks(q, env)
    local cols, out = columns(env), {}
    local function block(label, items) if #items > 0 then out[#out + 1] = { label = label, items = items } end end
    local function in_cat(e) return st.cat == "all" or st.cat == "pins" or st.cat == "recent" or e.group == st.cat end
    if q ~= "" then
        local found = {}
        for _, e in ipairs(search(q, env)) do if in_cat(e) then found[#found + 1] = e end end
        block(tr(N("RESULTS")), found)
        return out
    end
    local pins, recent = {}, {}
    for _, c in ipairs(pinned(env)) do if by_c[c] then pins[#pins + 1] = by_c[c] end end
    for _, c in ipairs(env.kept.emoji or {}) do if by_c[c] and #recent < cols * 2 and not table.find(pinned(env), c) then recent[#recent + 1] = by_c[c] end end
    if st.cat == "all" or st.cat == "pins" then block(tr(N("PINNED")), pins) end
    if st.cat == "all" or st.cat == "recent" then block(tr(N("FREQUENTLY USED")), recent) end
    if st.cat == "pins" or st.cat == "recent" then return out end
    for _, list in ipairs({ GROUPS, SYMBOL_GROUPS }) do
        for _, g in ipairs(list) do
            if st.cat == "all" or st.cat == g[1] then
                local items = {}
                for _, e in ipairs(all) do if e.group == g[1] then items[#items + 1] = e end end
                block(upper(tr(g[2])), items)
            end
        end
    end
    return out
end

-- the pages: the blocks cut into lines of `cols`, so many as fit in `room` pixels, a heading at every block (again at
-- the top of a page a block goes on to)
local function pages(list, cols, room)
    local out, page, used = {}, {}, 0
    local function close() if #page > 0 then out[#out + 1] = page end page, used = {}, 0 end
    for _, b in ipairs(list) do
        local i = 1
        while i <= #b.items do
            local head = 30 + (#page > 0 and 14 or 0)
            if used + head + 50 > room then close() head = 30 end
            local lines = math.max(1, math.floor((room - used - head) / 50))
            local n = math.min(#b.items - i + 1, lines * cols)
            local chunk = {}
            for j = i, i + n - 1 do chunk[#chunk + 1] = b.items[j] end
            page[#page + 1] = { label = b.label, items = chunk }
            used += head + math.ceil(n / cols) * 50
            i += n
            if i <= #b.items then close() end
        end
    end
    close()
    return out
end

local function cat_label()
    if st.cat == "all" then return tr(N("All")) elseif st.cat == "pins" then return tr(N("Pinned")) elseif st.cat == "recent" then return tr(N("Frequently used")) end
    for _, list in ipairs({ GROUPS, SYMBOL_GROUPS }) do for _, g in ipairs(list) do if g[1] == st.cat then return tr(g[2]) end end end
    return st.cat
end
local function cat_menu(env)
    local function pick(id) return function() st.cat, st.page = id, 1 env.render(true) end end
    local rows = { { label = tr(N("All")), on = st.cat == "all", run = pick("all") },
                   { label = tr(N("Pinned")), glyph = "pin", on = st.cat == "pins", run = pick("pins") },
                   { label = tr(N("Frequently used")), glyph = "clock", on = st.cat == "recent", run = pick("recent") } }
    for i, g in ipairs(GROUPS) do rows[#rows + 1] = { label = tr(g[2]), on = st.cat == g[1], line = i == 1, run = pick(g[1]) } end
    local sub = {}
    for _, g in ipairs(SYMBOL_GROUPS) do sub[#sub + 1] = { label = tr(g[2]), on = st.cat == g[1], run = pick(g[1]) } end
    rows[#rows + 1] = { label = tr(N("Symbols")), glyph = "math-symbols", sub = sub, line = true }
    ctx.open(rows, { width = 260 })
end

-- the sections of the mode, the one nearest the line first (as LensShore lays its panel)
function M.sections(q, env)
    local out = {}
    local tabs = {}
    for _, t in ipairs({ { "emoji", N("Emoji") }, { "kaomoji", N("Kaomoji") }, { "gif", N("GIF") } }) do
        tabs[#tabs + 1] = { label = tr(t[2]), on = st.tab == t[1], keep = true, skip = true,
                            run = function() st.tab = t[1] env.render(true) end }
    end
    out[#out + 1] = { { pills = tabs, per = 3 } }
    if st.tab == "gif" then
        for _, s in ipairs(env.gif(q)) do out[#out + 1] = s end
        return out
    end
    if st.editing then
        local e = st.editing
        out[#out + 1] = { { label = tr("Keywords for {name}: type them, separated by commas, and press Enter"):gsub("{name}", function() return e.name end),
                            icon = picture(e, env), quiet = true } }
        return out
    end
    if st.tab == "kaomoji" then
        local k = KAOMOJI[math.clamp(st.kpage, 1, #KAOMOJI)]
        local chips = {}
        for i, t in ipairs(k[2]) do chips[i] = { label = t, main = t, first = i == 1, run = function() env.paste(t) end, right = function() ctx.open({
            { label = env.main, glyph = "clipboard", run = function() env.close() env.paste(t) end },
            { label = tr("Copy"), glyph = "copy", run = function() env.close() env.copy(t) end } }, { width = 240 }) end } end
        local function turn(d) return function() st.kpage = (st.kpage - 1 + d) % #KAOMOJI + 1 env.render(true) end end
        out[#out + 1] = { { pills = { { label = "‹", keep = true, skip = true, run = turn(-1) },
                                      { label = tr(k[1]) .. " · " .. st.kpage .. "/" .. #KAOMOJI, keep = true, skip = true, run = function()
                                          local rows = {}
                                          for i, kk in ipairs(KAOMOJI) do rows[i] = { label = tr(kk[1]), on = i == st.kpage, run = function() st.kpage = i env.render(true) end } end
                                          ctx.open(rows, { width = 240 })
                                      end },
                                      { label = "›", keep = true, skip = true, run = turn(1) } }, per = 3, line = true } }
        out[#out + 1] = { { pills = chips, per = 3 } }
        return out
    end
    if not all then
        out[#out + 1] = { { label = tr(N("Preparing the emoji…")), glyph = "mood-smile", quiet = true } }
        return out
    end
    want_tone(env)
    local cols = columns(env)
    if q ~= st.query then st.query, st.page = q, 1 end
    local list = pages(blocks(q, env), cols, env.room)
    st.page = math.clamp(st.page, 1, math.max(#list, 1))
    local function turn(d) return function() st.page = math.clamp(st.page + d, 1, math.max(#list, 1)) env.render(true) end end
    out[#out + 1] = { { pills = { { label = "‹", keep = true, skip = true, off = st.page <= 1, run = turn(-1) },
                                  { label = cat_label() .. (#list > 1 and ("  " .. st.page .. "/" .. #list) or ""), glyph = "chevron-down", keep = true, skip = true, run = function() cat_menu(env) end },
                                  { label = "›", keep = true, skip = true, off = st.page >= #list, run = turn(1) } }, per = 3, line = true } }
    local page = list[st.page]
    if not page then
        out[#out + 1] = { { label = tr(q ~= "" and N("No emoji is called that") or N("Nothing here yet")), glyph = "mood-smile", quiet = true } }
        return out
    end
    local pins = pinned(env)
    for b, chunk in ipairs(page) do
        local cells = {}
        for i, e in ipairs(chunk.items) do
            cells[i] = { label = e.name, icon = picture(e, env), on = table.find(pins, e.c) ~= nil, main = e.name, first = b == 1 and i == 1,
                         emoji = e, run = function() primary(e, env) end, right = function() ctx.open(actions(e, env), { width = 330 }) end }
        end
        out[#out + 1] = { { head = true, label = chunk.label }, { cells = cells, per = cols } }
    end
    return out
end

-- the keys (lib/card.luau `combo`): Ctrl+Enter the other of paste and copy, Ctrl+. pin, Ctrl+E keywords, Ctrl+plus and
-- minus the columns (for now: the Settings keep the default), Page Down and Up the pages
function M.combo(n, it, env)
    if st.tab == "gif" then return env.gif_combo(n, it) end
    local e = it and it.emoji
    if n == 1 and e then env.close() if env.settings.lens_emoji_enter == "copy" then paste(e, env) else copy(e, env) end
    elseif n == 2 and e then
        local pins = pinned(env)
        local at = table.find(pins, e.c)
        if at then table.remove(pins, at) else pins[#pins + 1] = e.c end
        env.save() env.render(true)
    elseif n == 3 and e then M.edit(e, env)
    elseif n == 4 or n == 5 then st.zoom = math.clamp(columns(env) + (n == 4 and -1 or 1), 6, 10) env.render(true)
    elseif n == 7 or n == 8 then
        if st.tab == "kaomoji" then st.kpage = (st.kpage - 1 + (n == 7 and 1 or -1)) % #KAOMOJI + 1 else st.page = math.max(1, st.page + (n == 7 and 1 or -1)) end
        env.render(true)
    end
end
function M.actual_size(env) st.zoom = nil env.render(true) end

return M
