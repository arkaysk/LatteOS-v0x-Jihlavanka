-- PowerGoo: the account, power and leaving. A small drop almost under the edge that rises the most of all.
-- A press opens its card: who is logged in, the battery and the power profile, and the ways out: log out,
-- sleep, restart, shut down. With windows open, one that does not undo asks once more first.
-- On a laptop it carries the battery as beads: three green from 60 %, two yellow from 30 %, one red below;
-- under 10 % its core pulses red, and while charging it breathes.
local card = require("lib/card")
local wm = require("lib/wm")
local bar = require("lib/bar")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local user, host, since = "", "", os.date("%H:%M")
local battery = nil
local profile, profiles = nil, false          -- the power profile in use; whether this machine has any
local armed = nil                             -- the way out that was asked about, for four seconds
local open_card

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
        { pills = { { label = ask("logout", N("Log out")), glyph = "logout", on = armed == "logout", keep = true, run = leave("logout", d) } } },
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
    rows[#rows + 1] = { line = true, pills = {
        { label = tr("Sleep"), glyph = "moon", run = leave("sleep", d) },
        { label = ask("restart", N("Restart")), glyph = "refresh", on = armed == "restart", keep = true, run = leave("restart", d) },
        { label = ask("off", N("Shut down")), glyph = "power", danger = true, on = armed == "off", keep = true, run = leave("off", d) },
    } }
    card.open(rows, { owner = d, id = "power", width = 330, keep = keep })
end

return {
    id = "powergoo", name = "PowerGoo", core = true, glyph = "power", nature = "calm", size = 19, seat = 3, lift = 1.8, swell = 0.21,
    beside = "lensgoo", gap = -62,
    about = function()
        if battery then return math.floor(battery.percent) .. " %" .. (battery.charging and (" · " .. tr("charging")) or "") end
        return tr("account, power, shut down")
    end,
    start = function(d)
        local E = require("lib/engine")
        user = E.env("USER")
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
}
