-- Calendar settings (calsettings.plm; ROADMAP 10J.16): read with `latte-cal settings`, kept here until OK or Apply, then written with
-- `latte-cal settings-set` (~/.config/latteos/calendar.json). The Calendar app and the working-days count read that file.
local st = nil                                 -- the settings as read
local now = {}                                 -- the settings as they are on the screen
local countries = {}                           -- code → name in English
local order = {}                               -- the codes, in the order shown

local function copy(t) local o = {} for k, v in pairs(t) do o[k] = type(v) == "table" and copy(v) or v end return o end

local function has(list, v) for _, x in ipairs(list) do if x == v then return true end end return false end

local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    if #a ~= #b then return false end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    return true
end

local function show()
    local rows = {}
    for i, code in ipairs(order) do
        rows[i] = { code = code, name = tr(countries[code]), nd = has(now.namedays, code), hol = now.holiday_country == code }
    end
    model.ctry = rows
    fact.hol_place = now.holiday_country == ""
    text.place_text = tr("The place's country") .. " (" .. tr(countries[st.place] or st.place:upper()) .. ")"
    fact.ws = now.week_start
    for k = 0, 6 do fact["wd" .. k] = has(now.workdays, k) end
    local h = now.hours
    text.hours_text = (h == math.floor(h) and tostring(math.floor(h)) or tostring(h):gsub("%.", ",")) .. " " .. tr("hours")
    fact.o_dirty = not (equal(now.namedays, st.namedays) and now.holiday_country == st.holiday_country and now.week_start == st.week_start
        and equal(now.workdays, st.workdays) and now.hours == st.hours)
end

on("nd_flip", function(i)
    local code = order[(tonumber(i) or 0) + 1]
    if not code then return end
    if has(now.namedays, code) then
        local l = {} for _, c in ipairs(now.namedays) do if c ~= code then l[#l + 1] = c end end
        now.namedays = l
    else
        now.namedays[#now.namedays + 1] = code
    end
    show()
end)
on("hol_pick", function(i)
    i = tonumber(i) or -1
    now.holiday_country = i < 0 and "" or (order[i + 1] or "")
    show()
end)
on("ws_pick", function(k) now.week_start = tonumber(k) or 0 show() end)
on("wd_flip", function(k)
    k = tonumber(k) or 0
    local l = {}
    if has(now.workdays, k) then
        for _, d in ipairs(now.workdays) do if d ~= k then l[#l + 1] = d end end
        if #l == 0 then return end             -- some day has to be worked
    else
        for _, d in ipairs(now.workdays) do l[#l + 1] = d end
        l[#l + 1] = k
        table.sort(l)
    end
    now.workdays = l
    show()
end)
on("hrs_less", function() now.hours = math.max(0.5, now.hours - 0.5) show() end)
on("hrs_more", function() now.hours = math.min(24, now.hours + 0.5) show() end)

local function read()
    run("latte-cal", { "settings" }, function(out)
        local ok, s = pcall(json.decode, out or "")
        if not ok or type(s) ~= "table" then return end
        st = s
        countries = s.nameday_countries or {}
        order = {}
        for code in pairs(countries) do order[#order + 1] = code end
        table.sort(order, function(a, b) return tr(countries[a]) < tr(countries[b]) end)
        now = copy(s)
        show()
    end)
end

local function write(after_)
    if not st then return end
    local change = { namedays = now.namedays, holiday_country = now.holiday_country, week_start = now.week_start, workdays = now.workdays, hours = now.hours }
    run("latte-cal", { "settings-set", json.encode(change) }, function()
        read()
        if after_ then after_() end
    end)
end
on("apply", function() write() end)
on("ok", function() write(function() emit("done") end) end)

require("lib/cup").start()
text.o_title = tr("Calendar settings")
read()
