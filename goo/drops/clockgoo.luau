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
    local rows = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_notes(d) end },
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
            read_linked(function() if card.id() == "notes" then open_notes(d, true) end end)
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
local function overview()
    local t = os.date("*t")
    -- the week as ISO 8601 counts it, Monday first
    local week = (t.yday - ((t.wday + 5) % 7 + 1) + 10) // 7
    if week < 1 then week = 52 end
    local rows = {
        { big = true, label = os.date("%H:%M") },
        { glyph = "calendar", label = tr(WEEKDAYS[t.wday]) .. "  " .. t.day .. ". " .. t.month .. ". " .. t.year, hint = tr("week") .. " " .. week, quiet = true },
    }
    local parts = {}
    local alarm = timers.next_alarm()
    if alarm then parts[#parts + 1] = tr("Alarm") .. " " .. alarm.time end
    local running, _, left = timers.timer()
    if running then parts[#parts + 1] = tr("Timer") .. " " .. timers.clock(left + 999) end
    if #parts > 0 then rows[#rows + 1] = { glyph = "alarm", label = table.concat(parts, "  ·  "), quiet = true } end
    return rows
end
local function stopwatch(again)
    local w = timers.all().watch
    local rows = {
        { big = true, label = timers.clock(timers.elapsed(), true) },
        { keep = true, glyph = w.running and "player-pause" or "player-play", label = tr(w.running and N("Stop") or N("Start")), run = function() timers.watch_toggle() again() end },
    }
    if w.running then rows[#rows + 1] = { keep = true, glyph = "flag", label = tr("Lap"), run = function() timers.watch_lap() again() end } end
    if w.running or (w.sum or 0) > 0 then rows[#rows + 1] = { keep = true, glyph = "refresh", label = tr("Reset"), run = function() timers.watch_reset() again() end } end
    for i, lap in ipairs(w.laps) do
        if i > 6 then break end
        rows[#rows + 1] = { line = i == 1, label = tr("Lap") .. " " .. (#w.laps - i + 1), hint = timers.clock(lap, true), quiet = true }
    end
    return rows
end
local function timer(again)
    local running, started, left, length = timers.timer()
    local rows = {
        { big = true, label = timers.clock(started and (left + (running and 999 or 0)) or length), bar = started and left / math.max(length, 1) or 1 },
        { keep = true, glyph = running and "player-pause" or "player-play", label = tr(running and N("Pause") or (started and N("Resume") or N("Start"))),
          run = function() timers.timer_toggle() again() end },
    }
    if started then
        rows[#rows + 1] = { keep = true, glyph = "x", label = tr("Cancel"), run = function() timers.timer_cancel() again() end }
    else
        -- the mouse first: the wheel over the row sets the length, or one of the ready lengths below does
        rows[#rows + 1] = { keep = true, glyph = "adjustments-horizontal", label = tr("Length") .. ": " .. math.floor(length / 60000 + 0.5) .. " min", hint = tr("wheel"),
                            wheel = function(dir) timers.timer_adjust(dir) again() end, run = function() timers.timer_adjust(1) again() end }
        for i, minutes in ipairs({ 1, 5, 10, 15, 25, 45 }) do
            rows[#rows + 1] = { keep = true, line = i == 1, glyph = "hourglass", label = minutes .. " min", run = function() timers.timer_start(minutes) again() end }
        end
    end
    return rows
end
local function alarms(again)
    local rows, off = {}, 0
    for i, a in ipairs(timers.all().alarms) do
        if i > 7 then break end
        if not a.on then off += 1 end
        rows[#rows + 1] = { keep = true, glyph = "alarm", on = a.on == true, label = a.time or "", hint = tr(a.on and N("on") or N("off")),
                            run = function() timers.alarm_toggle(i) again() end }
    end
    if #rows == 0 then rows[1] = { glyph = "alarm", label = tr("No alarms"), off = true } end
    -- a new alarm: the wheel sets the hour and the minute, a press goes a step on
    rows[#rows + 1] = { keep = true, line = true, glyph = "clock", label = tr("Hour") .. ": " .. string.format("%02d", timers.hour), hint = tr("wheel"),
                        wheel = function(dir) timers.hour = (timers.hour + dir) % 24 again() end, run = function() timers.hour = (timers.hour + 1) % 24 again() end }
    rows[#rows + 1] = { keep = true, glyph = "clock", label = tr("Minute") .. ": " .. string.format("%02d", timers.minute), hint = tr("wheel"),
                        wheel = function(dir) timers.minute = (timers.minute + dir * 5) % 60 again() end, run = function() timers.minute = (timers.minute + 5) % 60 again() end }
    rows[#rows + 1] = { keep = true, glyph = "plus", label = tr("Add alarm") .. " " .. string.format("%02d:%02d", timers.hour, timers.minute), run = function() timers.alarm_add() again() end }
    if off > 0 then rows[#rows + 1] = { keep = true, danger = true, glyph = "trash", label = tr("Remove alarms that are off"), run = function() timers.alarm_prune() again() end } end
    return rows
end
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
local function weather()
    if not (sky and sky.now) then return { { big = true, label = "—" }, { glyph = "cloud", label = tr("No forecast yet"), off = true } } end
    local function rain(p) return (tonumber(p) or 0) > 0 and ("  ·  " .. p .. " %") or "" end
    local rows = { { big = true, label = tostring(sky.now.temp) .. " °C" .. ((sky.place or "") ~= "" and ("  " .. sky.place) or "") } }
    local days = type(sky.days) == "table" and sky.days or {}
    if days[1] then
        rows[#rows + 1] = { glyph = sky_glyph(sky.now.code), label = tr("Today"), hint = days[1].max .. "° / " .. days[1].min .. "°" .. rain(days[1].rain), quiet = true }
    end
    for i, h in ipairs(type(sky.hours) == "table" and sky.hours or {}) do
        if i > 5 then break end
        rows[#rows + 1] = { line = i == 1, glyph = sky_glyph(h.code), label = h.time or "", hint = tostring(h.temp) .. "°", quiet = true }
    end
    for i = 2, math.min(7, #days) do
        local x = days[i]                          -- its weekday counts from Monday, the names from Sunday
        rows[#rows + 1] = { line = i == 2, glyph = sky_glyph(x.code), label = i == 2 and tr("Tomorrow") or tr(WEEKDAYS[((tonumber(x.weekday) or 0) + 1) % 7 + 1]),
                            hint = x.max .. "° / " .. x.min .. "°" .. rain(x.rain), quiet = true }
    end
    return rows
end
local TABS = { { glyph = "layout-dashboard", name = N("Overview") }, { glyph = "stopwatch", name = N("Stopwatch") }, { glyph = "hourglass", name = N("Timer") },
               { glyph = "alarm", name = N("Alarms") }, { glyph = "cloud", name = N("Weather") } }
local ticking
open_time = function(d, keep)
    local function again() open_time(d, true) end
    -- The stopwatch and the timer are seen running: while the card shows them it is drawn again five times a second.
    if not ticking then
        ticking = every(200, function()
            if card.id() ~= "time" then cancel(ticking) ticking = nil return end
            if tab == 1 or tab == 2 then open_time(d, true) end
        end)
    end
    local tabs = {}
    for i, t in ipairs(TABS) do tabs[i] = { glyph = t.glyph, label = tr(t.name), on = tab == i - 1, run = function() tab = i - 1 open_time(d, true) end } end
    local rows = (tab == 1 and stopwatch(again)) or (tab == 2 and timer(again)) or (tab == 3 and alarms(again)) or (tab == 4 and weather()) or overview()
    -- the same height on every tab: the card's top edge stays where it is
    card.open(rows, { owner = d, id = "time", width = 400, tabs = tabs, keep = keep, min_height = 500 })
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
            if card.id() == "notes" then open_notes(d, true) end
        end)
        if served then pcall(sys.call, "notifications.keep", true) end
        on("toast_press", function() open_notes(d) end)
        on("clock_notes", function() if card.id() == "notes" then card.close() else open_notes(d) end end)
        on("clock_time", function() if card.id() == "time" then card.close() else open_time(d) end end)
        -- the weather beside the date, fresh every twenty minutes
        after(4000, function() read_sky(function() show_face(d) end) end)
        every(20 * 60000, function() read_sky(function() show_face(d) end) end)
        timers.guard(ring, function() if card.id() == "time" then open_time(d, true) end end)
        -- A running timer, or else the stopwatch, takes the date's place on the drop.
        every(1000, function()
            if card.id() == "time" and (tab == 0 or tab == 3) then open_time(d, true) end
            local running, started, left = timers.timer()
            local w = timers.all().watch
            if started then busy_face = true d:set({ line2 = timers.clock(left + (running and 999 or 0)) })
            elseif w.running then busy_face = true d:set({ line2 = timers.clock(timers.elapsed()) })
            elseif busy_face then busy_face = false show_face(d) end
        end)
    end,
    click = function(d) if card.id() == "notes" then card.close() else open_notes(d) end end,
    right = function(d) if card.id() == "time" then card.close() else open_time(d) end end,
}
