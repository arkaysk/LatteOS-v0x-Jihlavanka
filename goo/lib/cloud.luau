-- AppCloud (parts/cloud.plm, ROADMAP 6N): the third launcher, a plate in the bottom left corner with the time and the
-- date, and the apps over the whole screen. It is there when Settings › Drops says so (`appcloud`), beside any launcher. The apps are the system's (the `apps` service, as LensShore's), started as LensShore starts them.
-- AppCloud is "dumb" on purpose (6N.05): the field only filters the apps by name and words; no AI, no search of files.
local E = require("lib/engine")
local wm = require("lib/wm")
local icons = require("lib/icons")
local open = require("lib/open")
local timers = require("lib/timers")

local M = {}
local function N(s) return s end
local SHORT = { N("Su"), N("Mo"), N("Tu"), N("We"), N("Th"), N("Fr"), N("Sa") }
local CH = 138                               -- a row of apps, px (the same in parts/cloud.plm: cloud_ch)
local cols, win, first = 8, 80, 0            -- columns; apps in the model: the rows seen and one more; the first row in it
-- the kinds of the freedesktop menu, in the order a phone's drawer has them
local KINDS = { { "Network", N("Internet") }, { "Office", N("Office") }, { "AudioVideo", N("Media") }, { "Graphics", N("Graphics") },
                { "Game", N("Games") }, { "Development", N("Development") }, { "System", N("System") } }

local all, shown, tabs = {}, {}, 0, {}
local function num(v, d) return type(v) == "number" and v or d end
local function kinds_of(a) return type(a.categories) == "table" and table.concat(a.categories, ";") or tostring(a.categories or "") end

-- the time and date on the plate, 24 hours (the user, 5 Nov)
local function tick()
    local t = os.date("*t")
    text.cloud_hm = string.format("%02d:%02d", t.hour, t.min)
    -- a timer or the stopwatch running takes the date's place, as on ClockGoo (6D.13)
    local running, started, left = timers.timer()
    if started then text.cloud_date = timers.clock(left + (running and 999 or 0))
    elseif timers.all().watch.running then text.cloud_date = timers.clock(timers.elapsed())
    else text.cloud_date = tr(SHORT[t.wday]) .. " " .. t.day .. ". " .. t.month .. "." end
end

-- the kinds present, as tabs: All first
local function make_tabs()
    tabs = { { name = tr("All") } }
    for _, k in ipairs(KINDS) do
        for _, a in ipairs(all) do
            if string.find(";" .. kinds_of(a) .. ";", ";" .. k[1] .. ";", 1, true) then tabs[#tabs + 1] = { name = tr(k[2]), kind = k[1] } break end
        end
        if #tabs >= 8 then break end
    end
    model.ctab = tabs
end

-- columns from the screen, and how many apps the model holds: the rows that are seen, and one more
local function size()
    local w, h = num(fact.sw, 0), num(fact.sh, 0)
    if w <= 0 or h <= 0 then return end
    cols = math.max(4, math.min(12, math.floor((w - 160) / 150)))
    win = cols * (math.ceil((h - 236) / CH) + 1)
    fact.cloud_cols, fact.cloud_ch = cols, CH
end
local function view() return math.max(0, num(fact.sh, 0) - 236) end

-- the model is a window of the list: only the rows seen are in it (virtual list), however many apps there are
local function fill()
    size()
    local q = string.lower(text.cloud_q or "")
    local kind = tabs[(num(fact.cloud_tab, 0)) + 1]
    shown = {}
    for _, a in ipairs(all) do
        local name = a.local_name or a.name or a.id or ""
        local words = string.lower(name .. " " .. (a.generic_name or "") .. " " .. (type(a.keywords) == "table" and table.concat(a.keywords, " ") or tostring(a.keywords or "")))
        local in_kind = not (kind and kind.kind) or string.find(";" .. kinds_of(a) .. ";", ";" .. kind.kind .. ";", 1, true) ~= nil
        if in_kind and (q == "" or string.find(words, q, 1, true)) then shown[#shown + 1] = a end
    end
    local total = math.ceil(#shown / cols)
    fact.cloud_max = math.max(0, total * CH - view())
    fact.cloud_target = math.max(0, math.min(num(fact.cloud_target, 0), fact.cloud_max))
    first = math.max(0, math.min(first, total - 1))
    local cells = {}
    for i = 1, win do
        local a = shown[first * cols + i]
        if not a then break end
        cells[i] = { name = a.local_name or a.name or a.id or "", icon = a.icon or "", has_icon = (a.icon or "") ~= "" }
    end
    model.capp = cells
    fact.cloud_first = first
    fact.cloud_n = #cells
    fact.cloud_sel = math.max(0, math.min(num(fact.cloud_sel, 0), #shown - 1))
    fact.cloud_typed = (text.cloud_q or "") ~= ""
end

-- the chosen cell stays in view: the list goes just far enough
local function show_sel()
    local top = math.floor(num(fact.cloud_sel, 0) / cols) * CH
    local t = num(fact.cloud_target, 0)
    if top < t then t = top elseif top + CH > t + view() then t = top + CH - view() end
    fact.cloud_target = math.max(0, math.min(t, num(fact.cloud_max, 0)))
end

-- the plate stands in the water: the apps coming out of it or going back push the level at its end (as TrayShore's panel)
local function surge()
    local w = num(fact.sw, 0)
    if w > 0 then E.ripple((math.max(0, num(fact.cloud_at, 0)) + 168 + 30) / w, 3.5, "stone") end
end
local function close() if fact.cloud_grid then surge() end fact.cloud_grid = false end
local function start_app(a)
    if not a then return end
    close()
    after(350, function() open.app(a) end)         -- as LensGoo waits (lib/lens.luau LET_GO): the keyboard lent to the overlay is let go first, or the app opens without it
end

-- where its plate lies: a wall for the level and the drops, and a stretch they keep off (as TrayShore's)
local function place()
    local w, h = num(fact.sw, 0), num(fact.sh, 0)
    local on = fact.app_cloud == true and w > 0
    local a = num(fact.cloud_at, -1); if a < 0 then a = 0 end
    if on then
        E.block("appcloud", 0, a, a + 168)
        fact["wall.1.x0"], fact["wall.1.y0"], fact["wall.1.x1"], fact["wall.1.y1"] = a, h - 46, a + 168, h
    else
        E.block("appcloud", nil)
        fact["wall.1.x0"], fact["wall.1.x1"] = 0, 0
        close()
    end
end
M.place = place

function M.start()
    text.cloud_ic_apps = icons["apps"] or ""
    text.cloud_ic_search = icons["search"] or ""
    text.cloud_none = tr("Nothing found")
    tick()
    every(1000, tick)
    pcall(sys.watch, "apps", function(list)
        all = type(list) == "table" and list or {}
        table.sort(all, function(x, y) return string.lower(x.local_name or x.name or "") < string.lower(y.local_name or y.name or "") end)
        make_tabs()
        fill()
    end)
    fact.cloud_at = num(E.settings().cloud_at, -1)
    on("fact:app_cloud", place)
    on("fact:sw", function() place() fill() end)
    on("fact:sh", place)
    on("cloud_open", function() if fact.cloud_grid then close() else fact.cloud_grid = true end end)
    -- the keys: across a row, and a row up or down; the list follows the choice
    on("cloud_key", function(k)
        local step = ({ [0] = -1, 1, -cols, cols })[tonumber(k) or 0] or 0
        fact.cloud_sel = math.max(0, math.min(num(fact.cloud_sel, 0) + step, #shown - 1))
        show_sel()
    end)
    on("cloud_opened", function() text.cloud_q, first, fact.cloud_tab, fact.cloud_sel, fact.cloud_target = "", 0, 0, 0, 0 fill() surge() end)
    on("cloud_close", close)
    on("cloud_pick", function(t) fact.cloud_tab = tonumber(t) or 0 first, fact.cloud_target, fact.cloud_sel = 0, 0, 0 fill() end)
    on("cloud_scrolled", function(f) first = tonumber(f) or 0 fill() end)
    on("text:cloud_q", function() first, fact.cloud_target, fact.cloud_sel = 0, 0, 0 fill() end)
    on("cloud_launch", function(k) start_app(shown[first * cols + (tonumber(k) or 0) + 1]) end)
    on("cloud_enter", function()
        local a = shown[num(fact.cloud_sel, 0) + 1] or shown[1]
        if a then start_app(a) end
        -- nothing found: nothing happens (AppCloud has no questions, 6N.05)
    end)
    place()
end

return M
