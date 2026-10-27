-- ClockGoo: the time, and where notifications gather. The drop shows the time and the date; beads count the
-- notifications that wait, dark red when one of them is critical, and a new one ripples the surface.
-- A press opens notifications and the calendar side by side, as the notification centre of Windows 11 does:
--   on the left what arrived (a press opens it, the right button offers its actions and to dismiss it),
--   Do not disturb and Clear all; on the right a month, and what is written down for the day chosen.
-- The right button opens the time card: an overview, a stopwatch, a timer, alarms and the weather. The timer
-- and the alarms ring whether the card is open or not, and a running timer or stopwatch takes the date's place
-- on the drop. pleamar itself receives the notifications: it is the session's notification server.
local E = require("lib/engine")
local card = require("lib/card")
local open = require("lib/open")
local timers = require("lib/timers")
local icons = require("lib/icons")
local ctx = require("lib/ctx")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local FILE = "clock.json"                    -- what the user wrote down: events and tasks; and Do not disturb
local SHOWN = 5                              -- notifications in the card; the rest is counted
local WEEKDAYS = { N("Sunday"), N("Monday"), N("Tuesday"), N("Wednesday"), N("Thursday"), N("Friday"), N("Saturday") }
local SHORT = { N("Su"), N("Mo"), N("Tu"), N("We"), N("Th"), N("Fr"), N("Sa") }
local MONTHS = { N("January"), N("February"), N("March"), N("April"), N("May"), N("June"), N("July"), N("August"),
                 N("September"), N("October"), N("November"), N("December") }

local notes, seen = {}, {}
local kept = { quiet = false, events = {}, tasks = {}, calendars = {} }
local linked = {}                            -- the events of the calendars kept elsewhere, as latte-cal read them
local date, sky = "", nil                    -- the date as the drop shows it; the weather, as latte-sky gave it
local busy_face = false                      -- a timer or the stopwatch has the date's place
local month = { y = nil, m = nil, chosen = nil, cells = {} }
local tab = 0
local open_notes, open_time, open_calendars
local open_calendar, read_events, fill_calendar     -- the calendar, the left button (below)

-- Calendars kept elsewhere (`kept.calendars`, their addresses) are read when the list changes and every half hour.
local function read_linked(then_do)
    if #kept.calendars == 0 then linked = {} if then_do then then_do() end return end
    run("latte-cal", kept.calendars, function(out)
        local ok, list = pcall(json.decode, out or "")
        if ok and type(list) == "table" then linked = list end
        if then_do then then_do() end
    end)
end

local function save() pcall(sys.call, "files.write", FILE, kept) end
-- Do not disturb, the note in the corner and its sound are the Goo's settings (settings.json): the Settings app sets them too
local function quiet() return E.settings().quiet == true end
local function second_line()
    if quiet() then return tr("Do not disturb") end
    return date .. ((sky and sky.now) and ("  " .. tostring(sky.now.temp) .. "°") or "")
end
local function show_face(d) if not busy_face then d:set({ line2 = second_line() }) end end
local function show_beads(d)
    local critical = false
    for _, n in ipairs(notes) do if (n.urgency or 1) >= 2 then critical = true end end
    d:set_beads(#notes, critical and "system" or "yellow")
end
local function iso(t) return string.format("%04d-%02d-%02d", t.year, t.month, t.day) end

-- ── notifications and the calendar (the left button) ─────────────────────────────────────────────────────────
local function note_rows(d)
    local rows = { { head = true, label = tr("NOTIFICATIONS"), hint = #notes > 0 and tostring(#notes) or "" } }
    if #notes == 0 then
        rows[#rows + 1] = { glyph = "bell-off", label = tr("No notifications"), line2 = tr("New ones appear here and ripple the edge"), quiet = true }
    end
    for i, n in ipairs(notes) do                 -- the service lists the newest first
        if i > SHOWN then
            rows[#rows + 1] = { glyph = "dots", label = "+" .. (#notes - SHOWN) .. " " .. tr("more"), quiet = true }
            break
        end
        local critical = (n.urgency or 1) >= 2
        local from = ((n.app or "") ~= "" and (n.title or "") ~= "") and (n.app .. " · ") or ""
        local actions = type(n.actions) == "table" and n.actions or {}
        rows[#rows + 1] = {
            icon = (n.icon or "") ~= "" and n.icon or nil, glyph = critical and "alert-triangle" or "bell", danger = critical,
            label = (n.title or "") ~= "" and n.title or (n.app or ""), line2 = from .. tostring(n.body or ""):gsub("%s+", " "),
            run = function()
                pcall(sys.call, "notifications.invoke", n.id, "default")
                pcall(sys.call, "notifications.dismiss", n.id)
            end,
            right = function()
                local sub = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_notes(d) end } }
                for _, a in ipairs(actions) do
                    sub[#sub + 1] = { label = a.label or a.key or "", glyph = "chevron-right", line = #sub == 1, run = function()
                        pcall(sys.call, "notifications.invoke", n.id, a.key)
                        pcall(sys.call, "notifications.dismiss", n.id)
                    end }
                end
                sub[#sub + 1] = { label = tr("Dismiss"), glyph = "x", line = true, run = function() pcall(sys.call, "notifications.dismiss", n.id) end }
                card.open(sub, { owner = d, width = 300 })
            end,
        }
    end
    local pills = { { glyph = quiet() and "bell-off" or "bell", label = tr("Do not disturb"), on = quiet(), keep = true, run = function()
        E.set("quiet", not quiet())
        show_face(d)
        open_notes(d, true)
    end } }
    if #notes > 0 then
        pills[2] = { glyph = "trash", label = tr("Clear all"), danger = true, keep = true, run = function() pcall(sys.call, "notifications.clear") end }
    end
    rows[#rows + 1] = { line = true, pills = pills }
    return rows
end

-- the month shown, six weeks from Monday
local function month_of(d)
    local now = os.date("*t")
    month.y, month.m, month.chosen = month.y or now.year, month.m or now.month, month.chosen or iso(now)
    local today = iso(now)
    local first = os.date("*t", os.time({ year = month.y, month = month.m, day = 1, hour = 12 }))
    local lead = (first.wday + 5) % 7            -- Monday is 0
    local marked = {}
    for _, e in ipairs(kept.events) do if e.date then marked[e.date] = true end end
    for _, e in ipairs(linked) do if e.date then marked[e.date] = true end end
    local days, names = {}, {}
    month.cells = {}
    for i = 0, 41 do
        local t = os.date("*t", os.time({ year = month.y, month = month.m, day = 1 - lead + i, hour = 12 }))
        local key = iso(t)
        month.cells[i + 1] = key
        days[i + 1] = { n = tostring(t.day), dim = t.month ~= month.m, today = key == today, chosen = key == month.chosen and key ~= today, dot = marked[key] == true }
    end
    for i = 1, 7 do names[i] = tr(SHORT[i % 7 + 1]) end
    return {
        title = tr(MONTHS[month.m]) .. " " .. month.y, weekdays = names, days = days,
        pick = function(place)
            local key = month.cells[place + 1]
            if not key then return end
            month.chosen = key
            month.y, month.m = tonumber(key:sub(1, 4)), tonumber(key:sub(6, 7))
            open_notes(d, true)
        end,
        step = function(dir)
            month.m += dir
            if month.m < 1 then month.m, month.y = 12, month.y - 1 elseif month.m > 12 then month.m, month.y = 1, month.y + 1 end
            open_notes(d, true)
        end,
    }
end

-- what is written down for the chosen day: "10:30 Meeting" has a time, "Meeting" takes the whole day, "! milk" is a task
local function write_down(text)
    if text:sub(1, 1) == "!" then
        local title = text:sub(2):gsub("^%s+", "")
        if title ~= "" then kept.tasks[#kept.tasks + 1] = { title = title, done = false, date = month.chosen } end
    else
        local h, m, title = text:match("^(%d%d?):(%d%d)%s+(.+)$")
        if h and tonumber(h) < 24 and tonumber(m) < 60 then
            kept.events[#kept.events + 1] = { date = month.chosen, time = string.format("%02d:%02d", tonumber(h), tonumber(m)), title = title }
        else
            kept.events[#kept.events + 1] = { date = month.chosen, time = "", title = text }
        end
        table.sort(kept.events, function(a, b) return ((a.date or "") .. (a.time or "")) < ((b.date or "") .. (b.time or "")) end)
    end
    save()
end
local function day_rows(d)
    local now = os.date("*t")
    local y, m, day = month.chosen:match("(%d+)-(%d+)-(%d+)")
    local t = os.date("*t", os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(day), hour = 12 }))
    local rows = { { col = 2, glyph = "calendar", quiet = true,
                     label = (month.chosen == iso(now) and (tr("Today") .. " · ") or "") .. tr(WEEKDAYS[t.wday]) .. " " .. tonumber(day) .. ". " .. tonumber(m) .. "." } }
    local shown = 0
    for i, e in ipairs(kept.events) do
        if e.date == month.chosen then
            shown += 1
            if shown > 3 then break end
            rows[#rows + 1] = { col = 2, glyph = "calendar-event", label = ((e.time or "") ~= "" and e.time or tr("All day")) .. "  " .. (e.title or ""),
                                sub = { { danger = true, glyph = "trash", label = tr("Delete event"), run = function()
                                    table.remove(kept.events, i)
                                    save()
                                    after(60, function() open_notes(d) end)
                                end } } }
        end
    end
    for _, e in ipairs(linked) do                -- from a calendar kept elsewhere: shown, changed there
        if e.date == month.chosen and shown < 3 then
            shown += 1
            rows[#rows + 1] = { col = 2, glyph = "world", label = ((e.time or "") ~= "" and e.time or tr("All day")) .. "  " .. (e.title or ""), quiet = true }
        end
    end
    local tasks = 0
    for pass = 1, 2 do                           -- what is still to do first, then what is done
        for _, task in ipairs(kept.tasks) do
            if tasks < 2 and ((task.date or "") == "" or task.date == month.chosen) and (task.done == true) == (pass == 2) then
                tasks += 1
                rows[#rows + 1] = { col = 2, keep = true, glyph = "square-rounded", on = task.done == true, label = task.title or "",
                                    run = function() task.done = not task.done save() open_notes(d, true) end }
            end
        end
    end
    rows[#rows + 1] = { col = 2, glyph = "plus", label = tr("New event…"), keep = true, run = function()
        card.open({ { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_notes(d) end },
                    { label = tr("10:30 Meeting · Meeting · ! task"), glyph = "calendar-event", quiet = true, line = true } },
                  { owner = d, width = 340, field = { hint = tr("New event…"), submit = function(text) write_down(text) open_notes(d) return false end } })
    end }
    rows[#rows + 1] = { col = 2, glyph = "world", label = tr("Linked calendars"), hint = #kept.calendars > 0 and tostring(#kept.calendars) or "", keep = true,
                        run = function() open_calendars(d) end }
    return rows
end
-- the calendars kept elsewhere: their addresses, one more, one less
open_calendars = function(d)
    local rows = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_calendar(d) end },
                   { para = true, label = tr("The address of a calendar in iCal form (.ics): Google Calendar, iCloud and others give one in the calendar's settings."), line = true } }
    for i, address in ipairs(kept.calendars) do
        rows[#rows + 1] = { glyph = "world", label = address:gsub("^%a+://", ""), keep = true,
                            sub = { { danger = true, glyph = "trash", label = tr("Remove calendar"), run = function()
                                table.remove(kept.calendars, i)
                                save()
                                read_linked()
                                after(60, function() open_calendars(d) end)
                            end } } }
    end
    card.open(rows, { owner = d, width = 380, field = { hint = tr("Address of a calendar…"), submit = function(text)
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text ~= "" and #kept.calendars < 6 and not table.find(kept.calendars, text) then
            kept.calendars[#kept.calendars + 1] = text
            save()
            read_events(function() if card.id() == "notes" then fill_calendar() end end)
        end
        open_notes(d)
        return false
    end } })
end
open_notes = function(d, keep)
    local rows = note_rows(d)
    local cal = month_of(d)
    for _, r in ipairs(day_rows(d)) do rows[#rows + 1] = r end
    card.open(rows, { owner = d, id = "notes", width = 300, width2 = 320, calendar = cal, keep = keep })
end

-- ── the time card (the right button) ─────────────────────────────────────────────────────────────────────────
-- an icon for a weather code of the WMO
local function sky_glyph(code)
    code = tonumber(code) or 3
    if code == 0 then return "sun" end
    if code <= 2 then return "sun-low" end
    if code == 45 or code == 48 then return "cloud-fog" end
    if code >= 95 then return "cloud-storm" end
    if (code >= 71 and code <= 77) or code == 85 or code == 86 then return "cloud-snow" end
    if (code >= 51 and code <= 67) or (code >= 80 and code <= 82) then return "cloud-rain" end
    return "cloud"
end
-- ── the card, as the reference drew it: the scene (parts/clock.plm) is told the texts and the numbers ─────────────
-- the world clocks: the first is home. zones.json in the scene's folder holds the user's own list (the card's Change layout writes it)
-- until the user chooses (Settings › Drops › Clock and weather), these; the names are translated where they are shown
local DEFAULT_ZONES = {
    { zone = "Europe/Bratislava", name = N("Bratislava"), country = N("Slovakia") }, { zone = "Europe/London", name = N("London"), country = N("United Kingdom") },
    { zone = "Asia/Tokyo", name = N("Tokyo"), country = N("Japan") }, { zone = "America/New_York", name = N("New York"), country = N("USA (East)") },
    { zone = "America/Los_Angeles", name = N("San Francisco"), country = N("USA (West)") },
}
local world, world_at = {}, 0
local function zones()
    local ok, saved = pcall(sys.ask, "files.read", "zones.json", "json")
    if ok and type(saved) == "table" and #saved > 0 then return saved end
    return DEFAULT_ZONES
end
-- asks the system what time it is in each (date knows the zones), at most every half minute
local function learn_world()
    if os.clock() - world_at < 30 and #world > 0 then return end
    world_at = os.clock()
    local list, command = zones(), {}
    for i, z in ipairs(list) do
        if i > 6 then break end
        if type(z.zone) == "string" and z.zone:match("^[%w_/%-%+]+$") then command[#command + 1] = "TZ=" .. z.zone .. " date '+%H:%M %z %Z'" end
    end
    if #command == 0 then return end
    run("sh", { "-c", table.concat(command, "; ") }, function(out)
        local here, lines = tonumber(os.date("%z")) or 0, {}
        for time, sign, hh, mm, abbr in (out or ""):gmatch("(%d%d:%d%d) ([%+%-])(%d%d)(%d%d) (%S+)") do
            local diff = (tonumber(hh) + tonumber(mm) / 60) * (sign == "-" and -1 or 1) - math.floor(here / 100) - (here % 100) / 60
            lines[#lines + 1] = { time = time, diff = diff, abbr = abbr }
        end
        world = {}
        for i, line in ipairs(lines) do
            local z = list[i]
            if z then world[#world + 1] = { name = z.name or z.zone, country = z.country or "", time = line.time, diff = line.diff, abbr = line.abbr, home = i == 1 } end
        end
    end)
end

local SKY_NAMES = { [0] = N("Clear sky"), N("Mostly clear"), N("Partly cloudy"), N("Overcast") }
local function sky_name(code)
    code = tonumber(code) or 3
    if SKY_NAMES[code] then return tr(SKY_NAMES[code]) end
    if code == 45 or code == 48 then return tr("Fog") end
    if code >= 95 then return tr("Thunderstorm") end
    if (code >= 71 and code <= 77) or code == 85 or code == 86 then return tr("Snow") end
    if code >= 80 and code <= 82 then return tr("Showers") end
    if code >= 61 and code <= 67 then return tr("Rain") end
    if code >= 51 and code <= 57 then return tr("Drizzle") end
    return tr("Overcast")
end
local AQI = { N("Excellent"), N("Good"), N("Moderate"), N("Poor"), N("Very poor"), N("Extremely poor") }
local function aqi_level(v) return v <= 25 and 0 or (v <= 50 and 1 or (v <= 75 and 2 or (v <= 100 and 3 or (v <= 150 and 4 or 5)))) end
-- the long names of the time zones a user is likely to be in (the abbreviation and the offset come from the system)
local ZONE_NAMES = { CET = N("CENTRAL EUROPEAN TIME"), CEST = N("CENTRAL EUROPEAN SUMMER TIME"), GMT = N("GREENWICH MEAN TIME"), BST = N("BRITISH SUMMER TIME"),
                     UTC = N("COORDINATED UNIVERSAL TIME"), EET = N("EASTERN EUROPEAN TIME"), EEST = N("EASTERN EUROPEAN SUMMER TIME"), WET = N("WESTERN EUROPEAN TIME"),
                     EST = N("EASTERN STANDARD TIME"), EDT = N("EASTERN DAYLIGHT TIME"), PST = N("PACIFIC STANDARD TIME"), PDT = N("PACIFIC DAYLIGHT TIME") }

local focus = { total = 0, apps = {}, yesterday = 0, streak = 0, goal = 6, bedtime = "23:00", log = true }
local nameday = { today = "", tomorrow = "" }
local here_abbr = ""
local function learn_focus()
    run("latte-focus", { "today" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then focus = t end
    end)
end
local function learn_nameday()
    run("latte-nameday", {}, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then nameday = t end
    end)
end
local function learn_abbr()
    run("date", { "+%Z" }, function(out) here_abbr = (out or ""):match("%S+") or "" end)
end
local function hours(sec)
    sec = math.floor(tonumber(sec) or 0)
    return (sec >= 3600 and (sec // 3600 .. "h ") or "") .. (sec % 3600) // 60 .. "m"
end
local function minutes_of(hhmm)
    local h, m = tostring(hhmm or ""):match("^(%d+):(%d+)$")
    return h and (tonumber(h) * 60 + tonumber(m)) or nil
end
-- the app's name as the launcher knows it, from the class of its window
local function app_name(class, apps)
    for _, a in ipairs(apps or {}) do
        if a.wmclass and a.wmclass:lower() == tostring(class):lower() then return a.local_name or a.name or class end
    end
    return class
end
-- capitals for the letters of the languages of the desktop (string.upper knows only ASCII)
local UP = {}
for lower, capital in pairs({ [0xE1] = 0xC1, [0xE4] = 0xC4, [0x10D] = 0x10C, [0x10F] = 0x10E, [0xE9] = 0xC9, [0x11B] = 0x11A, [0xED] = 0xCD, [0x13A] = 0x139, [0x13E] = 0x13D,
                              [0x148] = 0x147, [0xF3] = 0xD3, [0xF4] = 0xD4, [0xF6] = 0xD6, [0x155] = 0x154, [0x159] = 0x158, [0x161] = 0x160, [0x165] = 0x164, [0xFA] = 0xDA,
                              [0x16F] = 0x16E, [0xFC] = 0xDC, [0xFD] = 0xDD, [0x17E] = 0x17D }) do UP[utf8.char(lower)] = utf8.char(capital) end
local function upper(s) return (s:gsub(utf8.charpattern, function(c) return UP[c] or c:upper() end)) end
local fill_apps = {}
local links = nil                            -- the region's own weather services, and some for anywhere
local forecasts = nil                       -- the days ahead from several weather services (latte-sky sources)                          -- the apps the launcher lists (LensGoo keeps them; ClockGoo asks the same service)

-- everything the scene shows, once a second while the card is open
local function fill_clock()
    local t = os.date("*t")
    local week = (t.yday - ((t.wday + 5) % 7 + 1) + 10) // 7
    if week < 1 then week = 52 end
    text.clk_tab0, text.clk_tab1, text.clk_tab2 = tr("Overview"), tr("Timers and alarms"), tr("Weather in detail")
    text.ic_world, text.ic_sun, text.ic_moon, text.ic_arrow, text.ic_drop = icons["world"], icons["sun"], icons["moon"], icons["arrow-right"], icons["droplet"]
    text.ic_leaf, text.ic_bulb, text.ic_grid, text.ic_bell = icons["leaf"], icons["bulb"], icons["layout-grid"], icons["bell-off"]
    text.ic_dash, text.ic_alarm, text.ic_cloud = icons["layout-dashboard"], icons["alarm"], icons["cloud"]
    -- the time
    local off = tonumber(os.date("%z")) or 0
    local utc = string.format("UTC%s%d", off < 0 and "-" or "+", math.abs(off) // 100)
    text.clk_zone = (ZONE_NAMES[here_abbr] and tr(ZONE_NAMES[here_abbr]) or here_abbr) .. " (" .. tr(here_abbr) .. " / " .. utc .. ")"
    text.clk_hm, text.clk_s, text.clk_ampm = os.date("%H:%M"), ":" .. os.date("%S"), tr(t.hour < 12 and "AM" or "PM")
    text.clk_date = tr(WEEKDAYS[t.wday]) .. ", " .. t.day .. ". " .. tr(MONTHS[t.month]) .. " " .. t.year
    text.clk_week = week .. ". " .. tr("calendar week")
    fact.clk_names = nameday.today ~= "" and 1 or 0
    text.clk_name1 = tr("Name day today:") .. " " .. nameday.today
    text.clk_name2 = tr("Tomorrow:") .. " " .. nameday.tomorrow
    -- the weather
    local now = sky and sky.now
    fact.clk_weather = now and 1 or 0
    if now then
        local days = type(sky.days) == "table" and sky.days or {}
        text.clk_place = upper((sky.place or "") ~= "" and (sky.place .. " · ") or "") .. tr("NOW")
        text.clk_temp = tostring(now.temp)
        fact.clk_kind = tonumber(now.kind) or 3
        fact.clk_night = (type(sky.sun) == "table" and (tonumber(sky.sun.t) or 0) < 0) and 1 or 0
        text.clk_sky = sky_name(now.code)
        text.clk_g_sky = icons[sky_glyph(now.code)] or icons["cloud"]
        if days[1] then text.clk_minmax = tr("Min") .. " " .. days[1].min .. "° / " .. tr("Max") .. " " .. days[1].max .. "°" end
        text.clk_feels = tr("Feels like:") .. " " .. tostring(now.feels or now.temp) .. "°C"
        text.clk_rain = (days[1] and days[1].rain or 0) .. "% " .. tr("rain")
        local aqi = sky.aqi
        fact.clk_aqi_on = type(aqi) == "table" and 1 or 0
        if type(aqi) == "table" then
            local lv = aqi_level(tonumber(aqi.value) or 0)
            fact.clk_aqi_lv = lv
            text.clk_aqi = "AQI " .. aqi.value .. " · " .. tr(AQI[lv + 1])
        end
        local d2, d3 = days[2], days[3]
        if d2 then text.clk_t1l, text.clk_t1, text.clk_g_t1 = tr("Tomorrow"), d2.max .. "°C · " .. sky_name(d2.code), icons[sky_glyph(d2.code)] or icons["cloud"] end
        if d3 then text.clk_t2l, text.clk_t2, text.clk_g_t2 = tr(WEEKDAYS[((tonumber(d3.weekday) or 0) + 1) % 7 + 1]), d3.max .. "°C · " .. sky_name(d3.code), icons[sky_glyph(d3.code)] or icons["cloud"] end
        -- the daylight: from the sunrise to the sunset
        local rise, set = minutes_of(sky.sunrise), minutes_of(sky.sunset)
        if rise and set then
            local minute = t.hour * 60 + t.min
            text.clk_rise, text.clk_set = tr("Sunrise") .. " " .. sky.sunrise, tr("Sunset") .. " " .. sky.sunset
            fact.clk_day = math.max(0, math.min(1, (minute - rise) / math.max(1, set - rise)))
            if minute >= rise and minute < set then
                text.clk_light = string.format(tr("%dh %dm of light left"), (set - minute) // 60, (set - minute) % 60)
            else
                text.clk_light = tr("The sun is below the horizon")
            end
        end
    end
    -- the world
    text.clk_w_title = tr("World clocks & Metropolises")
    local list = {}
    for _, w in ipairs(world) do
        local hour = tonumber(w.time:match("^(%d+)")) or 12
        local diff = w.home and "+0h" or string.format("%+gh", w.diff)
        list[#list + 1] = { name = tr(w.name), time = w.time, home = w.home, night = hour < 6 or hour >= 20,
                            note = w.home and tr("Home") or tr(w.country), tag = diff .. " " .. (w.home and tr(here_abbr) or tr(w.abbr)) }
    end
    model.clkw = list
    -- the screen time
    text.clk_wb_head = tr("Digital wellbeing")
    fact.clk_wb_on = focus.log and 1 or 0
    if focus.log then
        local total = tonumber(focus.total) or 0
        local top, shares = nil, {}
        for name, secs in pairs(focus.apps or {}) do shares[#shares + 1] = { class = name, secs = secs } end
        table.sort(shares, function(x, y) return x.secs > y.secs end)
        local rows = {}
        for i = 1, math.min(3, #shares) do
            local x = shares[i]
            rows[i] = { name = app_name(x.class, fill_apps), time = hours(x.secs) .. " (" .. math.floor(100 * x.secs / math.max(total, 1) + 0.5) .. "%)", pct = x.secs / math.max(total, 1) }
        end
        model.clka = rows
        text.clk_wb_sub = tr("Today") .. " " .. hours(total) .. (rows[1] and (" · " .. tr("Most active time in:") .. " " .. rows[1].name) or (" · " .. tr("nothing counted yet")))
        local yesterday = tonumber(focus.yesterday) or 0
        fact.clk_wb_delta_on = yesterday > 0 and 1 or 0
        if yesterday > 0 then
            local pct = math.floor(100 * (total - yesterday) / yesterday + 0.5)
            fact.clk_wb_good = pct <= 0 and 1 or 0
            text.clk_wb_delta = string.format(tr("%+d%% in front of the screen against yesterday"), pct)
        end
        local rest = 60 - (tonumber(focus.streak) or 0)
        text.clk_wb_tip = tr("LatteOS recommends:") .. " " .. (rest > 0 and string.format(tr("a break from the screen in %d minutes."), rest) or tr("a break from the screen now."))
        text.clk_wb_goal = string.format(tr("Goal: under %dh a day"), tonumber(focus.goal) or 6)
    else
        text.clk_wb_off = tr("Screen time is not being kept. Switch it on in Change layout; it stays on this computer.")
        fact.clk_wb_delta_on = 0
        model.clka = {}
    end
    -- the foot
    text.clk_bed = string.format(tr("Sleep mode planned for %s"), tostring(focus.bedtime or "23:00"))
    text.clk_btn_layout, text.clk_btn_dnd = tr("Change layout"), tr("Do not disturb mode")
    fact.clk_dnd_on = quiet() and 1 or 0
end

local function open_clock(d, keep)
    learn_world()
    learn_focus()
    learn_nameday()
    learn_abbr()
    -- the card's own frame, glass and coffee; the 592 × 550 of the picture, and the coffee begins where the foot does
    card.open({}, { owner = d, id = "time", custom = "clock", width = 592, min_height = 660, split = 606, pane = 1, grow = true, keep = keep })
    fill_clock()
end
-- ── the timers' page and the weather in detail: the same scene, told other texts ─────────────────────────────
local PRESETS = { 1, 5, 10, 15, 25, 45 }      -- ready lengths of the timer, in minutes
local function fill_timers()
    text.clk_t_watch, text.clk_t_timer, text.clk_t_alarms, text.clk_t_new = tr("STOPWATCH"), tr("TIMER"), tr("ALARMS"), tr("NEW ALARM")
    text.ic_watch, text.ic_hourglass, text.ic_play, text.ic_flag, text.ic_reset = icons["stopwatch"], icons["hourglass"], icons["player-play"], icons["flag"], icons["refresh"]
    text.ic_minus, text.ic_plus, text.ic_x, text.ic_trash, text.ic_alarmplus = icons["minus"], icons["plus"], icons["x"], icons["trash"], icons["alarm-plus"]
    local w = timers.all().watch
    text.clk_sw = timers.clock(timers.elapsed(), true)
    fact.clk_sw_run = w.running and 1 or 0
    text.clk_sw_btn, text.clk_lap_btn, text.clk_reset_btn = tr(w.running and N("Stop") or N("Start")), tr("Lap"), tr("Reset")
    local laps = {}
    for i, lap in ipairs(w.laps or {}) do
        if i > 3 then break end
        laps[i] = { name = tr("Lap") .. " " .. (#w.laps - i + 1), time = timers.clock(lap, true) }
    end
    model.clklap = laps
    local running, started, left, length = timers.timer()
    fact.clk_tm_run, fact.clk_tm_started = running and 1 or 0, started and 1 or 0
    text.clk_tm = timers.clock(started and (left + (running and 999 or 0)) or length)
    fact.clk_tm_frac = started and left / math.max(length, 1) or 1
    text.clk_tm_btn = tr(running and N("Pause") or (started and N("Resume") or N("Start")))
    text.clk_tm_cancel = tr("Cancel")
    text.clk_tm_len = math.floor(length / 60000 + 0.5) .. " min"
    local pre = {}
    for i, m in ipairs(PRESETS) do pre[i] = { label = m .. " min" } end
    model.clkpre = pre
    local list, off = {}, 0
    for i, a in ipairs(timers.all().alarms) do
        if i > 6 then break end
        if not a.on then off += 1 end
        list[#list + 1] = { time = a.time or "", on = a.on == true, state = tr(a.on and N("on") or N("off")) }
    end
    model.clkal = list
    fact.clk_al_count, fact.clk_al_off = #list, off
    text.clk_al_none = tr("No alarms")
    text.clk_al_h, text.clk_al_m = string.format("%02d", timers.hour), string.format("%02d", timers.minute)
    text.clk_al_add, text.clk_al_prune = tr("Add alarm"), tr("Remove alarms that are off")
end
local function fill_weather()
    text.ic_sunrise, text.ic_temp, text.ic_wind, text.ic_umbrella, text.ic_gauge, text.ic_clock = icons["sunrise"], icons["temperature"], icons["wind"], icons["umbrella"], icons["gauge"], icons["clock"]
    text.clk_d_sun, text.clk_d_hours, text.clk_d_days = tr("THE SUN"), tr("THE NEXT HOURS"), tr("THE DAYS AHEAD")
    text.clk_d_feelsl, text.clk_d_huml, text.clk_d_windl = tr("Feels like"), tr("Humidity"), tr("Wind")
    text.clk_d_rainl, text.clk_d_aqil, text.clk_d_lenl = tr("Rain today"), tr("Air"), tr("Daylight")
    local now = sky and sky.now
    if not now then return end
    local days = type(sky.days) == "table" and sky.days or {}
    text.clk_d_head = upper((sky.place or "") ~= "" and (sky.place .. " · ") or "") .. tr("NOW")
    text.clk_d_feels = tostring(now.feels or now.temp) .. " °C"
    text.clk_d_hum = tostring(now.humidity or "—") .. " %"
    text.clk_d_wind = tostring(sky.wind or 0) .. " km/h"
    text.clk_d_rain = (days[1] and days[1].rain or 0) .. " %"
    text.clk_d_aqi = type(sky.aqi) == "table" and (sky.aqi.value .. " · " .. tr(AQI[aqi_level(tonumber(sky.aqi.value) or 0) + 1])) or "—"
    local rise, set = minutes_of(sky.sunrise), minutes_of(sky.sunset)
    text.clk_d_len = (rise and set) and string.format("%dh %dm", (set - rise) // 60, (set - rise) % 60) or "—"
    local hours = {}
    for i, h in ipairs(type(sky.hours) == "table" and sky.hours or {}) do
        if i > 8 then break end
        hours[i] = { time = h.time or "", temp = tostring(h.temp) .. "°", glyph = icons[sky_glyph(h.code)] or icons["cloud"] }
    end
    model.clkh = hours
    -- the days ahead, as each weather service sees them
    text.clk_d_days = tr("THE DAYS AHEAD, FORECAST BY:")
    text.clk_d_more = tr("More forecasts") .. " ›"
    local list = type(forecasts) == "table" and forecasts or {}
    local heads = {}
    for j, f in ipairs(list) do if j <= 5 then heads[j] = { name = f.name or "", by = f.by or "" } end end
    model.clksrc = heads
    local rows = {}
    local first = list[1] and list[1].days or {}
    for i = 1, math.min(7, #first) do
        local x = first[i]
        local row = { day = i == 1 and tr("Today") or (i == 2 and tr("Tomorrow") or tr(WEEKDAYS[((tonumber(x.weekday) or 0) + 1) % 7 + 1])) }
        local hi, lo = -999, 999
        for j = 1, math.min(5, #list) do
            local y = list[j].days and list[j].days[i]
            if y then
                row["g" .. j], row["t" .. j] = icons[sky_glyph(y.code)] or icons["cloud"], y.max .. "° / " .. y.min .. "°"
                row["r" .. j] = (tonumber(y.rain) or 0) > 0 and (tostring(y.rain) .. " mm") or ""
                hi, lo = math.max(hi, y.max), math.min(lo, y.max)
            end
        end
        -- how far apart they are: where they differ much, the forecast is unsure
        row.spread = hi - lo >= 2 and string.format(tr("they differ by %d°"), hi - lo) or tr("they agree")
        rows[i] = row
    end
    model.clkdd = rows
end
-- the buttons of the timers' page, by their numbers in parts/clock.plm
local function act(n)
    if n == 1 then timers.watch_toggle() elseif n == 2 then timers.watch_lap() elseif n == 3 then timers.watch_reset()
    elseif n == 4 then timers.timer_toggle() elseif n == 5 then timers.timer_cancel()
    elseif n == 6 then timers.timer_adjust(1) elseif n == 7 then timers.timer_adjust(-1)
    elseif n >= 10 and n < 10 + #PRESETS then timers.timer_start(PRESETS[n - 9])
    elseif n >= 20 and n < 30 then timers.alarm_toggle(n - 19)
    elseif n == 30 then timers.hour = (timers.hour + 1) % 24 elseif n == 31 then timers.hour = (timers.hour - 1) % 24
    elseif n == 32 then timers.minute = (timers.minute + 5) % 60 elseif n == 33 then timers.minute = (timers.minute - 5) % 60
    elseif n == 34 then timers.alarm_add() elseif n == 35 then timers.alarm_prune() end
    fill_timers()
end

local ticking
local last_fill = 0
open_time = function(d, keep)
    -- the overview and the weather are told the time once a second, the timers' page five times (the stopwatch's tenths)
    if not ticking then
        ticking = every(200, function()
            if card.id() ~= "time" then cancel(ticking) ticking = nil return end
            if tab == 1 or os.time() ~= last_fill then
                last_fill = os.time()
                fill_clock()
                if tab == 1 then fill_timers() elseif tab == 2 then fill_weather() end
            end
        end)
    end
    fact.clk_page = tab
    if tab == 2 then
        run("latte-sky", { "sources" }, function(out)
            local ok, t = pcall(json.decode, out or "")
            if ok and type(t) == "table" then forecasts, links = t.sources, t.links fill_weather() end
        end)
    end
    open_clock(d, keep)
    if tab == 1 then fill_timers() elseif tab == 2 then fill_weather() end
end

local function read_sky(then_do)
    run("latte-sky", {}, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then sky = t end
        if then_do then then_do() end
    end)
end
-- the timer has run out, or an alarm's minute has come: a notification, and three notes
local function ring(title, text)
    run("notify-send", { "-a", "LatteOS", "-u", "critical", "-i", "alarm", title, text }, nil, { output = false })
    for i = 0, 2 do after(i * 420, function() pcall(sound.tone, { wave = "sine", freq = 880, to = 660, ms = 260, release = 180, volume = 0.6 }) end) end
end

-- ── the calendar, the left button (parts/calendar.plm; the design approved 21. 10.) ────────────────────────────
-- Every account's events come from latte-cal (Evolution Data Server keeps them: Google, Microsoft 365, iCloud…), with the
-- addresses kept here and the holidays of the weather's place; the name days are the place's too (latte-nameday).
local cal = { events = {}, side = 0, parsed = nil, snoozed = {}, asked = 0 }
local function rgb_of(hex)
    local r, g, b = tostring(hex or ""):match("^#(%x%x)(%x%x)(%x%x)")
    if not r then return 0.97, 0.78, 0.45 end
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end
read_events = function(then_do)
    local args = { "events" }
    for _, a in ipairs(kept.calendars) do args[#args + 1] = a end
    run("latte-cal", args, function(out)
        local ok, list = pcall(json.decode, out or "")
        if ok and type(list) == "table" then cal.events = list end
        if then_do then then_do() end
    end)
end
-- what a day holds: the events of the accounts and the ones written here before (kept.events), the time ones in order
local function events_on(key)
    local out = {}
    for _, e in ipairs(cal.events) do if e.date == key then out[#out + 1] = e end end
    for _, e in ipairs(kept.events) do
        if e.date == key then out[#out + 1] = { date = e.date, time = e.time or "", end_ = "", title = e.title, color = "#f7c873", kind = "event", calendar = "LatteOS" } end
    end
    table.sort(out, function(a, b) return ((a.kind == "holiday" and "0" or "1") .. (a.time or "")) < ((b.kind == "holiday" and "0" or "1") .. (b.time or "")) end)
    return out
end
local function mins(hhmm) local h, m = tostring(hhmm or ""):match("^(%d+):(%d+)$") return h and tonumber(h) * 60 + tonumber(m) or nil end
local function hhmm(n) return string.format("%02d:%02d", n // 60, n % 60) end
-- the next thing today or tomorrow, not yet begun and not put off
local function next_event()
    local now = os.date("*t")
    local today, minute = iso(now), now.hour * 60 + now.min
    local tomorrow = iso(os.date("*t", os.time() + 86400))
    for _, key in ipairs({ today, tomorrow }) do
        for _, e in ipairs(events_on(key)) do
            local m = mins(e.time)
            local id = key .. (e.time or "") .. (e.title or "")
            if e.kind ~= "holiday" and m and (key ~= today or m >= minute) and not (cal.snoozed[id] and cal.snoozed[id] > os.time()) then
                return e, (key == today and m - minute or 24 * 60 - minute + m), id
            end
        end
    end
end
fill_calendar = function()
    local now = os.date("*t")
    month.y, month.m, month.chosen = month.y or now.year, month.m or now.month, month.chosen or iso(now)
    local today = iso(now)
    local first = os.date("*t", os.time({ year = month.y, month = month.m, day = 1, hour = 12 }))
    local lead = (first.wday + 5) % 7
    -- the weather of the coming days, by date (latte-sky's days start today)
    local temps = {}
    for i, w in ipairs(type(sky) == "table" and type(sky.days) == "table" and sky.days or {}) do
        temps[iso(os.date("*t", os.time() + (i - 1) * 86400))] = tostring(math.floor((tonumber(w.max) or 0) + 0.5)) .. "°"
    end
    local cells, names = {}, {}
    month.cells = {}
    -- only the weeks of this month, and in them only its own days: the days of the months beside it are left empty
    local length = os.date("*t", os.time({ year = month.y, month = month.m + 1, day = 0, hour = 12 })).day
    local rows = math.ceil((lead + length) / 7)
    fact.cal_rows = rows
    for i = 0, rows * 7 - 1 do
        local t = os.date("*t", os.time({ year = month.y, month = month.m, day = 1 - lead + i, hour = 12 }))
        local key = iso(t)
        if t.month ~= month.m then
            cells[i + 1] = { n = "", dim = true, today = false, chosen = false, weekend = false, temp = "", hol = false, has1 = false, has2 = false,
                             t1 = "", t2 = "", more = "", r1 = 0, g1 = 0, b1 = 0, r2 = 0, g2 = 0, b2 = 0 }
            continue
        end
        month.cells[i + 1] = key
        local list, shown = events_on(key), {}
        local hol = false
        for _, e in ipairs(list) do if e.kind == "holiday" then hol = true end shown[#shown + 1] = e end
        local c = { n = tostring(t.day), dim = t.month ~= month.m, today = key == today, chosen = key == month.chosen and key ~= today,
                    weekend = i % 7 >= 5, temp = temps[key] or "", hol = hol, has1 = false, has2 = false, t1 = "", t2 = "", more = "",
                    r1 = 0, g1 = 0, b1 = 0, r2 = 0, g2 = 0, b2 = 0 }
        for k = 1, math.min(2, #shown) do
            local e = shown[k]
            c["has" .. k], c["t" .. k] = true, ((e.time or "") ~= "" and (e.time .. " ") or "") .. (e.title or "")
            c["r" .. k], c["g" .. k], c["b" .. k] = rgb_of(e.color)
        end
        if #shown > 2 then c.more = "+" .. (#shown - 2) .. " " .. tr("more") end
        cells[i + 1] = c
    end
    for i = 1, 7 do names[i] = { name = upper(tr(SHORT[i % 7 + 1])) } end
    model.calcell, model.calwd = cells, names
    text.cal_month = tr(MONTHS[month.m]) .. " " .. month.y
    text.cal_today, text.cal_new, text.cal_win = tr("Today"), tr("Event"), tr("In a window")
    text.cal_notes = #notes > 0 and (#notes .. " " .. tr("notifications")) or tr("Notifications")
    fact.cal_nnotes = #notes
    -- the ISO week of the chosen day, or of the month's middle (Luau's os.date has no %V): the year-day of that week's Thursday
    local cy, cm, cd = month.chosen:match("^(%d+)-(%d+)-(%d+)$")
    local wd = (tonumber(cy) == month.y and tonumber(cm) == month.m) and tonumber(cd) or 15
    local mid = os.date("*t", os.time({ year = month.y, month = month.m, day = wd, hour = 12 }))
    local thu = os.date("*t", os.time({ year = month.y, month = month.m, day = wd + 3 - (mid.wday + 5) % 7, hour = 12 }))
    text.cal_week = tr("week") .. " " .. ((thu.yday - 1) // 7 + 1)
    -- whose name day (the place's country) and the next holiday
    text.cal_names = (nameday.today or "") ~= "" and (tr("Name day today:") .. " " .. nameday.today .. ((nameday.tomorrow or "") ~= "" and (" · " .. tr("tomorrow") .. " " .. nameday.tomorrow) or "")) or ""
    local hol = nil
    for _, e in ipairs(cal.events) do if e.kind == "holiday" and e.date >= today then hol = e break end end
    text.cal_hol = hol and (tonumber(hol.date:sub(9, 10)) .. ". " .. tonumber(hol.date:sub(6, 7)) .. ". " .. hol.title) or ""
    fact.cal_hol_on = hol ~= nil
    fact.cal_names_on = text.cal_names ~= ""
    -- what comes next
    local e, left, id = next_event()
    fact.cal_next_on = e ~= nil
    cal.next, cal.next_id = e, id
    if e then
        text.cal_next_head = left < 60 and string.format(tr("NEXT IN %d MIN"), left) or (left < 24 * 60 and string.format(tr("NEXT IN %d H %d MIN"), left // 60, left % 60) or tr("TOMORROW"))
        text.cal_next_time = (e.time or "") .. (((e["end"] or "") ~= "") and (" – " .. e["end"]) or "")
        text.cal_next_title = e.title or ""
        text.cal_next_sub = (e.calendar or "") .. (((e.location or "") ~= "") and (" · " .. e.location) or "")
        fact.cal_link_on = (e.link or "") ~= ""
        text.cal_join = (e.link or ""):find("teams") and tr("Join (Teams)") or ((e.link or ""):find("meet.google") and tr("Join (Meet)") or ((e.link or ""):find("zoom") and tr("Join (Zoom)") or tr("Join")))
        text.cal_snooze = tr("Remind in 5 min")
    else
        text.cal_next_head, text.cal_next_time = tr("NOTHING MORE TODAY"), ""
        text.cal_next_title, text.cal_next_sub = tr("A free day"), tr("Nothing is planned for today or tomorrow.")
        fact.cal_link_on = false
    end
    -- the chosen day as a line of time: now, the events, the free hours between eight and eight
    local y, m, day = month.chosen:match("(%d+)-(%d+)-(%d+)")
    local t = os.date("*t", os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(day), hour = 12 }))
    text.cal_day_head = (month.chosen == today and (tr("Today") .. ", ") or "") .. tr(WEEKDAYS[t.wday]):lower() .. " " .. tonumber(day) .. ". " .. tonumber(m) .. "."
    local rows, list, busy, free = {}, events_on(month.chosen), 0, 0
    local minute = now.hour * 60 + now.min
    local cursor = 8 * 60
    if month.chosen == today then cursor = math.max(cursor, minute) end
    local placed_now = month.chosen ~= today
    cal.row_events = {}                      -- what each line is, for a press: the event, or false for free time and now
    local function add(r, e) if #rows < 8 then rows[#rows + 1] = r cal.row_events[#rows] = e or false end end
    for _, e in ipairs(list) do
        local s, en = mins(e.time), mins(e["end"])
        if not s then
            local r, g, b = rgb_of(e.color)
            add({ time = tr("all day"), title = e.title or "", sub = e.kind == "holiday" and tr("Holiday") or (e.calendar or ""), r = r, g = g, b = b, kind = 0 }, e)
        else
            if not placed_now and s >= minute then placed_now = true add({ time = hhmm(minute), title = "", sub = "", r = 0, g = 0, b = 0, kind = 2 }) end
            if s - cursor >= 60 and s <= 20 * 60 then
                free += s - cursor
                add({ time = hhmm(cursor), title = string.format(tr("Free %d h %02d min"), (s - cursor) // 60, (s - cursor) % 60), sub = tr("Room for deep work"), r = 0, g = 0, b = 0, kind = 1 })
            end
            busy += 1
            local r, g, b = rgb_of(e.color)
            add({ time = e.time, title = e.title or "", sub = (e.calendar or "") .. (((e.location or "") ~= "") and (" · " .. e.location) or ""), r = r, g = g, b = b, kind = 0 }, e)
            cursor = math.max(cursor, en or (s + 60))
        end
    end
    if not placed_now then add({ time = hhmm(minute), title = "", sub = "", r = 0, g = 0, b = 0, kind = 2 }) end
    if 20 * 60 - cursor >= 60 then
        free += 20 * 60 - cursor
        add({ time = hhmm(cursor), title = string.format(tr("Free %d h %02d min"), (20 * 60 - cursor) // 60, (20 * 60 - cursor) % 60), sub = tr("Until eight in the evening"), r = 0, g = 0, b = 0, kind = 1 })
    end
    model.calrow = rows
    text.cal_day_sum = string.format(tr("%d events · %d h free"), busy, free // 60)
    text.cal_empty = cal.side == 1 and tr("No notifications") or tr("Nothing on this day")
    -- the notifications, when they are what the right column shows
    local ns = {}
    for i, n in ipairs(notes) do
        if i > 6 then break end
        ns[i] = { title = (n.title or "") ~= "" and n.title or (n.app or ""), body = tostring(n.body or ""):gsub("%s+", " "), critical = (n.urgency or 1) >= 2 }
    end
    model.calnote = ns
    fact.cal_side = cal.side
    -- the sentence, and what it became
    text.cal_q_hint = tr("A new event in a sentence: Lunch with Peter tomorrow at 12 in Jihlavanka")
    text.cal_q_note = cal.reading and tr("The AI on this computer is reading it…")
        or ((cal.parsed and cal.parsed.ai) and tr("read by the AI on this computer") or tr("read on this computer"))
    text.cal_add = tr("Add")
    text.cal_accounts = tr("Linked calendars: Google, Microsoft 365, iCloud, Nextcloud and others · a subscription (.ics)")
    local p = cal.parsed
    fact.cal_p_on = p ~= nil and p.ok == true
    if fact.cal_p_on then
        local d0 = p.start:sub(1, 10)
        local dt0 = os.date("*t", os.time({ year = tonumber(d0:sub(1, 4)), month = tonumber(d0:sub(6, 7)), day = tonumber(d0:sub(9, 10)), hour = 12 }))
        text.cal_p1 = tr(SHORT[dt0.wday]) .. " " .. dt0.day .. ". " .. dt0.month .. "."
        text.cal_p2 = p.allday and tr("all day") or (p.start:sub(12, 16) .. " – " .. p["end"]:sub(12, 16))
        text.cal_p3 = (p.place or "") ~= "" and p.place or p.title
        text.cal_p4 = (p.calendar_name or "") ~= "" and p.calendar_name or tr("no calendar to write to")
    end
    text.ic_cal_prev, text.ic_cal_next, text.ic_cal_plus, text.ic_cal_bell = icons["chevron-left"], icons["chevron-right"], icons["plus"], icons[#notes > 0 and "bell" or "bell-off"]
    text.ic_cal_win = icons["external-link"]
    text.ic_cal_spark, text.ic_cal_video, text.ic_cal_drop, text.ic_cal_link = icons["sparkles"], icons["video"], icons["droplet"], icons["link"]
end
open_calendar = function(d, keep)
    learn_nameday()
    cal.side = keep and cal.side or 0
    -- the 760 × 520 of the design, scaled by 1.2; the coffee begins under the month, where the sentence is written
    card.open({}, { owner = d, id = "notes", custom = "calendar", width = 760, min_height = 700, split = 624, pane = 1, grow = true, keep = keep })
    fill_calendar()
    if os.time() - cal.asked > 60 then cal.asked = os.time() read_events(function() if card.id() == "notes" then fill_calendar() end end) end
end

return {
    id = "clockgoo", name = "ClockGoo", kind = "clock", nature = "calm", size = 33, swell = 0.09, seat = 22,
    home = { edge = 0, at = 0.79 }, pull = 0.25, reach = 130,
    about = function()
        return (quiet() and (tr("Do not disturb is on: notifications wait here quietly") .. " · ") or "")
            .. (#notes > 0 and (#notes .. " " .. tr("notifications") .. " · ") or "") .. tr("left: notifications and calendar · right: time, timer, alarms, weather")
    end,
    start = function(d)
        local ok, saved = pcall(sys.ask, "files.read", FILE, "json")
        if ok and type(saved) == "table" then
            if saved.quiet == true and E.settings().quiet == nil then E.set("quiet", true) end      -- where it was kept before
            kept.events = type(saved.events) == "table" and saved.events or {}
            kept.tasks = type(saved.tasks) == "table" and saved.tasks or {}
            kept.calendars = type(saved.calendars) == "table" and saved.calendars or {}
        end
        read_linked()
        every(30 * 60000, function() read_linked() end)
        -- the accounts' events, fresh every ten minutes (Evolution Data Server syncs them on its own)
        after(6000, function() read_events() end)
        every(10 * 60000, function() read_events(function() if card.id() == "notes" then fill_calendar() end end) end)
        -- the time, as the minute turns
        sys.watch("clock", function(c)
            if type(c) ~= "table" then return end
            date = string.format(tr("%s %d/%d"), tr(SHORT[(tonumber(c.weekday) or 0) + 1]), tonumber(c.day) or 1, tonumber(c.month) or 1)
            d:set({ label = c.time or "" })
            show_face(d)
        end)
        -- notifications: they do not expire by themselves, this is where they wait
        local served = pcall(sys.watch, "notifications", function(list)
            notes = list or {}
            local fresh = false
            local newest = nil
            for _, n in ipairs(notes) do if not seen[n.id] then seen[n.id], fresh = true, true newest = newest or n end end
            if fresh and not quiet() then
                d:ripple(5)
                local set = E.settings()
                if newest and set.banners ~= false then
                    text.toast_title = ((newest.title or "") ~= "" and newest.title or (newest.app or "")):sub(1, 80)
                    text.toast_body = tostring(newest.body or ""):gsub("%s+", " "):sub(1, 160)
                    fact.toast_n += 1
                end
                if set.notify_sound ~= false then pcall(sound.tone, { wave = "sine", freq = 740, to = 990, ms = 160, release = 220, volume = 0.35 }) end
            end
            show_beads(d)
            if card.id() == "notes" then fill_calendar() end
        end)
        if served then pcall(sys.call, "notifications.keep", true) end
        on("toast_press", function() open_notes(d) end)
        on("clock_notes", function() if card.id() == "notes" then card.close() else open_calendar(d) end end)
        on("clock_time", function() if card.id() == "time" then card.close() else open_time(d) end end)
        on("clk_tab", function(n) tab = tonumber(n) or 0 open_time(d, true) end)
        on("clk_act", function(n) act(tonumber(n) or 0) end)
        on("clk_more", function()
            local rows = {}
            for i, x in ipairs(links or {}) do
                if i > 12 then break end
                rows[#rows + 1] = { label = x.name, glyph = x.here and "map-pin" or "world", line = i > 1 and not x.here and (links[i - 1] or {}).here,
                                    run = function() card.close() open.url(x.url) end }
            end
            rows[#rows + 1] = { label = tr("Choose the services…"), glyph = "settings", line = true, run = function() card.close() after(80, function() open.settings("clockgoo") end) end }
            ctx.open(rows, { width = 240 })
        end)
        -- the calendar's own buttons
        on("cal_go", function(dir)
            dir = tonumber(dir) or 0
            if dir == 0 then local now = os.date("*t") month.y, month.m, month.chosen = now.year, now.month, iso(now)
            else
                month.m += dir
                if month.m < 1 then month.m, month.y = 12, month.y - 1 elseif month.m > 12 then month.m, month.y = 1, month.y + 1 end
            end
            fill_calendar()
        end)
        on("cal_pick", function(place)
            local key = month.cells[(tonumber(place) or 0) + 1]
            if key then month.chosen = key cal.side = 0 fill_calendar() end
        end)
        on("cal_show", function(k) cal.side = tonumber(k) or 0 fill_calendar() end)
        -- the calendar as a window of its own (apps/calendar.qml), at the chosen day; a line of the day opens its event there
        on("cal_window", function()
            card.close()
            run("latte-app", { "calendar", month.chosen or "" }, nil, { output = false })
        end)
        on("cal_open", function(i)
            local e = cal.row_events and cal.row_events[(tonumber(i) or 0) + 1]
            card.close()
            run("latte-app", (e and e.kind == "event") and { "calendar", e.date, e.source or "", e.uid or "" } or { "calendar", month.chosen or "" }, nil, { output = false })
        end)
        on("cal_join_it", function() if cal.next and (cal.next.link or "") ~= "" then card.close() open.url(cal.next.link) end end)
        on("cal_snooze_it", function() if cal.next_id then cal.snoozed[cal.next_id] = os.time() + 300 fill_calendar() end end)
        on("cal_note", function(i)
            local n = notes[(tonumber(i) or 0) + 1]
            if n then pcall(sys.call, "notifications.invoke", n.id, "default") pcall(sys.call, "notifications.dismiss", n.id) end
        end)
        on("cal_linked", function()
            ctx.open({ { label = tr("Accounts: Google, Microsoft 365, Exchange, Nextcloud…"), glyph = "users", run = function() card.close() run("latte-cal", { "accounts" }, nil, { output = false }) end },
                       { label = tr("A calendar from an address (.ics)…"), glyph = "link", run = function() open_calendars(d) end } }, { width = 330 })
        end)
        -- a sentence typed: what it would become, a moment after the typing stops
        local typing = 0
        local function cal_changed()
            fact.cal_typed = (text.cal_q or "") ~= ""
            typing += 1
            local mine = typing
            if not fact.cal_typed then cal.parsed = nil fill_calendar() return end
            after(450, function()
                if mine ~= typing then return end
                run("latte-cal", { "parse", text.cal_q }, function(out)
                    local ok, p = pcall(json.decode, out or "")
                    cal.parsed = ok and type(p) == "table" and p or nil
                    if card.id() == "notes" then fill_calendar() end
                end)
            end)
        end
        on("text:cal_q", cal_changed)
        on("cal_field_menu", function() card.field_menu("cal_q", cal_changed) end)   -- cut, copy, paste, as on any field
        on("cal_put", function()
            local p = cal.parsed
            if not (p and p.ok and (p.calendar or "") ~= "") then return end
            -- the words found no day or no time in it: the AI on this computer reads it first, and what it read is shown
            if not p.sure and not p.ai and not p.ai_failed then
                if cal.reading then return end
                cal.reading, typing = true, typing + 1
                fill_calendar()
                run("latte-cal", { "parse", "--ai", text.cal_q }, function(out)
                    local ok, q = pcall(json.decode, out or "")
                    cal.reading, cal.parsed = false, ok and type(q) == "table" and q.ok and q or p
                    if card.id() == "notes" then fill_calendar() end
                end)
                return
            end
            local args = { "add", p.calendar, p.title, p.start, p["end"] }
            if (p.place or "") ~= "" then args[#args + 1] = p.place end
            run("latte-cal", args, function()
                text.cal_q, fact.cal_typed, cal.parsed = "", false, nil
                read_events(function() if card.id() == "notes" then fill_calendar() end end)
            end)
        end)
        on("clk_dnd", function() E.set("quiet", not quiet()) show_face(d) fill_clock() end)
        on("clk_layout", function() card.close() after(80, function() open.settings("clockgoo") end) end)
        pcall(sys.watch, "apps", function(list) fill_apps = list or {} end)
        -- the weather beside the date, fresh every twenty minutes
        after(4000, function() read_sky(function() show_face(d) end) end)
        every(20 * 60000, function() read_sky(function() show_face(d) end) end)
        timers.guard(ring, function() if card.id() == "time" then open_time(d, true) end end)
        -- A running timer, or else the stopwatch, takes the date's place on the drop.
        every(1000, function()
            local running, started, left = timers.timer()
            local w = timers.all().watch
            if started then busy_face = true d:set({ line2 = timers.clock(left + (running and 999 or 0)) })
            elseif w.running then busy_face = true d:set({ line2 = timers.clock(timers.elapsed()) })
            elseif busy_face then busy_face = false show_face(d) end
        end)
    end,
    click = function(d) if card.id() == "notes" then card.close() else open_calendar(d) end end,
    right = function(d) if card.id() == "time" then card.close() else open_time(d) end end,
}
