-- LensCloud (parts/cloud.plm, ROADMAP 6N): the third launcher, a plate in the bottom left corner with the time and the
-- date, and the apps over the whole screen. It is there only when it is the launcher chosen (Settings › Drops:
-- `lens` = "cloud"). The apps are the system's (the `apps` service, as LensShore's), started as LensShore starts them.
-- ponytail: the field filters the apps by name and words; it is not yet LensShore's whole search (6N.03 "one brain").
local E = require("lib/engine")
local wm = require("lib/wm")
local icons = require("lib/icons")
local open = require("lib/open")

local M = {}
local function N(s) return s end
local SHORT = { N("Su"), N("Mo"), N("Tu"), N("We"), N("Th"), N("Fr"), N("Sa") }
local PAGE = 32
-- the kinds of the freedesktop menu, in the order a phone's drawer has them
local KINDS = { { "Network", N("Internet") }, { "Office", N("Office") }, { "AudioVideo", N("Media") }, { "Graphics", N("Graphics") },
                { "Game", N("Games") }, { "Development", N("Development") }, { "System", N("System") } }

local all, shown, page, tabs = {}, {}, 0, {}
local function num(v, d) return type(v) == "number" and v or d end
local function kinds_of(a) return type(a.categories) == "table" and table.concat(a.categories, ";") or tostring(a.categories or "") end

-- the time and date on the plate, 24 hours (the user, 5 Nov)
local function tick()
    local t = os.date("*t")
    text.cloud_hm = string.format("%02d:%02d", t.hour, t.min)
    text.cloud_date = tr(SHORT[t.wday]) .. " " .. t.day .. ". " .. t.month .. "."
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

local function fill()
    local q = string.lower(text.cloud_q or "")
    local kind = tabs[(num(fact.cloud_tab, 0)) + 1]
    shown = {}
    for _, a in ipairs(all) do
        local name = a.local_name or a.name or a.id or ""
        local words = string.lower(name .. " " .. (a.generic_name or "") .. " " .. (type(a.keywords) == "table" and table.concat(a.keywords, " ") or tostring(a.keywords or "")))
        local in_kind = not (kind and kind.kind) or string.find(";" .. kinds_of(a) .. ";", ";" .. kind.kind .. ";", 1, true) ~= nil
        if in_kind and (q == "" or string.find(words, q, 1, true)) then shown[#shown + 1] = a end
    end
    local pages = math.max(1, math.ceil(#shown / PAGE))
    page = math.max(0, math.min(page, pages - 1))
    local cells = {}
    for i = 1, PAGE do
        local a = shown[page * PAGE + i]
        if not a then break end
        cells[i] = { name = a.local_name or a.name or a.id or "", icon = a.icon or "", has_icon = (a.icon or "") ~= "" }
    end
    model.capp = cells
    fact.cloud_n = #cells
    fact.cloud_sel = math.max(0, math.min(num(fact.cloud_sel, 0), #cells - 1))
    fact.cloud_typed = (text.cloud_q or "") ~= ""
    fact.cloud_more = pages > 1
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
    open.app(a)
end

-- where its plate lies: a wall for the level and the drops, and a stretch they keep off (as TrayShore's)
local function place()
    local w, h = num(fact.sw, 0), num(fact.sh, 0)
    local on = fact.lens_cloud == true and w > 0
    local a = num(fact.cloud_at, -1); if a < 0 then a = 0 end
    if on then
        E.block("lenscloud", 0, a, a + 168)
        fact["wall.1.x0"], fact["wall.1.y0"], fact["wall.1.x1"], fact["wall.1.y1"] = a, h - 46, a + 168, h
    else
        E.block("lenscloud", nil)
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
    every(5000, tick)
    pcall(sys.watch, "apps", function(list)
        all = type(list) == "table" and list or {}
        table.sort(all, function(x, y) return string.lower(x.local_name or x.name or "") < string.lower(y.local_name or y.name or "") end)
        make_tabs()
        fill()
    end)
    fact.cloud_at = num(E.settings().cloud_at, -1)
    on("fact:lens_cloud", place)
    on("fact:sw", place)
    on("fact:sh", place)
    on("cloud_open", function() if fact.cloud_grid then close() else fact.cloud_grid = true end end)
    -- the keys: across a row, and a row up or down (a page further at the end)
    on("cloud_key", function(k)
        k = tonumber(k) or 0
        local sel, n = num(fact.cloud_sel, 0), num(fact.cloud_n, 0)
        local step = ({ [0] = -1, 1, -8, 8 })[k] or 0
        local to = sel + step
        if to >= n and (k == 1 or k == 3) and (page + 1) * PAGE < #shown then page = page + 1 fact.cloud_sel = 0 fill() return end
        if to < 0 and (k == 0 or k == 2) and page > 0 then page = page - 1 fill() fact.cloud_sel = num(fact.cloud_n, 1) - 1 return end
        fact.cloud_sel = math.max(0, math.min(to, n - 1))
    end)
    on("cloud_opened", function() text.cloud_q, page, fact.cloud_tab, fact.cloud_sel = "", 0, 0, 0 fill() surge() end)
    on("cloud_close", close)
    on("cloud_pick", function(t) fact.cloud_tab = tonumber(t) or 0 page = 0 fill() end)
    on("cloud_wheel", function(down) page = page + ((tonumber(down) or 0) == 1 and 1 or -1) fill() end)
    on("text:cloud_q", function() page, fact.cloud_sel = 0, 0 fill() end)
    on("cloud_launch", function(k) start_app(shown[page * PAGE + (tonumber(k) or 0) + 1]) end)
    on("cloud_enter", function()
        local a = shown[page * PAGE + num(fact.cloud_sel, 0) + 1] or shown[1]
        if a then start_app(a) return end
        -- nothing of the apps: LensAI answers it (ponytail: LensShore's whole search comes with 6N.03)
        local q = text.cloud_q or ""
        close()
        if q ~= "" then run("latte-app", { "lensai", q }, function() end) end
    end)
    place()
end

return M
