-- The login screens' logic: it fills in what the scene shows and checks the password. The animated scene
-- (login.plm) and the still one for software rendering (login-safe.plm) declare the same facts and share it.
--
-- LATTE_LOGIN=greetd is the real thing: bin/latte-greeter starts the scene that way, and the password goes to
-- greetd through bin/latte-login. Anything else is a dry run that changes nothing on the system: the password
-- is "latte", the power menu only logs, and the opening plays again after a login.
--
-- With { lock = true } it is the lock screen (lockscreen.plm): the same screen for whoever is logged in, the password
-- checked by the system (`auth.check`), no session to choose; the right one opens the session as it was left.
return function(opts)
    local icons = require("lib/icons")
    local LOCK = type(opts) == "table" and opts.lock == true

    local ok_env, env = pcall(sys.ask, "env", "LATTE_LOGIN")
    local LIVE = LOCK or (ok_env and env == "greetd")
    local ME = ""
    if LOCK then
        local ok_user, user = pcall(sys.ask, "env", "USER")
        ME = ok_user and type(user) == "string" and user or ""
    end

    local sessions = {}          -- { file, name, cmd }, as latte-login lists them
    local known_user = ""        -- whoever the data named; typed over, it is another account

    local function note(locked) pcall(sys.call, "files.write", "lock.json", { locked = locked }) end

    local function guard(what, f, ...)
        local ok, err = pcall(f, ...)
        if not ok then log("login · " .. what .. ": " .. tostring(err)) end
    end

    local function show_sky(s)
        local sun, moon = s.sun or {}, s.moon or {}
        if (tonumber(sun.t) or -1) >= 0 then
            fact.sky_body, fact.sky_t, fact.sky_alt = 1, sun.t, math.max(0, tonumber(sun.alt) or 0)
        elseif (tonumber(moon.t) or -1) >= 0 then
            fact.sky_body, fact.sky_t, fact.sky_alt = 2, moon.t, math.max(0, tonumber(moon.alt) or 0)
            fact.moon_lit, fact.moon_waxing = tonumber(moon.lit) or 1, moon.waxing == true
        else
            fact.sky_body = 0
        end
        -- after sunset: how far it is down and on which side, for the afterglow and the stars
        fact.sun_down, fact.sun_west = (tonumber(sun.t) or -1) < 0 and math.max(0, -(tonumber(sun.alt) or 0)) or 0, sun.west ~= false
        local stars = {}
        for _, st in ipairs(type(s.stars) == "table" and s.stars or {}) do
            stars[#stars + 1] = { x = st[1], alt = st[2], mag = st[3], r = st[4], g = st[5], b = st[6] }
        end
        model.stars = stars
        fact.rain, fact.snow = tonumber(s.rain) or 0, s.snow == true
        fact.wind = tonumber(s.wind) or 0
        local now = type(s.now) == "table" and s.now or nil
        if not now then text.temp = "" fact.weather = 0 return end
        local today = type(s.days) == "table" and s.days[1] or nil
        local range = today and (tostring(today.max) .. "° / " .. tostring(today.min) .. "°") or ""
        local place = s.place or ""
        text.temp, text.g_weather = tostring(now.temp) .. "°", icons[now.icon] or ""
        text.place = (place ~= "" and range ~= "") and (place .. " · " .. range) or (place .. range)
        fact.weather = tonumber(now.kind) or 0
    end

    local function fill()
        run("latte-login", { "data" }, function(out)
            local ok, d = pcall(json.decode, out or "")
            if not ok or type(d) ~= "table" then log("login · latte-login data gave nothing") return end
            -- Only the first answer names the user: what has been typed since is not written over.
            if known_user == "" then known_user = LOCK and ME or (d.user or "") text.user = known_user end
            local coffee = type(d.coffee) == "table" and d.coffee or {}
            fact.water, fact.milk = tonumber(coffee[1]) or 0.55, tonumber(coffee[2]) or 0
            if tonumber(d.power_x) then fact.power_x = tonumber(d.power_x) end

            local lines = {}
            for _, t in ipairs(d.lines or {}) do lines[#lines + 1] = { t = t } end
            model.lines = lines
            fact.panel = (d.panel == "crash" and 1) or (d.panel == "news" and 2) or 0

            local info = {}
            for _, i in ipairs(d.info or {}) do info[#info + 1] = { g = icons[i.icon] or "", v = tostring(i.text or ""), on = true } end
            if not LIVE and #info == 0 then      -- a desktop has no battery: samples, so a dry run shows the goo come up
                info = { { g = icons["battery-3"], v = "82 %", on = true }, { g = icons["bell"], v = "3", on = true },
                         { g = icons["calendar-event"], v = "2", on = true } }
            end
            model.info = info

            -- The first answer picks the session used last; later ones leave the user's choice alone.
            local first = #sessions == 0
            sessions = (not LOCK and type(d.sessions) == "table") and d.sessions or {}
            local names = {}
            for _, s in ipairs(sessions) do names[#names + 1] = { name = s.name or s.file or "?" } end
            model.sessions = names
            if first then fact.ses_sel = math.max(0, math.min(#sessions - 1, tonumber(d.session) or 0)) end
            local chosen = sessions[fact.ses_sel + 1]
            text.ses_name = chosen and (chosen.name or chosen.file) or ""

            show_sky(type(d.sky) == "table" and d.sky or {})
        end)
    end

    local function show_date()
        run("date", { "+" .. tr("%A, %-d %B") }, function(out) text.date = (out or ""):gsub("%s+$", "") end)
    end

    local function check(pw, done)
        if not LIVE then return done(pw == "latte") end
        if LOCK then
            -- The answer to a wrong password takes a couple of seconds; the renderer does not wait for the logic.
            local ok, right = pcall(sys.ask, "auth.check", pw)
            if not ok then log("lock · the password could not be checked: " .. tostring(right)) end
            return done(ok and right == true)
        end
        local s = sessions[fact.ses_sel + 1] or { file = "latteos", cmd = { "/usr/bin/latte-session" } }
        local who = (text.user or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if who == "" then who = known_user end
        local args = { "auth", who, s.file or "", "--" }
        for _, c in ipairs(s.cmd or {}) do args[#args + 1] = c end
        if #args == 4 then args[5] = "/usr/bin/latte-session" end
        if who ~= known_user then            -- every account keeps its power drop where it likes
            run("latte-login", { "hint", who }, function(out)
                local x = tonumber((out or ""):match("[%d.]+"))
                fact.power_x = (x and x > 0 and x < 1) and x or 0.14
            end)
        end
        -- The password goes on the command's input: never in its arguments, its environment or a file.
        run("latte-login", args, function(out)
            local ok, d = pcall(json.decode, out or "")
            local good = ok and type(d) == "table" and d.ok == true
            if not good then log("login · refused: " .. tostring(ok and type(d) == "table" and d.error or out)) end
            done(good)
        end, { input = pw .. "\n" })
    end

    on("login", function()
        guard("password", function()
            local pw = text.password or ""
            if pw == "" or fact.checking then return end
            fact.checking = true
            local function go()
                check(pw, function(good)
                    text.password = ""
                    fact.checking = false
                    if not good then emit("rejected") return end
                    emit("accepted")
                    if LOCK then
                        -- the drop goes to its place on the bar, the coffee drains, the desktop shows, and only then the lock goes
                        after(2300, function() fact.locked = false note(false) end)
                    elseif LIVE then
                        -- The session is prepared; greetd starts it when the login compositor ends, after the drop has left.
                        after(2300, function() run("latte-login", { "done" }, nil, { output = false }) end)
                    else
                        after(4200, function() emit("again") emit("intro") end)
                    end
                end)
            end
            if LIVE then go() else after(500, go) end    -- a dry run answers at once: wait, so "Checking…" is seen
        end)
    end)

    on("text:password", function() emit("wake") end)

    on("session", function(i)
        local s = sessions[(i or 0) + 1]
        if s then text.ses_name = s.name or s.file or "" end
    end)

    -- The keyboard layouts come in the order the login compositor was started with. labwc cannot be told to
    -- switch from outside, so a press asks latte-greeter for the login screen again with the next one first.
    local layouts, layout = {}, 0
    do
        local ok, list = pcall(sys.ask, "env", "LATTE_LOGIN_LAYOUTS")
        for l in tostring(ok and list or ""):gmatch("[^,]+") do layouts[#layouts + 1] = l end
        local ok2, at = pcall(sys.ask, "env", "LATTE_LOGIN_LAYOUT")
        layout = tonumber(ok2 and at or 0) or 0
        if not LIVE then layouts, layout = { "us", "sk" }, 0 end
        if LOCK then layouts = {} end            -- the session's own layout is the one typed in
    end
    local function show_layout()
        fact.kb_count = #layouts
        text.kb_name = (layouts[layout + 1] or ""):upper()
    end
    show_layout()
    on("layout", function(lang)
        if #layouts < 2 then return end
        layout = (layout + 1) % #layouts
        show_layout()
        if LIVE then
            -- the language goes along: the new screen starts in the one chosen here
            run("latte-login", { "layout", tostring(layout), lang == 1 and "sk" or "en" }, nil, { output = false })
        end
    end)

    -- Caps Lock and Num Lock, from the keyboard's own lights: the scene cannot read them from the compositor.
    local function show_locks()
        run("latte-login", { "locks" }, function(out) fact.kb_lock = tonumber((out or ""):match("%d")) or 0 end)
    end
    show_locks()
    every(700, show_locks)

    local MACHINE = { "suspend", "reboot", "poweroff" }
    on("machine", function(k)
        local what = MACHINE[(k or 0) + 1]
        if not what then return end
        if not LIVE then log("login · dry run, not done: systemctl " .. what) return end
        run("systemctl", { what }, nil, { output = false })
    end)

    text.g_power, text.g_go, text.g_sleep = icons["power"], icons["arrow-right"], icons["moon"]
    text.g_restart, text.g_session = icons["refresh"], icons["device-desktop"]
    text.g_kb, text.g_lang = icons["keyboard"], icons["world"]
    fact.keep_backdrop = LIVE and not LOCK      -- the lock fades to the desktop it kept
    fill()
    show_date()
    every(60000, fill)           -- the news, the battery and the sky move on
    every(30000, show_date)
    if LOCK then
        local function lock_now()
            if fact.locked then return end
            fact.locked = true
            note(true)
            text.password = ""
            emit("again")
            fill()
            show_date()
            after(60, function() emit("intro") end)
        end
        on("lock_now", lock_now)
        -- A lock screen that died while it held the lock leaves the session locked, on purpose: the one started in
        -- its place (GuardDog, systemd) takes the lock up again. Called, not emitted: the logic's own emit goes to the scene,
        -- not to its own handlers, so the lock was never taken up (found 26. 10. by killing the user's systemd).
        local found, kept = pcall(sys.ask, "files.read", "lock.json", "json")
        if found and type(kept) == "table" and kept.locked == true then lock_now() end
        log("login · the lock screen")
        return
    end
    emit("intro")
    log("login · " .. (LIVE and "greetd" or "dry run"))
end
