-- The stopwatch, the timer and the alarms behind ClockGoo's card. They are kept in timers.json in the scene's
-- folder, so a timer that was running goes on after the scene starts again. The timer and the alarms are
-- watched here once a second whether the card is open or not (`guard`).
local M = { hour = 7, minute = 0 }           -- the alarm being set in the card
local FILE = "timers.json"
local data
local base, c0 = os.time(), os.clock()       -- the clock by seconds, and a finer one to count on from it

function M.now() return math.floor((base + (os.clock() - c0)) * 1000) end
-- 5:07, or 1:05:07 past the hour; with tenths for a stopwatch
function M.clock(ms, tenths)
    ms = math.max(0, math.floor(ms))
    local s = ms // 1000
    local h, m, sec = s // 3600, (s // 60) % 60, s % 60
    local out = h > 0 and string.format("%d:%02d:%02d", h, m, sec) or string.format("%02d:%02d", m, sec)
    if tenths then out = string.format(tr("%s.%d"), out, (ms // 100) % 10) end
    return out
end

local function all()
    if not data then
        local ok, t = pcall(sys.ask, "files.read", FILE, "json")
        data = ok and type(t) == "table" and t or {}
    end
    data.watch = data.watch or { running = false, start = 0, sum = 0, laps = {} }
    data.watch.laps = data.watch.laps or {}
    data.timer = data.timer or { ends = 0, length = 5 * 60000, left = 0 }
    data.alarms = data.alarms or {}
    return data
end
local function save() pcall(sys.call, "files.write", FILE, all()) end
M.all = all

-- ── the stopwatch ────────────────────────────────────────────────────────────────────────────────────────────
function M.elapsed()
    local w = all().watch
    return (w.sum or 0) + ((w.running and (w.start or 0) > 0) and (M.now() - w.start) or 0)
end
function M.watch_toggle()
    local w = all().watch
    if w.running then w.sum, w.running = M.elapsed(), false else w.start, w.running = M.now(), true end
    save()
end
function M.watch_lap()
    local w = all().watch
    if w.running then table.insert(w.laps, 1, M.elapsed()) save() end
end
function M.watch_reset() all().watch = { running = false, start = 0, sum = 0, laps = {} } save() end

-- ── the timer: it runs (`ends`), it is paused (`left`), or it waits to be started with its `length` ──────────
-- answers: running, started, ms left, its length in ms
function M.timer()
    local t = all().timer
    local running = (t.ends or 0) > 0
    local left = running and (t.ends - M.now()) or (t.left or 0)
    return running, running or (t.left or 0) > 0, math.max(0, left), t.length or 300000
end
function M.timer_toggle()
    local t = all().timer
    if (t.ends or 0) > 0 then t.left, t.ends = t.ends - M.now(), 0
    elseif (t.left or 0) > 0 then t.ends, t.left = M.now() + t.left, 0
    else t.ends, t.left = M.now() + (t.length or 300000), 0 end
    save()
end
function M.timer_cancel() local t = all().timer t.ends, t.left = 0, 0 save() end
function M.timer_start(minutes)
    local t = all().timer
    t.length = minutes * 60000
    t.ends, t.left = M.now() + t.length, 0
    save()
end
-- the wheel: a minute more or less, while it is neither running nor paused
function M.timer_adjust(dir)
    local t = all().timer
    if (t.ends or 0) > 0 or (t.left or 0) > 0 then return end
    t.length = math.clamp(math.floor((t.length or 300000) / 60000 + 0.5) + dir, 1, 180) * 60000
    save()
end

-- ── alarms ───────────────────────────────────────────────────────────────────────────────────────────────────
function M.alarm_add()
    local list = all().alarms
    if #list >= 10 then return end
    list[#list + 1] = { time = string.format("%02d:%02d", M.hour, M.minute), on = true, last = "" }
    table.sort(list, function(a, b) return a.time < b.time end)
    save()
end
function M.alarm_toggle(i)
    local a = all().alarms[i]
    if a then a.on, a.last = not a.on, "" save() end
end
function M.alarm_prune()                     -- the ones that are off go
    local keep = {}
    for _, a in ipairs(all().alarms) do if a.on then keep[#keep + 1] = a end end
    all().alarms = keep
    save()
end
function M.next_alarm()
    local now, nxt = os.date("%H:%M"), nil
    for _, a in ipairs(all().alarms) do
        if a.on and (not nxt or (a.time > now and (nxt.time <= now or a.time < nxt.time))) then nxt = a end
    end
    return nxt
end

-- Rings when the timer runs out or an alarm's minute comes: ring(title, text). `changed` after either.
function M.guard(ring, changed)
    every(1000, function()
        local d, touched = all(), false
        if (d.timer.ends or 0) > 0 and d.timer.ends - M.now() <= 0 then
            d.timer.ends, touched = 0, true
            ring(tr("Timer"), tr("Time is up") .. " (" .. M.clock(d.timer.length) .. ")")
        end
        local now, today = os.date("%H:%M"), os.date("%Y-%m-%d")
        for _, a in ipairs(d.alarms) do
            if a.on and a.time == now and a.last ~= today then
                a.last, touched = today, true
                ring(tr("Alarm") .. " " .. now, tr("LatteOS alarm"))
            end
        end
        if touched then save() if changed then changed() end end
    end)
end

return M
