-- ClockGoo (čas, kalendár, upozornenia a pohoda, LATTEOS-GOO.md „Nová architektúra“ §2): voliteľná kvapka, ktorá
-- spája čas a centrum upozornení (predtým TimeGoo a DaNoGoo). V kvapke veľký čas a dátum; guľky počtu upozornení —
-- systémové/kritické červeno-kávové, ostatné žlté (do 4, nad 4 s počtom); nové upozornenie zvlní hladinu.
-- Ľavý klik = HROZNO UPOZORNENÍ: kvapka sa vymrští od okraja a nechá za sebou visieť kapsuly na lepkavom vlákne
-- (najnovšie hore, najviac 8). Bobuľa: ľavý = otvoriť, pravý = akcie (ak má), odtiahnutie = zahodiť. Zavrie ho klik
-- na kvapku alebo mimo. Kritické a systémové majú červené jadro.
-- Pravý klik = KARTA ČASU (lib/cas.luau, údaje spoločné s plochou Kvapky): Prehľad (dátum, týždeň, najbližší budík,
-- digitálna pohoda, svetové hodiny) · Stopky (medzičasy) · Minútka (koliesko nastaví dĺžku) · Budíky. Minútka
-- a budíky zvonia, aj keď je karta zatvorená; bežiaca minútka alebo stopky sa ukazujú v kvapke namiesto dátumu.
-- Kalendár s udalosťami a počasie v karte ešte nie sú (sú v scéne plochy Kvapky). Upozornenia prijíma pleamar —
-- iba jeden proces.
local E = require("lib/engine")
local cas = require("lib/cas")
local DNI = { "ne", "po", "ut", "st", "št", "pi", "so" }
local notes, seen = {}, {}
-- hrozno: polomer bobule, polovica rovnej časti kapsuly, rozostup a výška prvej nad okrajom (nad hlavou GooBaru)
local R, KW, STEP, Y0, MAX = 19, 118, 46, 96, 8
local open, shown = false, {}

local function close(d)
    if not open then return end
    open = false
    for id in pairs(shown) do E.remove(id) end
    shown = {}
    fact.hr_open = false
    if d.yRest then d.y, d.yRest = d.yRest, nil end
    d:stlac()
    E.publish()
end

local function hang(d)
    local edge = d.edge or 0
    local n = math.min(#notes, MAX)
    if n == 0 or edge % 2 == 1 then close(d) return false end       -- na bočnom okraji hrozno nie je (ponuka)
    local len, sh = E.len(d), tonumber(fact.sh) or 1080
    -- kapsuly sa musia zmestiť na obrazovku a nesmú do rohovej lišty Noctalie
    local hi = math.min(len - 10, E.hiAlong(d) + d.v.velkost * d.z)
    local ax = math.max(KW + R + 10, math.min(E.along(d), hi - KW - R))
    local keep = {}
    for i = 1, n do
        local x = notes[i]                                            -- služba ich dáva od najnovšieho
        local id = "nt:" .. tostring(x.id)
        local crit = (x.urgency or 1) >= 2
        local body = tostring(x.body or ""):gsub("%s+", " ")
        local acts = type(x.actions) == "table" and x.actions or {}
        keep[id] = true
        local c = E.upsert({
            id = id, nazov = x.app or "", velkost = R, kw = KW, visi = true, okraj = edge,
            poloha = { x = ax / len, y = Y0 + (n - i) * STEP },
            gravitacia = 0, vznos = 0, dosah = 1, rast = 0.04, svetlo = 0.3, mlaka = 0, zliatie = 0.6,
            ikona = crit and "alert-triangle" or "bell", obr = (x.icon or "") ~= "" and x.icon or nil,
            text = ((x.app or "") ~= "" and x.app .. " · " or "") .. (x.title or ""), t2 = body,
            klik = function()
                pcall(sys.call, "notifications.invoke", x.id, "default")
                pcall(sys.call, "notifications.dismiss", x.id)
            end,
            pravy = #acts > 0 and function()
                local items = {}
                for _, a in ipairs(acts) do
                    items[#items + 1] = { label = a.label or a.key or "", glyph = "chevron-right", run = function()
                        pcall(sys.call, "notifications.invoke", x.id, a.key)
                        pcall(sys.call, "notifications.dismiss", x.id)
                    end }
                end
                items[#items + 1] = { label = tr("Dismiss"), glyph = "x", sep = true, run = function() pcall(sys.call, "notifications.dismiss", x.id) end }
                E.menu(items, 260)
            end or nil,
            -- odtiahnutá preč = zahodená; inak sa vráti na vlákno
            pustenie = function(c, X, Y)
                local cy = edge == 0 and (sh - 6 - c.y) or (6 + c.y)
                if math.abs(X - ax) > KW + 60 or math.abs(Y - cy) > 70 then pcall(sys.call, "notifications.dismiss", x.id) end
                return false
            end,
        })
        if c then if crit then c:jadro("hardver", 0.75, false) else c:jadro() end end
    end
    for id in pairs(shown) do if not keep[id] then E.remove(id) end end
    shown = keep
    -- kvapka nad hroznom, lepkavé vlákno od okraja k nej
    if not d.yRest then d.yRest = d.y end
    d.y = Y0 + n * STEP + 14
    fact.vlx = E.along(d)
    fact.vly0 = edge == 0 and sh - 6 or 6
    fact.vly1 = edge == 0 and sh - 6 - d.y or 6 + d.y
    fact.hr_open = true
    E.publish()
    return true
end

local function paint(d)
    local crit, n = 0, #notes
    for _, x in ipairs(notes) do if (x.urgency or 1) >= 2 then crit = crit + 1 end end
    if n == 0 then d:gulky(0) return end
    d:gulky(n, crit > 0 and "system" or "zlta")
end

-- ── karta času (pravý klik) ──────────────────────────────────────────────────────────────────────────────────
local DNI_PLNE = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local tab = 0
local card
local function chips(d)
    local function t(i, glyph, label) return { glyph = glyph, label = tr(label), on = tab == i, run = function() tab = i card(d, true) end } end
    return { t(0, "layout-dashboard", "Overview"), t(1, "stopwatch", "Stopwatch"), t(2, "hourglass", "Timer"), t(3, "alarm", "Alarms") }
end
local function overview(d)
    local t = os.date("*t")
    -- týždeň podľa ISO 8601 (Luau os.date nepozná %V): pondelok = 1
    local iso = (t.wday + 5) % 7 + 1
    local week = (t.yday - iso + 10) // 7
    if week < 1 then week = 52 end
    local items = {
        { big = true, off = true, label = os.date("%H:%M") },
        { off = true, glyph = "calendar", label = tr(DNI_PLNE[t.wday]) .. "  " .. t.day .. ". " .. t.month .. ". " .. t.year,
          hint = tr("week") .. " " .. week },
    }
    local parts = {}
    local nxt = cas.next_alarm()
    if nxt then parts[#parts + 1] = tr("Alarm") .. " " .. nxt.time end
    local running, active, left = cas.timer_state()
    if running then parts[#parts + 1] = tr("Timer") .. " " .. cas.fmt(left + 999) end
    if #parts > 0 then items[#items + 1] = { off = true, glyph = "alarm", label = table.concat(parts, "  ·  ") } end
    -- digitálna pohoda: čas pred obrazovkou a tri najpoužívanejšie aplikácie dnes
    local p = cas.pohoda or {}
    items[#items + 1] = { sep = true, glyph = "heart", label = cas.dur(p.spolu or 0) .. " " .. tr("on screen today"), hint = tr("details"),
                          run = function() run("latte-app", { "monitor", "pohoda" }) end }
    local top = math.max((p.aplikacie or {})[1] and p.aplikacie[1].s or 1, 1)
    for _, a in ipairs(p.aplikacie or {}) do
        items[#items + 1] = { off = true, label = a.nazov or "", hint = cas.dur(a.s or 0), bar = (a.s or 0) / top }
    end
    for i, z in ipairs(cas.pasma or {}) do
        items[#items + 1] = { off = true, sep = i == 1, glyph = "world", label = z.mesto or "", hint = (z.hm or "") .. ((z.rozdiel or "") ~= "" and "  ·  " .. z.rozdiel or "") }
    end
    if #notes > 0 then
        items[#items + 1] = { sep = true, danger = true, glyph = "trash", label = tr("Clear all") .. " (" .. #notes .. " " .. tr("notifications") .. ")",
                              run = function() pcall(sys.call, "notifications.clear") end }
    end
    items[#items + 1] = { sep = #notes == 0, glyph = "settings", label = tr("Date and time settings"), run = function() run("latte-app", { "nastavenia", "cas" }) end }
    return items
end
local function stopwatch(d)
    local sw = cas.timers().sw
    local function again() card(d, true) end
    local items = {
        { big = true, off = true, label = cas.fmt(cas.elapsed(), true) },
        { keep = true, glyph = sw.running and "player-pause" or "player-play", label = tr(sw.running and "Stop" or "Start"), run = function() cas.sw_toggle() again() end },
    }
    if sw.running then items[#items + 1] = { keep = true, glyph = "flag", label = tr("Lap"), run = function() cas.sw_lap() again() end } end
    if sw.running or (sw.acc or 0) > 0 then items[#items + 1] = { keep = true, glyph = "refresh", label = tr("Reset"), run = function() cas.sw_reset() again() end } end
    for i, lap in ipairs(sw.laps) do
        if i > 6 then break end
        items[#items + 1] = { off = true, sep = i == 1, label = tr("Lap") .. " " .. (#sw.laps - i + 1), hint = cas.fmt(lap, true) }
    end
    return items
end
local function timer(d)
    local running, active, left, dur = cas.timer_state()
    local function again() card(d, true) end
    local items = {
        { big = true, off = true, label = cas.fmt(active and (left + (running and 999 or 0)) or dur), bar = active and left / math.max(dur, 1) or 1 },
        { keep = true, glyph = running and "player-pause" or "player-play", label = tr(running and "Pause" or (active and "Resume" or "Start")),
          run = function() cas.timer_toggle() again() end },
    }
    if active then
        items[#items + 1] = { keep = true, glyph = "x", label = tr("Cancel"), run = function() cas.timer_cancel() again() end }
    else
        -- myš prvá: dĺžku nastaví koliesko nad riadkom, alebo jedna z predvolieb nižšie
        items[#items + 1] = { keep = true, glyph = "adjustments-horizontal", label = tr("Length") .. ": " .. math.floor(dur / 60000 + 0.5) .. " min", hint = tr("wheel"),
                              wheel = function(dir) cas.timer_adjust(dir) again() end, run = function() cas.timer_adjust(1) again() end }
        for i, m in ipairs({ 1, 5, 10, 15, 25, 45 }) do
            items[#items + 1] = { keep = true, sep = i == 1, glyph = "hourglass", label = m .. " min", run = function() cas.timer_start(m) again() end }
        end
    end
    return items
end
local function alarms(d)
    local function again() card(d, true) end
    local items, off = {}, 0
    for i, a in ipairs(cas.timers().alarms) do
        if i > 7 then break end
        if not a.on then off = off + 1 end
        items[#items + 1] = { keep = true, glyph = "alarm", on = a.on == true, label = (a.time or "") .. ((a.label or "") ~= "" and "  " .. a.label or ""),
                              hint = tr(a.on and "on" or "off"), run = function() cas.alarm_toggle(i) again() end }
    end
    if #items == 0 then items[1] = { off = true, glyph = "alarm", label = tr("No alarms") } end
    -- nový budík: hodinu a minútu nastaví koliesko (alebo klik = o krok ďalej)
    items[#items + 1] = { keep = true, sep = true, glyph = "clock", label = tr("Hour") .. ": " .. string.format("%02d", cas.alh), hint = tr("wheel"),
                          wheel = function(dir) cas.alh = (cas.alh + dir) % 24 again() end, run = function() cas.alh = (cas.alh + 1) % 24 again() end }
    items[#items + 1] = { keep = true, glyph = "clock", label = tr("Minute") .. ": " .. string.format("%02d", cas.alm), hint = tr("wheel"),
                          wheel = function(dir) cas.alm = (cas.alm + dir * 5) % 60 again() end, run = function() cas.alm = (cas.alm + 5) % 60 again() end }
    items[#items + 1] = { keep = true, glyph = "plus", label = tr("Add alarm") .. " " .. string.format("%02d:%02d", cas.alh, cas.alm), run = function() cas.alarm_add() again() end }
    if off > 0 then items[#items + 1] = { keep = true, danger = true, glyph = "trash", label = tr("Remove alarms that are off"), run = function() cas.alarm_prune() again() end } end
    return items
end
card = function(d, keep)
    local items = (tab == 1 and stopwatch or tab == 2 and timer or tab == 3 and alarms or overview)(d)
    E.menu(items, 384, { id = "clock", chips = chips(d), keep = keep })
    if not keep then cas.load(function() if E.menuId() == "clock" then card(d, true) end end) end     -- čerstvé údaje
end

return {
    id = "clockgoo", nazov = "ClockGoo", druh = 2, povaha = "pokojna", velkost = 33, rast = 0.09, vyska = 22,
    poloha = { x = 0.79, y = 22 }, gravitacia = 0.25, dosah = 130, zoom = true,
    kazdych = 10000,
    tik = function(d)
        run("date", { "+%H:%M %w %-d %-m" }, function(out)
            local hm, w, dd, mm = (out or ""):match("(%d+:%d+) (%d) (%d+) (%d+)")
            if hm then
                d.datum = DNI[tonumber(w) + 1] .. " " .. dd .. ". " .. mm .. "."
                d:ikona(hm)
                if not d.alt then d:text(d.datum) end
            end
        end)
    end,
    start = function(d)
        local ok = sys.watch("notifications", function(list)
            notes = list or {}
            local fresh = false
            for _, x in ipairs(notes) do if not seen[x.id] then seen[x.id] = true fresh = true end end
            if fresh then d:vlnka(5) end
            paint(d)
            if open then hang(d) end                                  -- otvorené hrozno sleduje zoznam
        end)
        -- upozornenia neexpirujú samy (kvapka je centrum upozornení, ako v Kvapkách)
        if ok then pcall(sys.call, "notifications.keep", true) end
        on("hr_close", function() close(d) end)
        -- čas: údaje, stráženie minútky a budíkov, živá karta (stopky a minútka 5× za sekundu, prehľad raz)
        cas.load()
        cas.guard(function() if E.menuId() == "clock" then card(d, true) end end)
        local n = 0
        every(200, function()
            n = n + 1
            if E.menuId() == "clock" and (tab == 1 or tab == 2 or n % 5 == 0) then card(d, true) end
        end)
        -- bežiaca minútka (prednosť) alebo stopky sa ukazujú v kvapke namiesto dátumu
        every(1000, function()
            local running, active, left = cas.timer_state()
            local sw = cas.timers().sw
            if active then d.alt = true d:text(cas.fmt(left + (running and 999 or 0)))
            elseif sw.running then d.alt = true d:text(cas.fmt(cas.elapsed()))
            elseif d.alt then d.alt = false d.v.text = d.datum or "" E.publish() end
        end)
    end,
    klik = function(d)
        if open then close(d) return end
        if #notes == 0 then d:bublina(tr("No notifications")) return end
        open = true
        if hang(d) then d:poskoc() return end
        -- bočný okraj: zoznam v ponuke Goo
        open = false
        local items = {}
        for i, x in ipairs(notes) do                            -- služba ich dáva od najnovšieho: najnovšie hore
            if i > MAX then break end
            items[#items + 1] = { label = (x.app or "") .. ": " .. (x.title or ""), glyph = (x.urgency or 1) >= 2 and "alert-triangle" or "bell",
                                  run = function() pcall(sys.call, "notifications.invoke", x.id, "default") end }
        end
        items[#items + 1] = { label = tr("Clear all") .. " (" .. #notes .. ")", glyph = "trash", sep = true, danger = true,
                              run = function() pcall(sys.call, "notifications.clear") end }
        E.menu(items, 340)
    end,
    -- počas otvoreného hrozna sa kvapka neťahá inam (ostane nad ním)
    pustenie = function(d) if open then return false end end,
    pravy = function(d) card(d) end,
    popis = function(d)
        return (#notes > 0 and (#notes .. " " .. tr("notifications") .. " · ") or "") .. tr("left: notifications · right: time and calendar")
    end,
}
