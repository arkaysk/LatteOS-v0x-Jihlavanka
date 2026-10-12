-- SAFE's logic: it reports the load, the windows and the date, starts what the bar's buttons ask for and
-- serves the typing row. A mode of the row is one entry in MODES and one branch in `search`.
local fold = require("lib/fold")
local dangerous = require("lib/dangerous")
local icons = require("lib/icons")

text.g_power, text.g_term, text.g_search, text.g_prompt = icons["power"], icons["terminal-2"], icons["search"], icons["prompt"]

local function go(cmd, args) run(cmd, args or {}, nil, { output = false }) end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

on("menu", function() go("foot", { "-T", "LatteOS SAFE", "-e", "latte-safe" }) end)
on("terminal", function() go("foot") end)

-- in the order the power menu draws them
local MACHINE = { [0] = { "labwc", { "--exit" } }, { "systemctl", { "suspend" } }, { "systemctl", { "reboot" } },
                  { "systemctl", { "poweroff" } } }
on("machine", function(i)
    local m = MACHINE[tonumber(i) or -1]
    if m then go(m[1], m[2]) end
end)

-- ── the load ────────────────────────────────────────────────────────────────────────────────────────────────
local function gb(bytes) return string.format("%.1f G", (bytes or 0) / 1073741824) end
local function watch_stats()
    spawn("latte-stats", { "1" }, function(line)
        local ok, s = pcall(json.decode, line or "")
        if not ok or type(s) ~= "table" then return end
        local t = "CPU " .. (s.cpu or 0) .. " %   RAM " .. gb(s.ram)
        if s.gpu ~= nil then t = t .. "   GPU " .. s.gpu .. " %" end
        if (s.vram_total or 0) > 0 then t = t .. "   VRAM " .. gb(s.vram) end
        text.stats = t
    end, function() after(3000, watch_stats) end)      -- it ended: start it again
end
watch_stats()

local function show_date()
    run("date", { "+" .. tr("%A, %-d %B") }, function(out) text.date = trim(out) end)
end
show_date()
every(30000, show_date)

-- ── the windows ─────────────────────────────────────────────────────────────────────────────────────────────
local windows = {}
sys.watch("window", function(v)
    windows = (v and v.list) or {}
    local chips = {}
    for i, w in ipairs(windows) do
        if i > 3 then break end
        local title = w.title
        if title == nil or title == "" then title = w.class or "" end
        chips[i] = { title = title, active = w.active == true }
    end
    model.wins = chips
end)
on("window", function(i)
    local w = windows[(tonumber(i) or -1) + 1]
    if not w then return end
    if w.active and not w.minimized then pcall(sys.call, "window.minimize", w.id) else pcall(sys.call, "window.restore", w.id) end
end)

-- ── the typing row ──────────────────────────────────────────────────────────────────────────────────────────
local MODES = { [0] = "apps", "code" }     -- by the scene's `mode`
local apps, rows, confirm = {}, {}, nil    -- installed apps; what is shown now, each with what it does; the command asked about
pcall(sys.watch, "apps", function(list) apps = list or {} end)

local function show(found)
    rows = found or {}
    local m = {}
    for i, r in ipairs(rows) do
        if i <= 8 then m[i] = { title = r.title, sub = r.sub or "", icon = r.icon or "", g = r.g or "" } end
    end
    model.results = m
end
local function clear() text.q = "" confirm = nil show({}) end

-- An app ranks by where its name matches: at the start, at the start of a word, anywhere; then by its id.
local function find_apps(q)
    local want, hits = fold(q), {}
    for _, a in ipairs(apps) do
        local name = fold(a.name)
        local at = name:find(want, 1, true)
        local score = at == 1 and 3 or (at and name:sub(at - 1, at - 1):match("[%s%-_]") and 2) or (at and 1)
            or (fold(a.id):find(want, 1, true) and 0.5) or 0
        if score > 0 then hits[#hits + 1] = { app = a, score = score, name = name } end
    end
    table.sort(hits, function(x, y) if x.score ~= y.score then return x.score > y.score end return x.name < y.name end)
    local found = {}
    for i = 1, math.min(#hits, 8) do
        local a = hits[i].app
        found[i] = { title = a.name or a.id, sub = a.generic or a.comment or "", icon = a.icon or "application-x-executable",
                     act = function() if a.exec then pcall(sys.call, "apps.launch", a.exec) end end }
    end
    return found
end

local function run_code(cmd)
    go("foot", { "sh", "-c", cmd .. '; exec "${SHELL:-/bin/bash}"' })     -- the terminal stays open after the command
    clear()
end

local function search()
    local t = trim(text.q)
    fact.typing = t ~= ""
    confirm = nil
    if t == "" then return show({}) end
    local mode = MODES[fact.mode]
    if mode == "apps" then
        show(find_apps(t))
    elseif mode == "code" then
        show({ { title = tr("Run in console"), sub = t, g = icons["terminal-2"], act = function() run_code(t) end } })
    end
end
on("text:q", search)
on("fact:mode", search)
on("cleared", clear)

-- A dangerous command is asked about once: the same line entered again runs.
local function confirmed(cmd)
    if not dangerous(cmd) or confirm == cmd then return true end
    confirm = cmd
    show({ { title = tr("Dangerous command: press Enter again to run it"), sub = cmd, g = icons["alert-triangle"] } })
    return false
end

on("entered", function()
    local t = trim(text.q)
    if t == "" then return end
    if MODES[fact.mode] == "code" then
        if confirmed(t) then run_code(t) end
        return
    end
    local first = rows[1]
    if first and first.act then first.act() clear() end
end)

on("picked", function(i)
    local r = rows[(tonumber(i) or -1) + 1]
    if not r or not r.act then return end
    if MODES[fact.mode] == "code" and not confirmed(trim(text.q)) then return end
    r.act()
    clear()
end)
