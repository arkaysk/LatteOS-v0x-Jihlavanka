-- PowerGoo: the account, power and leaving. A small drop almost under the edge that rises the most of all.
-- A press opens its card: who is logged in, the battery and the power profile, and the ways out: log out,
-- sleep, restart, shut down. With windows open, one that does not undo asks once more first.
-- The right button stretches it along its edge into the performance strip (parts/strip.plm): the processor,
-- the memory, the graphics card and its memory, once a second from latte-stats. The drops beside it are
-- pushed aside and come back when the strip is drawn in, unless someone moved them meanwhile. A strip left
-- on is there again after the next login.
-- On a laptop it carries the battery as beads: three green from 60 %, two yellow from 30 %, one red below;
-- under 10 % its core pulses red, and while charging it breathes.
local card = require("lib/card")
local E = require("lib/engine")
local wm = require("lib/wm")
local bar = require("lib/bar")
local lock = require("lib/lock")
local settings = require("lib/settings")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local user, host, since = "", "", os.date("%H:%M")
local battery = nil
local profile, profiles = nil, false          -- the power profile in use; whether this machine has any
local armed = nil                             -- the way out that was asked about, for four seconds
local open_card

-- ── the performance strip ────────────────────────────────────────────────────────────────────────────────────
local FILE = "power.json"
local CELL, CELL_SIDE = 64, 50                -- a cell's length along the bottom and top edges; on the sides
local R = 22                                  -- the capsule's radius: a cell holds a name, a figure and a bar
local strip = { on = false, job = nil, cells = {} }

local function gb(bytes)
    local tenths = math.floor((bytes or 0) / 2 ^ 30 * 10 + 0.5)
    return string.format(tr("%d.%d G"), tenths // 10, tenths % 10)
end
-- how a figure is coloured: 0 fine, 1 high, 2 critical; a part that runs hot counts as well
local function state(percent, temp, warm, hot)
    if percent >= 95 or (temp and temp >= hot) then return 2 end
    if percent >= 80 or (temp and temp >= warm) then return 1 end
    return 0
end
local function degrees(t) return t and ("  ·  " .. t .. " °C") or "" end
local function cells_of(s)
    local out = {}
    local cpu = tonumber(s.cpu) or 0
    out[#out + 1] = { name = "CPU", value = cpu .. " %", level = cpu / 100, state = state(cpu, s.cpu_temp, 80, 90),
                      tip = tr("Processor") .. " " .. cpu .. " %" .. degrees(s.cpu_temp) }
    local ram = (s.ram_total or 0) > 0 and math.floor(100 * (s.ram or 0) / s.ram_total + 0.5) or 0
    out[#out + 1] = { name = "RAM", value = gb(s.ram), level = ram / 100, state = state(ram),
                      tip = tr("Memory") .. " " .. gb(s.ram) .. " / " .. gb(s.ram_total) .. "  (" .. ram .. " %)" }
    if s.gpu ~= nil then
        out[#out + 1] = { name = "GPU", value = s.gpu .. " %", level = s.gpu / 100, state = state(s.gpu, s.gpu_temp, 85, 95),
                          tip = tr("Graphics") .. " " .. s.gpu .. " %" .. degrees(s.gpu_temp) }
    end
    if (s.vram_total or 0) > 0 then
        local vram = math.floor(100 * (s.vram or 0) / s.vram_total + 0.5)
        out[#out + 1] = { name = "VRAM", value = gb(s.vram), level = vram / 100, state = state(vram),
                          tip = tr("Video memory") .. " " .. gb(s.vram) .. " / " .. gb(s.vram_total) .. "  (" .. vram .. " %)" }
    end
    return out
end

-- The capsule is as long as its cells and grows to the side that has room: away from LensGoo unless the
-- edge ends there.
local function shape(d)
    local cell = d.edge % 2 == 1 and CELL_SIDE or CELL
    fact.strip_owner, fact.strip_cell = d.k, cell
    d:stretch(math.max(#strip.cells, 1) * cell / 2 + 3, R)
end
local function paint(d, s)
    local cells = cells_of(s)
    local grew = #cells ~= #strip.cells
    strip.cells = cells
    model.cell = cells
    if grew then shape(d) end
end
local function watch(d)
    strip.job = spawn("latte-stats", { "1" }, function(line)
        local ok, s = pcall(json.decode, line or "")
        if ok and type(s) == "table" and strip.on then paint(d, s) end
    end, function()
        strip.job = nil
        if strip.on then after(3000, function() if strip.on and not strip.job then watch(d) end end) end     -- it ended: again
    end)
end
local function strip_on(d, quiet)
    if strip.on then return end
    strip.on = true
    strip.cells = cells_of({ cpu = 0 })
    model.cell = {}
    shape(d)
    fact.strip_on = true
    watch(d)
    if quiet then return end
    d:squash()
    d:ripple(4)
    pcall(sys.call, "files.write", FILE, { strip = true })
end
local function strip_off(d)
    if not strip.on then return end
    strip.on = false
    if strip.job then pcall(kill, strip.job) strip.job = nil end
    fact.strip_on = false
    d:shrink()
    d:ripple(3)
    pcall(sys.call, "files.write", FILE, { strip = false })
end

local LEAVE = {
    logout = wm.logout,
    sleep = function() pcall(sys.call, "session.suspend") end,
    restart = function() pcall(sys.call, "session.reboot") end,
    off = function() pcall(sys.call, "session.poweroff") end,
}
local function leave(how, d)
    return function()
        local n = #bar.windows()
        if n > 0 and how ~= "sleep" and armed ~= how then
            armed = how
            open_card(d, true)
            after(4000, function() if armed == how then armed = nil if card.id() == "power" then open_card(d, true) end end end)
            return
        end
        armed = nil
        card.close()
        after(200, LEAVE[how])
    end
end
local function ask(how, label)
    if armed ~= how then return tr(label) end
    return tr("Sure?") .. " (" .. tr("windows:") .. " " .. #bar.windows() .. ")"
end

local function read_profile(then_do)
    run("powerprofilesctl", { "get" }, function(out, code)
        profiles = code == 0
        profile = profiles and (out or ""):match("[%a%-]+") or nil
        if then_do then then_do() end
    end)
end
local function set_profile(name, d)
    return function()
        run("powerprofilesctl", { "set", name }, function() read_profile(function() if card.id() == "power" then open_card(d, true) end end) end)
    end
end

open_card = function(d, keep)
    local rows = {
        { profile = true, glyph = "user", label = user, line2 = user .. "@" .. host .. " · " .. tr("since") .. " " .. since, quiet = true },
        { pills = { { label = tr("Lock"), glyph = "lock", run = function() after(200, lock.lock) end },
                    { label = ask("logout", N("Log out")), glyph = "logout", on = armed == "logout", keep = true, run = leave("logout", d) } } },
    }
    if battery or profiles then rows[#rows + 1] = { head = true, label = tr("POWER"), line = true } end
    if battery then
        rows[#rows + 1] = { label = tr("Battery"), glyph = battery.charging and "battery-charging" or "battery-3", bar = battery.percent / 100, quiet = true,
                            hint = math.floor(battery.percent) .. " %" .. (battery.charging and (" · " .. tr("charging")) or "") }
    end
    if profiles then
        rows[#rows + 1] = { pills = {
            { label = tr("Saver"), glyph = "leaf", on = profile == "power-saver", keep = true, run = set_profile("power-saver", d) },
            { label = tr("Balanced"), glyph = "scale", on = profile == "balanced", keep = true, run = set_profile("balanced", d) },
            { label = tr("Performance"), glyph = "rocket", on = profile == "performance", keep = true, run = set_profile("performance", d) },
        } }
    end
    rows[#rows + 1] = { label = tr("Settings"), glyph = "settings", line = true, keep = true, more = true, run = function() settings.open(d) end }
    rows[#rows + 1] = { line = true, pills = {
        { label = tr("Sleep"), glyph = "moon", run = leave("sleep", d) },
        { label = ask("restart", N("Restart")), glyph = "refresh", on = armed == "restart", keep = true, run = leave("restart", d) },
        { label = ask("off", N("Shut down")), glyph = "power", danger = true, on = armed == "off", keep = true, run = leave("off", d) },
    } }
    -- With the strip out it stays where it is, and the card grows from where the press was.
    card.open(rows, { owner = not strip.on and d or nil, id = "power", width = 330, keep = keep })
end

return {
    id = "powergoo", name = "PowerGoo", core = true, glyph = "power", nature = "calm", size = 19, seat = 3, lift = 1.8, swell = 0.21,
    beside = "lensgoo", gap = -62,
    about = function()
        local what = tr(strip.on and N("left: account and power · right: hide the strip") or N("left: account and power · right: performance strip"))
        if battery then return math.floor(battery.percent) .. " %" .. (battery.charging and (" · " .. tr("charging")) or "") .. " · " .. what end
        return what
    end,
    start = function(d)
        user = E.env("USER")
        on("strip_hover", function(u) local c = strip.cells[(u or 0) + 1] if c then d:tip(c.tip) end end)
        on("strip_close", function() strip_off(d) end)
        local ok, kept = pcall(sys.ask, "files.read", FILE, "json")
        if ok and type(kept) == "table" and kept.strip == true then after(1500, function() strip_on(d, true) end) end
        run("hostname", {}, function(out) host = (out or ""):match("%S+") or "" end)
        -- The login screen lets its own power drop fall to where this one is: it is told where that is.
        local function remember()
            run("latte-login", { "remember", tostring(d.edge == 0 and E.along(d) / E.len(d) or -1) }, nil, { output = false })
        end
        E.on_save(remember)
        after(3000, remember)
        read_profile()
        pcall(sys.watch, "battery", function(b)
            if type(b) ~= "table" or not b.present then battery = nil d:set_beads(0) d:set_core() d:fx("none") return end
            battery = { percent = tonumber(b.percent) or 0, charging = b.charging == true }
            local p = battery.percent
            if p >= 60 then d:set_beads(3, "network") elseif p >= 30 then d:set_beads(2, "yellow") else d:set_beads(1, "hardware") end
            if p < 10 and not battery.charging then d:set_core("hardware", 0.8, true) else d:set_core() end
            d:fx(battery.charging and "breath" or "none", 0.7)
        end)
    end,
    click = function(d)
        if card.id() == "power" then return card.close() end
        armed = nil
        read_profile(function() open_card(d, false) end)
    end,
    right = function(d) if strip.on then strip_off(d) else strip_on(d) end end,
    -- moved to another edge, or to where the capsule has no room on that side: it is shaped again
    placed = function(d) if strip.on then after(400, function() if strip.on then shape(d) end end) end end,
}
