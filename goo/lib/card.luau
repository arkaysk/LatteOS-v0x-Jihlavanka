-- The card (parts/card.plm, parts/rows.plm): what is in it and what each row does when it is chosen.
-- The scene lays it out and measures it; here are only the rows, as the drop that opens the card lists them:
--
--   card.open(rows, { owner = d, id = "power", width = 320, tabs = { … }, field = { … }, min_height = 400 })
--
-- A row is a table:
--   { label, glyph, icon, hint, line2, on, off, danger, line, quiet, bar, run, right, wheel, keep, sub }
--       glyph   the name of an icon of the icon font; `icon` an app's icon by name or path instead
--       on      ticked · off: not available · quiet: to be read, not pressed · danger: it does not undo
--       line    a rule above it · bar: a bar filled this far (0…1) · line2: a second line under the label
--       run     what a press does; the card closes unless `keep` · right: the right button
--       wheel   function(direction ±1) · sub: rows of a submenu, which gets a row to go back · more: the arrow
--               of a submenu on a row that opens another card itself
--   { head = true, label, hint }                    the heading of a section
--   { big = true, label, bar }                      a large figure
--   { para = true, label }                          a paragraph
--   { profile = true, icon, glyph, label, line2, run, on, hint }       `on` shows `hint` as a small badge (the role)
--   { wave = true }                                  a divider: two layers of coffee, golden behind
-- `pills` and `tiles` with `per = 2` lie wide: an icon in a square, the name beside it, two to a line.
--   { slide = true, glyph, label, value, hint, off, run, set }     a slider: `value` 0…1, set = function(0…1) as it
--       is pressed or dragged, `run` a press on its icon (to mute), `wheel` as on any row
--   { pills = { { label, glyph, on, off, danger, keep, run }, … } }     buttons side by side, six at most
--   { tiles = { { label, icon, glyph, run, right }, … }, per = 4 }     apps as tiles, `per` in a line
-- A card may have a second column: `width2` in the options, and the rows that go there say `col = 2`. At its
-- top it can show a month: `calendar = { title, weekdays = { 7 names }, days = { 42 × { n, dim, today, chosen,
-- dot } }, pick = function(place 0…41), step = function(±1) }`.
-- A tab is { label, glyph, on, run }. The field is { hint, text, secret, change = function(text), submit =
-- function(text) }; `submit` returns true to keep what was typed, `secret` hides it as a password.
-- `tiles`: the rows between two headings are laid as a tile, a card within the card (rules between them are
-- dropped: the tile is what holds them together).
-- Options: `custom` ("clock") draws a scene of its own instead of rows, `split` says where its coffee begins, `grow` lets it grow with the screen (card.z in parts/card.plm). `uniform` is for a family of cards of one size (LensGoo's modes). `menu` makes it a classic context menu (at the pointer, solid, no ear). `pane` (0…1) makes the card glass above its `wave` row and solid coffee below it. `keep` refreshes an open card in place (live figures): the rows do not come in again and the row
-- chosen with the keys stays.
local icons = require("lib/icons")
local born = require("lib/born")
local ctx = require("lib/ctx")
local M = {}

local CARD_W, CARD_H, WAVE_AT = 600, 580, 502            -- a family of cards that keep one size (`uniform`) is this wide and at least this tall
local ROWS, ROWS2, ITEMS, TABS = 24, 12, 6, 6        -- what the scene's models hold
local RISE = 74                             -- how far from the edge the owner steps to be the card's ear
local engine                                -- set by lib/engine.luau, which owns the drops

local shown = { rows = {}, opts = {} }      -- the card as it was last opened
local actions, rights, wheels, slides, tab_runs = {}, {}, {}, {}, {}
local choosable, chosen = {}, nil            -- what the arrow keys walk through, and where they are
local field = nil
local calendar = nil                         -- the month shown, if any: who hears a day pressed
local ear = nil                              -- the drop that stepped out for the open card
local wheel_at = 0                           -- when a row last used the wheel itself

text.g_check, text.g_more, text.g_back, text.g_search, text.g_key = icons["check"], icons["chevron-right"], icons["chevron-left"], icons["search"], icons["key"]

local function glyph(name) return name and (icons[name] or (name:byte(1) or 0) >= 128 and name) or "" end

function M.attach(e) engine = e end
function M.id() return fact.card_open and shown.opts.id or nil end
function M.is_open() return fact.card_open == true end

-- The ear goes back to its edge: it falls and dives.
local function release()
    local d = ear
    if not d then return end
    ear = nil
    engine.lower(d)
end

-- whoever wants to know which card is out now (its id, nil for none), each time one opens or closes
local watchers = {}
function M.watch(f) watchers[#watchers + 1] = f end
local function tell() for _, f in ipairs(watchers) do f(M.id()) end end

function M.close()
    if fact.card_open then fact.card_open = false end
    actions, rights, wheels, slides, tab_runs = {}, {}, {}, {}, {}
    release()
    tell()
end

local function item_record(it)
    return { label = it.label or "", glyph = glyph(it.glyph), icon = it.icon or "", has_icon = (it.icon or "") ~= "",
             on = it.on == true, off = it.off == true, danger = it.danger == true }
end

-- how tall a row of the scene is, as parts/rows.plm lays it out (a paragraph is not known: 0)
local function height_of(it)
    if it.pills or it.tiles then
        local n = #(it.pills or it.tiles)
        local per = math.clamp(it.per or (it.pills and ITEMS or 4), 1, ITEMS)
        return math.ceil(n / per) * ((it.pills and (per <= 2 and 60 or 46)) or (per <= 2 and 66 or 88))
    end
    if it.head then return 30 elseif it.big then return 64 elseif it.profile then return 84 elseif it.slide then return 44
    elseif it.wave then return 26 elseif it.gap then return it.gap end
    return it.line2 and 54 or 44
end

function M.open(rows, opts)
    opts = opts or {}
    -- A card that has a `foot` (a row: a way on to what the card is about) gets the look of coffee below a divider, with the
    -- foot at the bottom of the card: glass above. Not with paragraphs or a month, whose height the rows alone do not tell.
    local footed = false
    if opts.foot and not opts.menu and not opts.dock and not opts.calendar then
        local free = true
        for _, r in ipairs(rows) do if r.wave or r.para then free = false end end
        if free then
            local more = {}
            for i, r in ipairs(rows) do more[i] = r end
            more[#more + 1] = { wave = true }
            more[#more + 1] = opts.foot
            rows, opts.pane, footed = more, opts.pane or 1, true
        end
    end
    -- A family of cards that keep one size (`uniform`: LensGoo's, one for each of its modes): the same width, at least the
    -- same height, and where there is a divider of coffee the foot stays at the bottom. (Other cards keep to their own.)
    local uniform = opts.uniform == true and not opts.menu
    if uniform then
        opts.width = CARD_W
        if not opts.plain then opts.min_height = math.max(opts.min_height or 0, CARD_H) end
    end
    -- so that the cards of one family are alike: the divider of coffee is at the same height in all of them (WAVE_AT, where the fullest
    -- of them has it), what is short gets room above it, and the foot stays at the bottom
    if (uniform and not opts.plain) or (footed and opts.min_height) then
        local want = uniform and WAVE_AT or opts.min_height - 78
        local at, above = nil, 8 + (#(opts.tabs or {}) > 0 and 44 or 0) + (opts.field and 46 or 0)
        for i, r in ipairs(rows) do
            if r.wave then at = i break end
            above = above + height_of(r) + (r.line and i > 1 and 14 or 0)
        end
        if at and above < want then
            local more = {}
            for i, r in ipairs(rows) do
                if i == at then more[#more + 1] = { gap = want - above } end
                more[#more + 1] = r
            end
            rows = more
        end
    end
    local out = {}
    actions, rights, wheels, slides, tab_runs = {}, {}, {}, {}, {}
    choosable = {}

    -- what choosing a row does
    local function action(it)
        if it.sub then
            return function()
                local sub = { { label = tr("Back"), glyph = "chevron-left", back = { rows = rows, opts = opts } } }
                for i, r in ipairs(it.sub) do
                    local copy = table.clone(r)
                    if i == 1 then copy.line = true end
                    sub[#sub + 1] = copy
                end
                -- a submenu keeps the tabs but not the card's name: its owner must not refresh it away
                local o = table.clone(opts)
                o.id, o.keep, o.field, o.width2, o.calendar = nil, nil, nil, nil, nil
                if opts.width2 and it.col == 2 then o.width = opts.width2 end
                M.open(sub, o)
            end
        elseif it.back then
            return function() M.open(it.back.rows, it.back.opts) end
        elseif it.keep then
            return function() if it.run then it.run() end end
        end
        -- what the card starts, a window that may come of it, is born of the drop the card grows from
        return function() local k = fact.card_owner M.close() if it.run then born.touch(k) it.run() end end
    end
    local function bind(id, it)
        actions[id] = action(it)
        rights[id] = it.right
        if not it.off and not it.quiet then choosable[#choosable + 1] = id end
    end

    -- `to`: the column's records; `base`: where the scene starts counting its rows; `room`: how many it holds
    local function add(it, to, base, room)
        if #to >= room then return end
        local list = it.pills or it.tiles
        if list then
            -- A record holds one line of them: more tiles than fit in a line go on in the next record.
            local per = math.clamp(it.per or (it.pills and ITEMS or 4), 1, ITEMS)
            for from = 1, #list, per do
                if #to >= room then break end
                local items = {}
                for j = from, math.min(from + per - 1, #list) do
                    items[#items + 1] = item_record(list[j])
                    bind((base + #to) * 8 + #items, list[j])
                end
                to[#to + 1] = { kind = it.pills and "pills" or "tiles", per = per, items = items, line = it.line == true and from == 1 }
            end
            return
        end
        local kind = (it.gap and "gap") or (it.head and "head") or (it.big and "big") or (it.para and "para") or (it.profile and "profile") or (it.slide and "slide") or (it.wave and "wave") or "plain"
        local pressed = (kind == "plain" or kind == "profile" or kind == "slide" or (kind == "big" and it.run ~= nil)) and not it.quiet
        if kind == "slide" then it = table.clone(it) it.bar, it.keep = it.value or 0, true slides[base + #to] = it.set end
        to[#to + 1] = {
            kind = kind, label = it.label or "", hint = it.hint or "", line2 = it.line2 or "", glyph = glyph(it.glyph),
            icon = it.icon or "", has_icon = (it.icon or "") ~= "", tall = kind == "plain" and (it.line2 or "") ~= "",
            on = it.on == true, off = it.off == true, quiet = not pressed,
            danger = it.danger == true, more = it.sub ~= nil or it.more == true, line = it.line == true and #to > 0,
            bar = it.gap or (type(it.bar) == "number" and it.bar or -1),
        }
        if pressed then bind((base + #to - 1) * 8, it) end
        if it.wheel then wheels[base + #to - 1] = it.wheel end
    end
    local out2 = {}
    for _, it in ipairs(rows) do
        if it.col == 2 and opts.width2 then add(it, out2, ROWS, ROWS2) else add(it, out, 0, ROWS) end
    end
    if opts.tiles then
        local IN = { plain = true, slide = true, profile = true, big = true }
        for _, list in ipairs({ out, out2 }) do
            local from = nil
            for i = 1, #list + 1 do
                local inside = list[i] ~= nil and IN[list[i].kind] == true
                if inside and not from then from = i end
                if not inside and from then
                    for k = from, i - 1 do
                        list[k].tile = (i - 1 == from and 4) or (k == from and 1) or (k == i - 1 and 3) or 2
                        list[k].line = false
                    end
                    from = nil
                end
            end
        end
    end

    local tabs = {}
    for i, t in ipairs(opts.tabs or {}) do
        if i > TABS then break end
        tabs[i] = { label = t.label or "", glyph = glyph(t.glyph), on = t.on == true }
        tab_runs[i] = t.run
    end

    -- The owner steps away from its edge and sits in the card's corner.
    local owner = opts.owner
    if owner and engine.can_rise(owner) then
        if ear and ear ~= owner then release() end
        if ear ~= owner then ear = owner engine.raise(owner, RISE) end
        fact.card_owner = owner.k
    elseif not opts.keep then
        release()
        fact.card_owner = -1
    end

    fact.card_pane = opts.pane or 0
    fact.card_menu = opts.menu == true
    fact.card_custom = (opts.custom == "clock" and 1) or (opts.custom == "cam" and 2) or (opts.custom == "ai" and 3) or (opts.custom == "calendar" and 4) or 0       -- the card is a scene of its own (parts/clock.plm), not rows
    -- where the coffee of a `wave` row begins: the heights of the rows above it, as parts/rows.plm lays them out
    local split, waved = (#tabs > 0 and 44 or 0) + (opts.field and 46 or 0), false
    for _, r in ipairs(out) do
        if r.kind == "wave" then waved, split = true, split + 10 break end
        local h = ({ plain = r.tall and 54 or 44, head = 30, big = 64, para = 0, profile = 84, slide = 44, gap = r.bar })[r.kind]
        if r.kind == "pills" then h = r.per <= 2 and 60 or 46 elseif r.kind == "tiles" then h = r.per <= 2 and 66 or 88 end
        split = split + (h or 0) + (r.line and 14 or 0)
    end
    fact.card_split = opts.split or (waved and split + 4 or 0)
    fact.card_dock, fact.card_dock_w = opts.dock ~= nil, tonumber(opts.dock) or 0
    fact.card_strip = opts.strip == true          -- its owner is stretched into a strip: the card grows out of all of it

    local fresh = not opts.keep or not fact.card_open
    if fresh then
        chosen = nil
        fact.card_sel = -1
        fact.card_gen = fact.card_gen + 1
        if not fact.card_open then fact.card_peak = 0 end
    elseif chosen and not actions[chosen] then
        chosen = nil
        fact.card_sel = -1
    end
    local had = field ~= nil and fact.card_open
    field = opts.field
    if field then
        text.card_hint = field.hint or ""
        fact.card_secret = field.secret == true
    end
    if field and (fresh or not had) then
        text.card_q, text.card_pw = "", ""
        M.text(field.text or "")
        -- what is typed goes to the field without a press
        after(60, function() if field then focus(field.secret and "card_pw" or "card_q") end end)
    end
    shown = { rows = rows, opts = opts }
    model.card = out
    model.card2 = out2
    model.tab = tabs
    calendar = opts.width2 and opts.calendar or nil
    if calendar then
        local names = {}
        for i, n in ipairs(calendar.weekdays or {}) do names[i] = { name = n } end
        model.weekday, model.day, text.cal_title = names, calendar.days or {}, calendar.title or ""
    end
    fact.cal_on = calendar ~= nil
    fact.card_w2 = opts.width2 and math.floor(opts.width2 * 1.2) or 0
    fact.card_w = math.floor((opts.width or 250) * 1.2)
    fact.card_min = opts.min_height or 0
    fact.card_grow = opts.grow == true
    fact.card_field = field ~= nil
    fact.card_open = #out > 0 or field ~= nil or opts.custom ~= nil
    tell()
end

-- what is typed in the field: read it, or put something there
function M.text(v)
    local name = (field and field.secret) and "card_pw" or "card_q"
    if v ~= nil then text[name], fact.card_typed = v, v ~= "" end
    return text[name] or ""
end

on("card_pick", function(id)
    local f = actions[id or 0]
    if f then f() end
end)
on("card_right", function(id)
    local f = rights[id or 0]
    if f then f() end
end)
on("card_wheel", function(v)
    local f = wheels[(v or 0) // 2]
    if f then wheel_at = os.clock() f((v or 0) % 2 == 1 and 1 or -1) end
end)
on("card_slide", function(v)
    local set = slides[(v or 0) // 1024]
    if set then set(((v or 0) % 1024) / 1000) end
end)
on("card_closed", function() M.close() end)
on("cal_pick", function(place) if calendar and calendar.pick and fact.card_open then calendar.pick(place or 0) end end)
on("cal_step", function(v) if calendar and calendar.step and fact.card_open then calendar.step(v == 1 and 1 or -1) end end)

local function step_tab(dir)
    local n, at = #tab_runs, 0
    if n == 0 then return end
    for i, t in ipairs(model.tab or {}) do if t.on then at = i end end
    local f = tab_runs[(at - 1 + dir) % n + 1]
    if f then f() end
end
on("card_tab", function(i) local f = tab_runs[(i or 0) + 1] if f then f() end end)
on("card_next", function(v) wheel_at = os.clock() step_tab(v == 1 and 1 or -1) end)   -- the wheel over the tabs: not the card's turn too
-- The wheel anywhere on the card turns the tabs. The scene tells both the row and the card of the same notch,
-- so the card waits a moment to see whether a row took it.
on("card_spin", function(v)
    after(30, function()
        if os.clock() - wheel_at > 0.12 and fact.card_open then step_tab(v == 1 and 1 or -1) end
    end)
end)

on("card_key", function(v)
    if #choosable == 0 then return end
    local at = 0
    for i, id in ipairs(choosable) do if id == chosen then at = i end end
    at = v == 1 and (at % #choosable + 1) or ((at - 2) % #choosable + 1)
    chosen = choosable[at]
    fact.card_sel = chosen
end)

on("card_enter", function()
    -- a row chosen with the arrows comes before what is typed
    if chosen and actions[chosen] then
        local f = actions[chosen]
        chosen = nil
        fact.card_sel = -1
        f()
        return
    end
    if not field then return end
    local v = M.text()
    if not field.secret then v = v:gsub("^%s+", ""):gsub("%s+$", "") end
    local keep = field.submit and v ~= "" and field.submit(v) == true
    if not keep then M.text("") end
end)

-- Typing is reported after a short pause, not for every letter.
local typing = nil
local function typed()
    fact.card_typed = M.text() ~= ""
    if not (field and field.change) then return end
    if typing then cancel(typing) end
    typing = after(140, function()
        typing = nil
        if field and field.change and fact.card_open then field.change(M.text()) end
    end)
end
on("text:card_q", typed)
-- The right button on the field, as on any field: cut, copy, paste (Ctrl+X, C, V work by themselves). What is written
-- here is not typed, so the field is told of it as if it were.
on("card_field_menu", function()
    local now = text.card_q or ""
    local function put(t) text.card_q = t typed() end
    local rows = {}
    if now ~= "" then
        rows[#rows + 1] = { label = tr("Cut"), glyph = "cut", keys = "Ctrl+X", run = function() pcall(sys.call, "clipboard.set", now) put("") end }
        rows[#rows + 1] = { label = tr("Copy"), glyph = "copy", keys = "Ctrl+C", run = function() pcall(sys.call, "clipboard.set", now) end }
    end
    rows[#rows + 1] = { label = tr("Paste"), glyph = "clipboard", keys = "Ctrl+V", run = function()
        local ok, got = pcall(sys.ask, "clipboard")
        if ok and type(got) == "string" and got ~= "" then put(now .. got) end
    end }
    ctx.open(rows, { width = 260 })
end)
on("text:card_pw", typed)

return M
