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
--       wheel   function(direction ±1) · sub: rows of a submenu, which gets a row to go back
--   { head = true, label, hint }                    the heading of a section
--   { big = true, label, bar }                      a large figure
--   { para = true, label }                          a paragraph
--   { profile = true, icon, glyph, label, line2, run }
--   { pills = { { label, glyph, on, off, danger, keep, run }, … } }     buttons side by side, six at most
--   { tiles = { { label, icon, glyph, run, right }, … }, per = 4 }     apps as tiles, `per` in a line
-- A tab is { label, glyph, on, run }. The field is { hint, text, change = function(text), submit = function(text) };
-- `submit` returns true to keep what was typed.
-- Options: `keep` refreshes an open card in place (live figures): the rows do not come in again and the row
-- chosen with the keys stays.
local icons = require("lib/icons")
local M = {}

local ROWS, ITEMS, TABS = 24, 6, 6           -- what the scene's models hold
local RISE = 74                             -- how far from the edge the owner steps to be the card's ear
local engine                                -- set by lib/engine.luau, which owns the drops

local shown = { rows = {}, opts = {} }      -- the card as it was last opened
local actions, rights, wheels, tab_runs = {}, {}, {}, {}
local choosable, chosen = {}, nil            -- what the arrow keys walk through, and where they are
local field = nil
local ear = nil                              -- the drop that stepped out for the open card
local wheel_at = 0                           -- when a row last used the wheel itself

text.g_check, text.g_more, text.g_search = icons["check"], icons["chevron-right"], icons["search"]

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

function M.close()
    if fact.card_open then fact.card_open = false end
    actions, rights, wheels, tab_runs = {}, {}, {}, {}
    release()
end

local function item_record(it)
    return { label = it.label or "", glyph = glyph(it.glyph), icon = it.icon or "", has_icon = (it.icon or "") ~= "",
             on = it.on == true, off = it.off == true, danger = it.danger == true }
end

function M.open(rows, opts)
    opts = opts or {}
    local out = {}
    actions, rights, wheels, tab_runs = {}, {}, {}, {}
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
                o.id, o.keep, o.field = nil, nil, nil
                M.open(sub, o)
            end
        elseif it.back then
            return function() M.open(it.back.rows, it.back.opts) end
        elseif it.keep then
            return function() if it.run then it.run() end end
        end
        return function() M.close() if it.run then it.run() end end
    end
    local function bind(id, it)
        actions[id] = action(it)
        rights[id] = it.right
        if not it.off and not it.quiet then choosable[#choosable + 1] = id end
    end

    for _, it in ipairs(rows) do
        if #out >= ROWS then break end
        local list = it.pills or it.tiles
        if list then
            -- A record holds one line of them: more tiles than fit in a line go on in the next record.
            local per = it.pills and ITEMS or math.clamp(it.per or 4, 1, ITEMS)
            for from = 1, #list, per do
                if #out >= ROWS then break end
                local items = {}
                for j = from, math.min(from + per - 1, #list) do
                    items[#items + 1] = item_record(list[j])
                    bind(#out * 8 + #items, list[j])
                end
                out[#out + 1] = { kind = it.pills and "pills" or "tiles", per = per, items = items, line = it.line == true and from == 1 }
            end
        else
            local kind = (it.head and "head") or (it.big and "big") or (it.para and "para") or (it.profile and "profile") or "plain"
            local pressed = (kind == "plain" or kind == "profile" or (kind == "big" and it.run ~= nil)) and not it.quiet
            out[#out + 1] = {
                kind = kind, label = it.label or "", hint = it.hint or "", line2 = it.line2 or "", glyph = glyph(it.glyph),
                icon = it.icon or "", has_icon = (it.icon or "") ~= "", tall = kind == "plain" and (it.line2 or "") ~= "",
                on = it.on == true, off = it.off == true, quiet = not pressed,
                danger = it.danger == true, more = it.sub ~= nil, line = it.line == true and #out > 0,
                bar = type(it.bar) == "number" and it.bar or -1,
            }
            local id = (#out - 1) * 8
            if pressed then bind(id, it) end
            if it.wheel then wheels[#out - 1] = it.wheel end
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
    field = opts.field
    if field and fresh then
        text.card_hint = field.hint or ""
        M.text(field.text or "")
    end
    shown = { rows = rows, opts = opts }
    model.card = out
    model.tab = tabs
    fact.card_w = math.floor((opts.width or 250) * 1.2)
    fact.card_min = opts.min_height or 0
    fact.card_field = field ~= nil
    fact.card_open = #out > 0 or field ~= nil
end

-- what is typed in the field: read it, or put something there
function M.text(v)
    if v ~= nil then text.card_q, fact.card_typed = v, v ~= "" end
    return text.card_q or ""
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
on("card_closed", function() M.close() end)

local function step_tab(dir)
    local n, at = #tab_runs, 0
    if n == 0 then return end
    for i, t in ipairs(model.tab or {}) do if t.on then at = i end end
    local f = tab_runs[(at - 1 + dir) % n + 1]
    if f then f() end
end
on("card_tab", function(i) local f = tab_runs[(i or 0) + 1] if f then f() end end)
on("card_next", function(v) step_tab(v == 1 and 1 or -1) end)
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
    local v = (text.card_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local keep = field.submit and v ~= "" and field.submit(v) == true
    if not keep then M.text("") end
end)

-- Typing is reported after a short pause, not for every letter.
local typing = nil
on("text:card_q", function()
    fact.card_typed = (text.card_q or "") ~= ""
    if not (field and field.change) then return end
    if typing then cancel(typing) end
    typing = after(140, function()
        typing = nil
        if field and field.change and fact.card_open then field.change(text.card_q or "") end
    end)
end)

return M
