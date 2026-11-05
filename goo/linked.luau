-- Linked calendars and planners (linked.plm; ROADMAP 10J.20): the calendars that are linked, listed and taken away; a calendar
-- added from a web address (.ics) or a CalDAV server (the password goes to latte-cal on its standard input, never into a
-- file or the list of processes); the lists of tasks, written at OK or Apply. Google and Microsoft 365 sign in through the
-- system's own window (OAuth in a browser). Everything is read and written by `latte-cal`.
local cals = {}                                -- the uid of each row of the calendars
local lists = {}                               -- the uid of each row of the lists of tasks
local shown = {}                               -- uid → on, as the lists are now (what is changed is not written yet)
local first = {}                               -- uid → on, as it was read
local ask_at = 0                               -- the row whose Remove was pressed once: "Really?"
local calrows, taskrows = {}, {}               -- what the two lists show (a model is only written, never read)

local function rgb(hex)
    hex = (hex or ""):gsub("^#", "")
    return (tonumber(hex:sub(1, 2), 16) or 247) / 255, (tonumber(hex:sub(3, 4), 16) or 200) / 255, (tonumber(hex:sub(5, 6), 16) or 115) / 255
end

local function dirty()
    for uid, on in pairs(shown) do if first[uid] ~= on then return true end end
    return false
end
local function show_dirty() fact.o_dirty = dirty() end

local function read_calendars()
    run("latte-cal", { "calendars" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        local rows = {}
        cals = {}
        if ok and type(list) == "table" then
            for _, c in ipairs(list) do
                local r, g, b = rgb(c.color)
                local where = (c.account ~= "" and c.account or tr("This computer")) .. (c.writable and "" or (" · " .. tr("read only")))
                rows[#rows + 1] = { name = c.name, sub = where, r = r, g = g, b = b, rm = c.removable == true, ask = false }
                cals[#cals + 1] = c.uid
            end
        end
        ask_at = 0
        calrows = rows
        model.acc = rows
        text.l_none = #rows == 0 and tr("No calendar is linked.") or ""
    end)
end

local function read_lists()
    run("latte-cal", { "tasklists" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        local rows = {}
        lists, first = {}, {}
        if ok and type(list) == "table" then
            for _, t in ipairs(list) do
                local r, g, b = rgb(t.color)
                first[t.uid] = t.enabled == true
                if shown[t.uid] == nil then shown[t.uid] = t.enabled == true end
                rows[#rows + 1] = { name = t.name, sub = t.account ~= "" and t.account or tr("This computer"), r = r, g = g, b = b, on = shown[t.uid] }
                lists[#lists + 1] = t.uid
            end
        end
        taskrows = rows
        model.tl = rows
        text.t_none = #rows == 0 and tr("No list of tasks is linked.") or ""
        show_dirty()
    end)
end

-- Remove: the first press asks "Really?", the second takes the calendar away
on("lk_rm", function(i)
    i = (tonumber(i) or 0) + 1
    if ask_at ~= i then
        ask_at = i
        for k, row in ipairs(calrows) do row.ask = k == i end
        model.acc = calrows
        return
    end
    local uid = cals[i]
    ask_at = 0
    if uid then run("latte-cal", { "remove-account", uid }, function() read_calendars() read_lists() end) end
end)

on("tl_flip", function(i)
    local uid = lists[(tonumber(i) or 0) + 1]
    if not uid then return end
    shown[uid] = not shown[uid]
    for k, u in ipairs(lists) do taskrows[k].on = shown[u] end
    model.tl = taskrows
    show_dirty()
end)

-- Google and Microsoft 365: the system's own window (GNOME Online Accounts), where the sign-in happens in a browser
on("sign_in", function() run("latte-cal", { "accounts" }, nil, { output = false }) end)

local function form(mode)
    fact.add_mode = mode
    text.l_msg = ""
    text.l_hint = mode == 2 and tr("The address ends in .ics, or begins with webcal://") or ""
end
on("add_caldav", function() form(1) end)
on("add_ics", function() form(2) end)
on("add_cancel", function() form(0) text.a_name, text.a_url, text.a_user, text.a_pass = "", "", "", "" end)

on("add_go", function()
    local mode = fact.add_mode
    local url = (text.a_url or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if not url:match("^https?://") and not url:match("^webcal://") then text.l_msg = tr("The address begins with https://") return end
    if mode == 1 and (text.a_user or "") == "" then text.l_msg = tr("Write the user.") return end
    fact.l_busy = true
    text.l_msg = tr("Adding…")
    local args = { "add-account", mode == 2 and "ics" or "caldav", (text.a_name or ""), url }
    if mode == 1 then args[#args + 1] = text.a_user end
    local out = {}
    local id = spawn("latte-cal", args, function(line) out[#out + 1] = line end, function()
        fact.l_busy = false
        local ok, r = pcall(json.decode, table.concat(out, "\n"))
        if ok and type(r) == "table" and r.ok then
            text.l_msg = ""
            fact.add_mode = 0
            text.a_name, text.a_url, text.a_user, text.a_pass = "", "", "", ""
            read_calendars()
        else
            text.l_msg = mode == 1 and tr("It was not added. Is the keyring unlocked?") or tr("It was not added.")
        end
    end, { stdin = "open" })
    if mode == 1 then write(id, (text.a_pass or "") .. "\n") end
end)

-- writes the lists of tasks that were switched, then `after_` if it should close
local function write_lists(after_)
    local n = 0
    for uid, on in pairs(shown) do
        if first[uid] ~= on then
            n += 1
            run("latte-cal", { "tasklist-show", uid, on and "on" or "off" }, function()
                n -= 1
                if n == 0 then read_lists() if after_ then after_() end end
            end)
        end
    end
    if n == 0 and after_ then after_() end
end
on("apply", function() write_lists() end)
on("ok", function() write_lists(function() emit("done") end) end)

require("lib/cup").start()
text.o_title = tr("Linked calendars and planners")
read_calendars()
read_lists()
