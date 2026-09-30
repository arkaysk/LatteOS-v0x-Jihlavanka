-- Logika Kvapky: iba fakty a príkazy. Zoznam okien plní služba `window` priamo v scéne (model wins);
-- logika model scény nevidí (číta iba to, čo sama zapísala), preto si drží vlastnú kópiu cez sys.watch —
-- režim okien je z latte/windows.lua (~/.local/state/latteos/window-mode) a prepína sa cez hyprctl eval —
-- to isté, čo robí lišta Noctalie.

local state = nil        -- ~/.local/state/latteos/window-mode (sandbox nemá os.getenv → printenv HOME)
local order = { plavajuce = 0, dlazdice = 1, paska = 2 }
local mode = "plavajuce"

local function read_mode()
    if not state then return end
    run("cat", { state }, function(out)
        local m = (out or ""):match("%a+")
        if m and order[m] then mode = m; fact.mode = m end
    end)
end

-- rovnaký zdroj a poradie ako model wins v scéne (hrbolček k = okno k)
local wins = {}
local layout   -- nižšie
local mon = nil  -- monitor (rozmery; plní hyprctl -j monitors nižšie)
local hidden, hidden_n = {}, 0  -- okná na skrytej ploche special:minimized (index v wins → true), mark_hidden

-- ── strapce okien (ikry) ──────────────────────────────────────────────────────
-- Okná tej istej aplikácie sa zlepia do strapca: prvé sedí pri lište, ďalšie sa lepia smerom od nej (ako ikry),
-- „náhodne“, ale pre každé poradie rovnako, aby strapec pri prekreslení neskákal. Čím viac okien, tým menšie
-- guľôčky (do 72 %, aby sa dali trafiť myšou). Myš nad strapcom ho rozvinie do radu v plnej veľkosti; keď
-- aktívne okno siaha k lište (fact.tight), všetko sa zrovná do jedného radu v páse.
local R0 = 29
local OFFS = { { 0, 0 }, { 1.72, -0.42 }, { 0.78, -1.62 }, { -0.98, -1.3 }, { 2.28, -1.86 },
               { 0.02, -3.0 }, { 1.62, -3.12 }, { -1.25, -2.85 }, { 2.9, -3.0 }, { 0.85, -4.2 },
               { -0.6, -4.3 }, { 2.2, -4.3 }, { 3.4, -1.1 }, { 0.1, -5.4 }, { 1.55, -5.5 },
               { -1.3, -5.2 }, { 3.1, -4.4 }, { -1.9, -1.9 }, { 0.8, -6.6 }, { 2.4, -6.4 } }
local JIT = { { 0, 0 }, { 0.06, -0.04 }, { -0.05, 0.07 }, { 0.08, 0.03 }, { -0.07, -0.05 },
              { 0.05, 0.06 }, { -0.04, 0.05 }, { 0.07, -0.06 }, { -0.06, 0.04 }, { 0.04, -0.07 },
              { 0.03, 0.05 }, { -0.05, -0.03 }, { 0.06, 0.02 }, { -0.03, -0.06 }, { 0.05, 0.04 },
              { -0.06, 0.03 }, { 0.02, -0.05 }, { 0.04, 0.06 }, { -0.04, -0.04 }, { 0.06, -0.02 } }
-- guľôčok v lište je najviac SLOTS (musí sedieť so session/kvapky/sloty.py); pri viac oknách je posledná guľôčka
-- „ďalšie okná“ a otvorí prehľad všetkých okien (Super+Tab), takže žiadne okno neostane nedostupné
local SLOTS = 48
-- okná nad lištou (30. 9., návrh používateľa): každé ako úsek pozdĺž okraja v súradniciach od hlavy { a0, a1, gap }
-- (gap = voľno medzi oknom a okrajom). Strapec sa nezrovnáva podľa hocijakého okna na ploche, iba podľa okien
-- priamo nad sebou: kým tam okno nie je, zhromaždí sa do výšky; keby okno prekryl, stiahne sa k okraju do radu.
local blocks = {}
local low_was = {}                        -- kľúč strapca → bol naposledy stiahnutý (hysterézia, aby neblikal)
local function free_above(x0, x1)
    local g = 999
    for _, b in ipairs(blocks) do
        if b.a1 > x0 and b.a0 < x1 then g = math.min(g, b.gap) end
    end
    return g
end
local function overflow() return #wins > SLOTS end
local ZIG = { 0, 0.46, 0.12, 0.52, 0.04, 0.38, 0.18, 0.5 }   -- cik-cak strapca v páse pod oknom (násobky r)
local hot = nil          -- aplikácia, ktorej strapec je pod myšou (rozvinutý)
local hot_gen = 0

-- okno → aplikácia (súbor .desktop zo služby `apps`): skupina strapca a ikona. Aplikácie LatteOS sú zatiaľ všetky
-- „org.quickshell“ → podľa titulku („Súbory — LatteOS“ = Name spúšťača); ostatné podľa StartupWMClass, id
-- spúšťača alebo jeho koncovky (Flatpak: trieda „firefox“, id „org.mozilla.firefox“)
local apps_by = { wm = {}, id = {}, tail = {}, name = {} }
local function index_apps(list)
    apps_by = { wm = {}, id = {}, tail = {}, name = {} }
    for _, a in ipairs(list or {}) do
        if a.wmclass and a.wmclass ~= "" then apps_by.wm[a.wmclass:lower()] = a end
        if a.id then
            apps_by.id[a.id:lower()] = a
            apps_by.tail[(a.id:match("([^%.]+)$") or a.id):lower()] = apps_by.tail[(a.id:match("([^%.]+)$") or a.id):lower()] or a
        end
        if a.name then apps_by.name[a.name:lower()] = apps_by.name[a.name:lower()] or a end
    end
end
local function app_of(w)
    local c = (w.class or ""):lower()
    if c == "org.quickshell" then
        local t = ((w.title or ""):match("^(.-) — ") or w.title or ""):lower()
        return apps_by.name[t]
    end
    return apps_by.wm[c] or apps_by.id[c] or apps_by.tail[c] or apps_by.name[c]
end
local function group_key(w)
    local a = app_of(w)
    if a then return "app:" .. (a.id or a.name) end
    local c = w.class or ""
    if c == "org.quickshell" then return "latte:" .. ((w.title or ""):match("^(.-) — ") or w.title or "") end
    return c
end
local function icon_of(w)
    local a = app_of(w)
    return (a and a.icon and a.icon ~= "") and a.icon or (w.class or "")
end

-- poradie aplikácií v lište, ktoré si používateľ nastavil ťahaním (kľúče skupín); ostatné podľa prvého okna
local group_order = {}
local last_spans = {}                    -- kľúč → stred strapca (x od hlavy), pre pustenie guľôčky

function layout()
    local groups, first = {}, {}
    for i, w in ipairs(wins) do
        if i > SLOTS then break end
        local k = (overflow() and i == SLOTS) and "~viac" or group_key(w)
        if not groups[k] then groups[k] = {}; first[#first + 1] = k end
        table.insert(groups[k], i)
    end
    local order, used = {}, {}
    for _, k in ipairs(group_order) do if groups[k] and not used[k] then order[#order + 1] = k; used[k] = true end end
    for _, k in ipairs(first) do if not used[k] then order[#order + 1] = k; used[k] = true end end
    local paska = tostring(fact.mode) == "paska"
    local lay, u = {}, 21                  -- u: ľavý okraj ďalšieho strapca (od hlavy; hlava končí na +36)
    for _, key in ipairs(order) do
        local idx = groups[key]
        local m = #idx
        local r = (paska and 24 or R0) * math.max(0.72, 1 - 0.07 * (m - 1))
        -- strapec: šírka a výška, ktorú by zabral; nad ním musí byť voľno (inak sa stiahne k okraju do radu)
        local lo, hi, top = 0, 0, 0
        for j = 1, math.min(m, #OFFS) do
            local ox = OFFS[j][1] + JIT[j][1]
            lo = math.min(lo, ox); hi = math.max(hi, ox); top = math.max(top, -(OFFS[j][2] + JIT[j][2]))
        end
        local need = top * r + r + 56 + (low_was[key] and 16 or 0)
        local tight = m > 1 and free_above(u, u + (hi - lo) * r + 2 * r) < need
        low_was[key] = tight
        local row = tight or m == 1 or key == hot or m > #OFFS    -- nad 20 okien jednej aplikácie rad, nie veža
        if key == hot and not tight then r = paska and 24 or R0 end
        if tight then r = math.min(r, 23) end
        if row and tight and m > 1 then
            -- pod oknom: strapec využije pás po spodok okna, nepravidelne (cik-cak), bez prekrytia okna
            local step = r * 1.45
            local ax = u + r
            for j, i in ipairs(idx) do
                local x = u + r + (j - 1) * step
                lay[i] = { x = x, y = -ZIG[((j - 1) % #ZIG) + 1] * r, r = r * (1 + 0.05 * (((j - 1) * 37) % 5 - 2) / 2), icon = icon_of(wins[i]), ax = ax, ay = 0 }
            end
            u = u + 2 * r + (m - 1) * step + 12
        elseif row then
            local step = r * 1.86
            for j, i in ipairs(idx) do
                local x = u + r + (j - 1) * step
                lay[i] = { x = x, y = 0, r = r, icon = icon_of(wins[i]), ax = x, ay = 0 }
            end
            u = u + 2 * r + (m - 1) * step + 12
        else
            local ax = u + r - lo * r
            for j, i in ipairs(idx) do
                local rr = r * (1 + 0.06 * (((j - 1) * 37) % 5 - 2) / 2)
                local x, y = ax + (OFFS[j][1] + JIT[j][1]) * r, (OFFS[j][2] + JIT[j][2]) * r
                lay[i] = { x = x, y = y, r = rr, icon = icon_of(wins[i]), ax = ax, ay = 0 }
            end
            u = ax + hi * r + r + 12
        end
    end
    -- veľa okien: šnúra sa musí zmestiť po kraj obrazovky (lišta rastie od hlavy doprava) — všetky guľôčky sa
    -- zmenšia a priblížia rovnakým pomerom (čím viac ikier, tým menšie; goo ich pri tom zlieva)
    if mon then
        local side = tostring(fact.side or "dole")
        local len = (side == "vlavo" or side == "vpravo") and mon.height or mon.width
        local avail = len * (1 - (tonumber(fact.pos) or 0.4)) - 24
        local lim = widget_limit and widget_limit(side, len)
        local head = len * (tonumber(fact.pos) or 0.4)
        if lim and lim > head + 120 then avail = math.min(avail, lim - head - 56) end
        if u > avail and u > 0 then
            local f = math.max(avail / u, 0.25)
            for _, e in pairs(lay) do e.x = e.x * f; e.ax = e.ax * f; e.y = e.y * math.max(f, 0.5); e.r = e.r * math.max(f, 0.5) end
            u = u * f
        end
    end
    if overflow() and lay[SLOTS] then          -- „ďalšie okná“ ostane plná guľôčka, aj keď sa ostatné zmenšili
        lay[SLOTS].icon = "preferences-system-windows"
        lay[SLOTS].r = math.max(lay[SLOTS].r, R0 * 0.8)
        lay[SLOTS].y = 0
    end
    for i, e in pairs(lay) do
        e.dim = hidden[i] and 1 or 0
        if hidden[i] then e.r = e.r * 0.84 end
    end
    model.lay = lay
    fact.chain_w = math.max(50, u - 12)
    last_spans = {}
    for _, key in ipairs(order) do
        local sx, n = 0, 0
        for _, i in ipairs(groups[key]) do sx = sx + (lay[i] and lay[i].x or 0); n = n + 1 end
        last_spans[#last_spans + 1] = { key = key, x = n > 0 and sx / n or 0 }
    end
end

sys.watch("window", function(v) wins = (v and v.list) or {}; layout() end)

-- guľôčka pustená po ťahaní: kde na lište (x od hlavy) → jej aplikácia sa presunie pred strapec, ktorý je tam
on("bead_drop", function(k)
    local w = wins[(k or 0) + 1]
    if not w or not mon then return end
    local key = group_key(w)
    run("hyprctl", { "-j", "cursorpos" }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if not ok or not c then return end
        local side = tostring(fact.side or "dole")
        local x, y = c.x - mon.x, c.y - mon.y
        local u = ({ dole = x, hore = mon.width - x, vlavo = y, vpravo = mon.height - y })[side] or x
        local len = (side == "vlavo" or side == "vpravo") and mon.height or mon.width
        local rel = u - len * (tonumber(fact.pos) or 0.4)
        local keys = {}
        for _, sp in ipairs(last_spans) do if sp.key ~= key then keys[#keys + 1] = sp end end
        local at = #keys + 1
        for i, sp in ipairs(keys) do if rel < sp.x then at = i; break end end
        local new = {}
        for i, sp in ipairs(keys) do
            if i == at then new[#new + 1] = key end
            new[#new + 1] = sp.key
        end
        if at > #keys then new[#new + 1] = key end
        group_order = new
        layout()
    end)
end)
on("fact:tight", function() layout() end)
on("fact:mode", function() layout() end)
on("fact:pos", function() layout() end)     -- šnúra sa zmestí po kraj podľa miesta hlavy
on("fact:side", function() layout() end)
on("hover", function(k)
    local w = wins[(k or 0) + 1]
    hot_gen = hot_gen + 1
    local key = w and group_key(w)
    if key ~= hot then hot = key; layout() end
end)
-- myš odišla z guľôčky: strapec sa zbalí až po chvíli (medzi rozvinutými guľôčkami sú medzery)
on("unhover", function()
    hot_gen = hot_gen + 1
    local mine = hot_gen
    after(500, function() if mine == hot_gen and hot then hot = nil; layout() end end)
end)

on("cycle", function()
    run("hyprctl", { "eval", 'require("latte.windows").cycle()' }, function() after(250, read_mode) end)
end)

-- hrbolček s oknom, ľavý klik: ako vo Windows — neaktívne okno sa ukáže, aktívne sa minimalizuje.
-- Minimalizuje LatteOS (plocha special:minimized, latte/bars.lua), nie protokol: Hyprland žiadosť o minimalizáciu
-- z wlr-foreign-toplevel ignoruje. Okno sa hľadá podľa triedy a titulku (adresy Hyprlandu zoznam nemá).
-- koľké okno s tou istou triedou a titulkom je okno i (terminály majú často rovnaký titulok „~“)
local function nth_of(i)
    local w, n = wins[i], 0
    for j = 1, i do
        local o = wins[j]
        if o and o.class == w.class and o.title == w.title then n = n + 1 end
    end
    return n
end
local function win_eval(fn, i)
    local w = wins[i]
    run("hyprctl", { "eval", string.format("latte.win.%s(%q, %q, %d)", fn, w.class or "", w.title or "", nth_of(i)) })
end
on("pick", function(k)
    local i = (k or 0) + 1
    if overflow() and i == SLOTS then
        run("noctalia", { "msg", "panel-toggle", "latteos/overview:panel" })
        return
    end
    if wins[i] then win_eval("toggle_by", i) end
end)

-- pravý klik: ponuka okna (apps/ponuka.qml) pri kurzore, pre to okno (najprv dostane fokus)
on("win_menu", function(k)
    local i = (k or 0) + 1
    if not wins[i] or (overflow() and i == SLOTS) then return end
    win_eval("focus_by", i)
    -- poloha ponuky = kurzor v čase kliku, priamo od Hyprlandu (JSON); fakty scény sem prišli neskoro (ponuka vľavo hore)
    run("hyprctl", { "-j", "cursorpos" }, function(out)
        local ok, c = pcall(json.decode, out or "")
        local x = (ok and c and c.x) or math.floor(fact["menu.x"] or 0)
        local y = (ok and c and c.y) or math.floor(fact["menu.y"] or 0)
        after(120, function() run("latte-ponuka", { "okno", tostring(math.floor(x)), tostring(math.floor(y)) }) end)
    end)
end)

-- koliesko nad lištou: páska = plynulý posun pásky, plávajúce = ďalšie/predošlé okno ako Alt+Tab, dlaždice = nič;
-- minimalizované okná (mimo pásky) vynechá — sú iba v lište, stlmené
on("wheel_turn", function(d)
    local dir = (d or 0) > 0 and 1 or -1
    -- páska sa hýbe ako fyzická páska (ako v niri): každý zúbok ju plynulo posunie o štvrť obrazovky, fokus dostane
    -- okno v strede. Pohyb okien animuje Hyprland (latte.tape_motion ho nechá zapnutý aj pri téme bez efektov)
    if mode == "paska" then
        local px = math.floor(((mon and mon.width) or 1920) * 0.25)
        run("hyprctl", { "eval", string.format('hl.dispatch(hl.dsp.layout("move %s%d"))', dir > 0 and "-" or "+", px) })
    elseif mode == "plavajuce" then
        -- ďalšie okno na aktuálnej ploche (latte/bars.lua) — nie cez Wayland: prepnutie na minimalizované okno
        -- ukázalo celú skrytú plochu special:minimized a nové okná sa potom otvárali na nej
        run("hyprctl", { "eval", "latte.win.cycle(" .. dir .. ")" })
    end
end)

on("start_open", function() run("latte-spustac", { "prepni" }) end)
-- ponuka Vypnúť (vyteká z kvapky vypínača): akcie relácie robí Noctalia, rovnako ako ponuka LatteOS (ponuka.qml)
local POWER = { "lock", "logout", "suspend", "reboot", "shutdown" }
on("power_do", function(k)
    fact.pmenu = false
    local a = POWER[(k or 0) + 1]
    if a then after(200, function() run("noctalia", { "msg", "session", a }) end) end
end)

-- okraj lišty: po presune (drag & drop) si ho zapamätá latte-kvapky okraj (a v ploche Kvapky nechá okná
-- uhnúť na tej strane); pri štarte sa vráti posledný
on("side_moved", function()
    run("latte-kvapky", { "okraj", tostring(fact.side), string.format("%.3f", fact.pos or 0.4) })
end)
run("latte-kvapky", { "okraj" }, function(out)
    local side, pos = (out or ""):match("^(%a+)%s+([%d.]+)")
    if side == "dole" or side == "hore" or side == "vlavo" or side == "vpravo" then
        fact.side = side
        fact.pos = tonumber(pos) or 0.4
    end
end)

-- tesne: aktívne okno siaha k okraju lišty (maximalizované, na celú obrazovku, dlaždice/páska) → kvapka ostane
-- v páse 64 px (+ rezerva), aby neprekryla program. Okraj podľa fact.side, rozmery monitora z hyprctl.
run("hyprctl", { "-j", "monitors" }, function(out)
    local ok, ms = pcall(json.decode, out or "")
    if ok and ms then for _, m in ipairs(ms) do if m.focused then mon = m end end end
end)
-- minimalizované okná (na skrytej ploche special:minimized) sú v lište stlmené a menšie — koliesko ich
-- vynecháva, klik ich vráti. Priradenie cez triedu, titulok a poradie (nth_of), ako pri kliku.
local function mark_hidden(list)
    local new, changed = {}, false
    for i, w in ipairs(wins) do
        local want, seen = nth_of(i), 0
        for _, c in ipairs(list) do
            if c.class == w.class and c.title == w.title then
                seen = seen + 1
                if seen == want then
                    new[i] = c.workspace and tostring(c.workspace.name or ""):find("^special:minimized") ~= nil
                    break
                end
            end
        end
        if (new[i] or false) ~= (hidden[i] or false) then changed = true end
    end
    if #wins ~= hidden_n then changed = true end
    hidden, hidden_n = new, #wins
    if changed then layout() end
end

local function check_tight()
    -- ktorékoľvek viditeľné okno na aktuálnej ploche (nielen aktívne — v Dlaždiciach siahajú k lište všetky)
    run("hyprctl", { "-j", "activeworkspace" }, function(wout)
        local okw, ws = pcall(json.decode, wout or "")
        run("hyprctl", { "-j", "clients" }, function(out)
            local ok, list = pcall(json.decode, out or "")
            local tight, room = false, 999
            local nb = {}
            if ok and list and okw and ws and mon then
                local side = tostring(fact.side or "dole")
                local W, H = mon.width, mon.height
                local head = ((side == "vlavo" or side == "vpravo") and H or W) * (tonumber(fact.pos) or 0.4)
                for _, w in ipairs(list) do
                    if w.workspace and w.workspace.id == ws.id and w.mapped ~= false and not w.hidden and w.at and w.size then
                        local x, y, ww, wh = w.at[1] - mon.x, w.at[2] - mon.y, w.size[1], w.size[2]
                        local gap = ({ dole = H - (y + wh), hore = y, vlavo = x, vpravo = W - (x + ww) })[side] or 999
                        if (w.fullscreen or 0) ~= 0 then gap = 0 end
                        local a0 = ({ dole = x, hore = W - x - ww, vlavo = y, vpravo = H - y - wh })[side] or x
                        local a1 = a0 + (((side == "vlavo" or side == "vpravo") and wh) or ww)
                        nb[#nb + 1] = { a0 = a0 - head, a1 = a1 - head, gap = gap }
                    end
                end
                -- lišta sa vysúva iba po okná nad sebou (Hodiny a vypínač vľavo od hlavy, šnúra vpravo)
                for _, b in ipairs(nb) do
                    if b.a1 > -190 and b.a0 < (fact.chain_w or 50) + 50 then room = math.min(room, b.gap) end
                end
                tight = room < 64 + 16
            end
            local changed = #nb ~= #blocks
            for i, b in ipairs(nb) do
                local o = blocks[i]
                if not o or math.abs(o.a0 - b.a0) > 8 or math.abs(o.a1 - b.a1) > 8 or math.abs(o.gap - b.gap) > 8 then changed = true end
            end
            blocks = nb
            if changed then layout() end
            if ok and list then mark_hidden(list) end
            if fact.tight ~= tight then fact.tight = tight end
            room = math.floor(math.max(0, room))
            if fact.room ~= room then fact.room = room end
        end)
    end)
end
every(700, check_tight)

-- ── upozornenia (iba v ploche Kvapky) ───────────────────────────────────────────
-- pleamar je vtedy server org.freedesktop.Notifications (v klasickej ploche ich má Noctalia — nepreberať).
-- Centrum si ich drží, kým ich niekto nezavrie (notifications.keep). Nové: kvapka padne do Hodín a bublina ukáže
-- „aplikácia · nadpis“.
local seen, first_report = {}, true
local URG = { low = 0, normal = 1, critical = 2 }
local function urgency(u)
    if type(u) == "number" then return math.max(0, math.min(2, u)) end
    return URG[tostring(u or "normal")] or 1
end
local function watch_notes()
    pcall(sys.call, "notifications.keep", true)
    sys.watch("notifications", function(list)
        list = list or {}
        local out, fresh = {}, nil
        for _, n in ipairs(list) do
            out[#out + 1] = { id = n.id, app = n.app or "", title = n.title or "", body = n.body or "", urgency = urgency(n.urgency) }
            if not seen[n.id] then
                seen[n.id] = true
                fresh = fresh or n
            end
        end
        model.notes = out
        if fresh and not first_report then
            text.toast = (fresh.app ~= "" and (fresh.app .. " · ") or "") .. (fresh.title or "")
            emit("new_note")
        end
        first_report = false
    end)
end

-- ── spúšťač (vyteká z hodiniek: ľavý klik alebo kláves Win) ─────────────────────────────────────────────
-- Hľadanie v aplikáciách (služba apps), súboroch (fd), na webe (predvolený vyhľadávač) a otázka pre AI (webové
-- čety, ktoré vezmú otázku z adresy); záložky s obľúbenými aplikáciami, ktoré si používateľ pomenuje sám.
-- Nastavenia: ~/.config/latteos/spustac.json (logika nevie zapisovať súbory → `latte-kvapky uloz spustac`).
local ENGINES = {
    { id = "google", name = "Google", url = "https://www.google.com/search?q=%s" },
    { id = "bing", name = "Bing", url = "https://www.bing.com/search?q=%s" },
    { id = "duckduckgo", name = "DuckDuckGo", url = "https://duckduckgo.com/?q=%s" },
    { id = "startpage", name = "Startpage", url = "https://www.startpage.com/do/search?q=%s" },
    { id = "ecosia", name = "Ecosia", url = "https://www.ecosia.org/search?q=%s" },
    { id = "brave", name = "Brave Search", url = "https://search.brave.com/search?q=%s" },
}
-- čety, ktoré otázku prevezmú z adresy (?q=); Gemini to nevie, preto tu nie je
local AIS = {
    { id = "chatgpt", name = "ChatGPT", url = "https://chatgpt.com/?q=%s" },
    { id = "claude", name = "Claude", url = "https://claude.ai/new?q=%s" },
    { id = "perplexity", name = "Perplexity", url = "https://www.perplexity.ai/search?q=%s" },
    { id = "copilot", name = "Copilot", url = "https://copilot.microsoft.com/?q=%s" },
    { id = "mistral", name = "Le Chat", url = "https://chat.mistral.ai/chat?q=%s" },
    { id = "google-ai", name = "Google AI", url = "https://www.google.com/search?udm=50&q=%s" },
}
local HOME = nil                                    -- domovský priečinok (printenv, nižšie)
local MAX_TABS = 4                                 -- používateľove záložky (+ Hľadať = 5 v scéne)
local apps, by_id = {}, {}
local cfg = { engine = "google", ai = { chatgpt = true, claude = true, perplexity = true }, tabs = {} }
local cfg_file = nil
local pin_ids = { "latteos-subory", "org.mozilla.firefox", "latteos-nastavenia", "latteos-aplikacie" }
local hits, file_hits, favs = {}, {}, {}
local renaming_tab = nil
local ctx_actions = {}

local function fill(s, vars) return (s:gsub("{(%w+)}", function(k) return vars[k] or "" end)) end
local function urlencode(s)
    return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end
local function engine() for _, e in ipairs(ENGINES) do if e.id == cfg.engine then return e end end return ENGINES[1] end

local function save_cfg()
    run("latte-kvapky", { "uloz", "spustac", json.encode(cfg) })
end

-- ── záložky a obľúbené ──
local function paint_tabs()
    local out = { { name = tr("Search") } }
    for _, t in ipairs(cfg.tabs) do out[#out + 1] = { name = t.name } end
    model.tabs = out
    if (tonumber(fact.tab) or 0) > #cfg.tabs then fact.tab = 0 end
end
local function paint_favs()
    favs = {}
    local out = {}
    local t = cfg.tabs[tonumber(fact.tab) or 0]
    if t then
        for _, id in ipairs(t.apps or {}) do
            local a = by_id[id]
            if a and #favs < 18 then favs[#favs + 1] = a; out[#out + 1] = { name = a.name, icon = a.icon } end
        end
    end
    model.favs = out
end

-- ── hľadanie ──
local function paint_hits()
    local q = text.query or ""
    local ql = q:lower()
    hits = {}
    if ql ~= "" then
        local starts, inside = {}, {}
        for _, a in ipairs(apps) do
            local n = (a.name or ""):lower()
            if n:sub(1, #ql) == ql then starts[#starts + 1] = a
            elseif n:find(ql, 1, true) then inside[#inside + 1] = a end
        end
        for _, list in ipairs({ starts, inside }) do
            for _, a in ipairs(list) do
                if #hits < 4 then hits[#hits + 1] = { kind = "app", name = a.name, sub = tr("Application"), icon = a.icon, app = a } end
            end
        end
        -- kvapky widgetov: napíš napr. „hlas“ → Hlasitosť; klik ju pridá na okraj (alebo odoberie)
        for _, w in ipairs(widget_rows(ql)) do
            if #hits < 6 then
                hits[#hits + 1] = { kind = "wdg", name = w.name, sub = w.on and tr("Drop · shown") or tr("Drop"), icon = w.icon, id = w.id }
            end
        end
        for _, f in ipairs(file_hits) do
            if #hits < 7 then
                local name = f.path:match("([^/]+)/?$") or f.path
                local where = f.path:gsub("^" .. (HOME or "~"):gsub("%p", "%%%0"), "~")
                hits[#hits + 1] = { kind = "file", name = name .. "   " .. where, sub = f.dir and tr("Folder") or tr("File"),
                                    icon = f.dir and "folder" or "text-x-generic", path = f.path }
            end
        end
        local e = engine()
        hits[#hits + 1] = { kind = "web", name = fill(tr("Search the web: {q}"), { q = q }), sub = e.name,
                            icon = "internet-web-browser", url = e.url:format(urlencode(q)) }
        for _, ai in ipairs(AIS) do
            if cfg.ai[ai.id] and #hits < 11 then
                hits[#hits + 1] = { kind = "ai", name = fill(tr("Ask {ai}: {q}"), { ai = ai.name, q = q }), sub = tr("AI"),
                                    icon = "dialog-question", url = ai.url:format(urlencode(q)) }
            end
        end
    end
    local out = {}
    for _, h in ipairs(hits) do out[#out + 1] = { name = h.name, sub = h.sub, icon = h.icon } end
    model.hits = out
    if (tonumber(fact.sel) or 0) >= #hits then fact.sel = 0 end
end

local fd_gen = 0
local function search()
    if fact.renaming then fact.typing = false; return end
    local q = text.query or ""
    fact.typing = q ~= ""
    if q ~= "" and (tonumber(fact.tab) or 0) > 0 then fact.tab = 0 end   -- písanie v záložke = hľadanie
    fact.sel = 0
    file_hits = {}
    paint_hits()
    -- súbory: fd po krátkej pauze v písaní (nie po každom písmene), iba ak je čo hľadať
    fd_gen = fd_gen + 1
    local gen = fd_gen
    if #q >= 2 and HOME then
        after(220, function()
            if gen ~= fd_gen then return end
            run("fd", { "--ignore-case", "--max-results", "3", "--max-depth", "6", "--absolute-path", "--", q, HOME }, function(out)
                if gen ~= fd_gen then return end
                file_hits = {}
                for line in (out or ""):gmatch("[^\n]+") do
                    file_hits[#file_hits + 1] = { path = line:gsub("/$", ""), dir = line:sub(-1) == "/" }
                end
                paint_hits()
            end)
        end)
    end
end
on("text:query", search)
on("sel_move", function(d)
    if #hits == 0 then return end
    fact.sel = math.max(0, math.min(#hits - 1, (tonumber(fact.sel) or 0) + (tonumber(d) or 0)))
end)

local function launch(a)
    if a and a.exec then pcall(sys.call, "apps.launch", a.exec) end
    fact.dash = false
end
local function open_hit(i)
    local h = hits[(i or 0) + 1]
    if not h then return end
    if h.kind == "wdg" then widget_toggle(h.id); paint_hits(); return end
    if h.kind == "app" then launch(h.app)
    elseif h.kind == "file" then run("xdg-open", { h.path }); fact.dash = false
    else run("xdg-open", { h.url }); fact.dash = false end
end
on("open_hit", open_hit)
on("fav_open", function(i) launch(favs[(i or 0) + 1]) end)

-- ── premenovanie záložky: pole hľadania slúži ako názov (Enter uloží, Esc zruší) ──
local function start_rename(t)
    renaming_tab = t
    fact.renaming = true
    fact.typing = false
    text.query = cfg.tabs[t].name
    focus("query")
end
on("query_submit", function(v)
    if fact.renaming then
        local name = (text.query or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if (tonumber(v) or 1) > 0 and renaming_tab and cfg.tabs[renaming_tab] and name ~= "" then
            cfg.tabs[renaming_tab].name = name
            save_cfg()
        end
        renaming_tab = nil
        fact.renaming = false
        text.query = ""
        paint_tabs()
        return
    end
    open_hit(tonumber(fact.sel) or 0)
end)
on("tab_pick", function(k)
    if fact.renaming then renaming_tab = nil; fact.renaming = false; text.query = "" end
    paint_favs()
    if (tonumber(k) or 0) == 0 then focus("query") end
end)
on("tab_add", function()
    if #cfg.tabs >= MAX_TABS then return end
    cfg.tabs[#cfg.tabs + 1] = { name = tr("New tab"), apps = {} }
    save_cfg(); paint_tabs()
    fact.tab = #cfg.tabs
    paint_favs()
    start_rename(#cfg.tabs)
end)
on("fact:dash", function(open)
    if not open then
        renaming_tab = nil; fact.renaming = false; text.query = ""; fact.ctx_open = false
    end
end)

-- ── kontextové ponuky (pravý klik): položky { label, on, run } ──
local function menu(items)
    ctx_actions = {}
    local out = {}
    for i, it in ipairs(items) do
        if i > 10 then break end
        out[#out + 1] = { label = it.label, on = it.on and 1 or 0, off = it.off == true }
        ctx_actions[#ctx_actions + 1] = it.run
    end
    model.ctx = out
    fact.ctx_hot = -1
    fact.ctx_open = #out > 0
end
on("ctx_pick", function(k) local f = ctx_actions[(k or 0) + 1]; if f then f() end end)
local function has(list, id) for i, v in ipairs(list) do if v == id then return i end end return nil end
local function move(list, i, d)
    local j = i + d
    if j < 1 or j > #list then return end
    list[i], list[j] = list[j], list[i]
end
on("hit_menu", function(k)
    local h = hits[(k or 0) + 1]
    if not h then return end
    local items = {}
    if h.kind == "app" then
        for _, t in ipairs(cfg.tabs) do
            local id = h.app.id
            items[#items + 1] = { label = fill(tr("Add to “{tab}”"), { tab = t.name }), on = has(t.apps, id) ~= nil, run = function()
                local at = has(t.apps, id)
                if at then table.remove(t.apps, at) else t.apps[#t.apps + 1] = id end
                save_cfg(); paint_favs()
            end }
        end
    elseif h.kind == "file" then
        items[#items + 1] = { label = tr("Open containing folder"), run = function()
            run("xdg-open", { h.path:match("^(.*)/[^/]*$") or h.path }); fact.dash = false
        end }
    elseif h.kind == "web" then
        for _, e in ipairs(ENGINES) do
            items[#items + 1] = { label = fill(tr("Search engine: {name}"), { name = e.name }), on = e.id == cfg.engine, run = function()
                cfg.engine = e.id; save_cfg(); paint_hits()
            end }
        end
    elseif h.kind == "ai" then
        for _, ai in ipairs(AIS) do
            items[#items + 1] = { label = ai.name, on = cfg.ai[ai.id] == true, run = function()
                cfg.ai[ai.id] = not cfg.ai[ai.id] or nil; save_cfg(); paint_hits()
            end }
        end
    end
    menu(items)
end)
on("fav_menu", function(k)
    local t = cfg.tabs[tonumber(fact.tab) or 0]
    local a = favs[(k or 0) + 1]
    if not t or not a then return end
    local i = has(t.apps, a.id)
    menu({
        { label = tr("Remove from this tab"), run = function() if i then table.remove(t.apps, i) end; save_cfg(); paint_favs() end },
        { label = tr("Move left"), run = function() if i then move(t.apps, i, -1) end; save_cfg(); paint_favs() end },
        { label = tr("Move right"), run = function() if i then move(t.apps, i, 1) end; save_cfg(); paint_favs() end },
    })
end)
on("tab_menu", function(k)
    local i = tonumber(k) or 0
    if not cfg.tabs[i] then return end
    menu({
        { label = tr("Rename"), run = function() start_rename(i) end },
        { label = tr("Move left"), run = function() if i > 1 then move(cfg.tabs, i, -1); fact.tab = i - 1 end; save_cfg(); paint_tabs(); paint_favs() end },
        { label = tr("Move right"), run = function() if i < #cfg.tabs then move(cfg.tabs, i, 1); fact.tab = i + 1 end; save_cfg(); paint_tabs(); paint_favs() end },
        { label = tr("Delete tab"), run = function() table.remove(cfg.tabs, i); fact.tab = 0; save_cfg(); paint_tabs(); paint_favs() end },
    })
end)

-- nastavenia: zo súboru; prvý raz obľúbené z doterajších pripnutých (~/.config/latteos/pripnute) a prázdne Hry
local function load_cfg()
    if not cfg_file then return end
    run("cat", { cfg_file }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if ok and type(c) == "table" and type(c.tabs) == "table" then
            cfg.engine = c.engine or cfg.engine
            if type(c.ai) == "table" then cfg.ai = c.ai end
            cfg.tabs = {}
            for _, t in ipairs(c.tabs) do
                if type(t) == "table" and #cfg.tabs < MAX_TABS then
                    cfg.tabs[#cfg.tabs + 1] = { name = tostring(t.name or tr("New tab")), apps = type(t.apps) == "table" and t.apps or {} }
                end
            end
        else
            cfg.tabs = { { name = tr("Favorites"), apps = pin_ids }, { name = tr("Games"), apps = {} } }
            save_cfg()
        end
        paint_tabs(); paint_favs()
    end)
end

sys.watch("apps", function(list)
    apps = list or {}
    by_id = {}
    for _, a in ipairs(apps) do by_id[a.id] = a end
    index_apps(apps); paint_favs(); search(); layout()
end)

-- upozornenie v spúšťači: klik = otvoriť (predvolená akcia aplikácie) a zavrieť; „Vymazať všetko“
on("note_open", function(i)
    local n = (model.notes or {})[(i or 0) + 1]
    if not n then return end
    pcall(sys.call, "notifications.invoke", n.id, "default")
    pcall(sys.call, "notifications.dismiss", n.id)
end)
on("notes_clear", function() pcall(sys.call, "notifications.clear") end)

local function noctalia(...) run("noctalia", { "msg", ... }) end

-- ── kvapky widgetov (30. 9.): widgety Noctalie ako kvapky na okrajoch obrazovky ───────────────────────────────
-- Akcie myši presne podľa Noctalie (src/shell/bar/widget_gesture_defaults.cpp): kde Noctalia pravý klik nemá, nemá
-- ho ani kvapka. Vykonáva ich Noctalia (`noctalia msg …`), stav a ikonu dávajú služby pleamaru. Rozmiestnenie:
-- ~/.config/latteos/kvapky-widgety.json ({ list = { { id, side, pos } } }), ukladá `latte-kvapky uloz widgety`.
local WMAX = 12                                    -- musí sedieť so session/kvapky/widgety.py
local WIDGETS = {
    ["control-center"] = { name = "Control center", left = "panel-toggle control-center home" },
    volume = { name = "Volume", left = "panel-toggle control-center audio", right = "volume-mute", up = "volume-up", down = "volume-down" },
    network = { name = "Network", left = "panel-toggle control-center network", right = "network-toggle" },
    bluetooth = { name = "Bluetooth", left = "panel-toggle control-center bluetooth", right = "bluetooth-toggle" },
    battery = { name = "Battery", left = "panel-toggle control-center power" },
    media = { name = "Media", left = "panel-toggle control-center media", right = "media toggle", up = "media next", down = "media previous" },
    sysmon = { name = "System monitor", left = "panel-toggle control-center system" },
    weather = { name = "Weather", left = "panel-toggle control-center weather" },
    nightlight = { name = "Night light", left = "nightlight-toggle", right = "nightlight-force-toggle" },
    power_profile = { name = "Power profile", left = "power-cycle next", right = "power-cycle prev", up = "power-cycle next", down = "power-cycle prev" },
    caffeine = { name = "Keep awake", left = "caffeine-toggle" },
    keyboard_layout = { name = "Keyboard layout", left = "keyboard-layout-cycle" },
    clipboard = { name = "Clipboard", left = "panel-toggle clipboard" },
    screenshot = { name = "Screenshot", left = "screenshot-region" },
    wallpaper = { name = "Wallpaper", left = "panel-toggle wallpaper" },
    theme_mode = { name = "Light and dark", left = "theme-mode-toggle" },
}
local WORDER = { "control-center", "volume", "network", "bluetooth", "battery", "media", "sysmon", "weather", "nightlight",
                 "power_profile", "caffeine", "keyboard_layout", "clipboard", "screenshot", "wallpaper", "theme_mode" }
local STATIC_ICON = {
    ["control-center"] = "emblem-system-symbolic", sysmon = "utilities-system-monitor-symbolic",
    weather = "weather-few-clouds-symbolic", nightlight = "night-light-symbolic", power_profile = "power-profile-balanced-symbolic",
    caffeine = "preferences-desktop-screensaver-symbolic", keyboard_layout = "input-keyboard-symbolic",
    clipboard = "edit-paste-symbolic", screenshot = "applets-screenshooter-symbolic",
    wallpaper = "preferences-desktop-wallpaper-symbolic", theme_mode = "weather-clear-night-symbolic",
}
local wlist = {}                                  -- { { id, side, pos } } na obrazovke
local wfile = nil
local st = { snd = {}, net = {}, bt = {}, bat = {}, media = {}, cpu = nil, temp = nil }

local function wstate(id)
    -- ikona, hodnota, zapnuté
    if id == "volume" then
        local v, mu = tonumber(st.snd.volume) or 0, st.snd.muted
        local lvl = mu and "muted" or (v < 0.34 and "low" or (v < 0.67 and "medium" or "high"))
        return "audio-volume-" .. lvl .. "-symbolic", math.floor(v * 100 + 0.5) .. "%", not mu
    elseif id == "network" then
        local n = st.net
        if n.kind == "wired" then return "network-wired-symbolic", "", n.online ~= false end
        if n.kind == "wifi" then
            local s = tonumber(n.strength) or 0
            local q = s > 75 and "excellent" or (s > 50 and "good" or (s > 25 and "ok" or "weak"))
            return "network-wireless-signal-" .. q .. "-symbolic", "", true
        end
        return "network-offline-symbolic", "", false
    elseif id == "bluetooth" then
        local n = 0
        for _, d in ipairs(st.bt.devices or {}) do if d.connected then n = n + 1 end end
        return st.bt.powered and "bluetooth-active-symbolic" or "bluetooth-disabled-symbolic", n > 0 and tostring(n) or "", st.bt.powered == true
    elseif id == "battery" then
        local p = tonumber(st.bat.percent) or 0
        local lvl = math.floor(p / 10 + 0.5) * 10
        return "battery-level-" .. lvl .. (st.bat.charging and "-charging" or "") .. "-symbolic", math.floor(p + 0.5) .. "%", true
    elseif id == "media" then
        return st.media.playing and "media-playback-start-symbolic" or "media-playback-pause-symbolic", "", st.media.playing == true
    elseif id == "sysmon" then
        return STATIC_ICON.sysmon, st.cpu and (st.cpu .. "%") or "", true
    elseif id == "weather" then
        return STATIC_ICON.weather, st.temp and (st.temp .. "°") or "", true
    end
    return STATIC_ICON[id] or "emblem-system-symbolic", "", true
end
-- ikony programov na pozadí (systémová lišta, StatusNotifierItem — napr. Discord) sú kvapky tiež: ľavý klik aktivuje,
-- pravý ukáže ich ponuku (ako v Noctalii); miesto, kam ich používateľ odtiahol, si pamätá wlist („tray:ID“)
local tray = {}
local wshown = {}                                  -- čo je na obrazovke: { kind = "w" | "tray", entry, item }
local function tray_place(it)
    for _, w in ipairs(wlist) do if w.id == "tray:" .. it.id then return w end end
    return nil
end
local function free_pos()
    local pos = 0.95
    local taken = true
    while taken and pos > 0.4 do
        taken = false
        for _, e in ipairs(wshown) do
            if e.entry.side == 0 and math.abs(e.entry.pos - pos) < 0.025 then taken = true end
        end
        if taken then pos = pos - 0.03 end
    end
    return pos
end
local function wpaint()
    local out = {}
    wshown = {}
    for _, w in ipairs(wlist) do
        local d = WIDGETS[w.id]
        if d and #out < WMAX then
            local icon, val, on = wstate(w.id)
            wshown[#wshown + 1] = { kind = "w", entry = w }
            out[#out + 1] = { icon = icon, val = val, hasval = val ~= "", mono = true, side = w.side, pos = w.pos,
                              right = d.right ~= nil, wheel = d.up ~= nil, on = on }
        end
    end
    for _, it in ipairs(tray) do
        local w = tray_place(it)
        if not (w and w.hidden) and #out < WMAX then
            local e = w or { id = "tray:" .. it.id, side = 0, pos = free_pos(), auto = true }
            wshown[#wshown + 1] = { kind = "tray", entry = e, item = it }
            out[#out + 1] = { icon = it.icon or "", val = "", hasval = false, mono = false, side = e.side, pos = e.pos,
                              right = true, wheel = true, on = it.status ~= "Passive" }
        end
    end
    model.wdg = out
end
local function wsave() run("latte-kvapky", { "uloz", "widgety", json.encode({ list = wlist }) }) end
local function nmsg(action)
    local args = { "msg" }
    for word in action:gmatch("%S+") do args[#args + 1] = word end
    run("noctalia", args)
end
local function wnth(k) return wshown[(k or 0) + 1] end
-- panel Noctalie sa otvorí pri kvapke, ktorá ho volá (kvapky sa dajú presúvať): z miesta kvapky najbližšia z 9 polôh
-- Noctalie; zmena polohy sa zapíše do jej konfigurácie pre Kvapky (latte-kvapky panel-poloha) a až potom sa panel otvorí
local PANEL_KEY = { ["control-center"] = "control_center", clipboard = "clipboard", wallpaper = "wallpaper", session = "session" }
local panel_at = {}
local function near_pos(e)
    local third = function(p) return p < 0.34 and 1 or (p < 0.67 and 2 or 3) end
    local t = third(tonumber(e.pos) or 0.5)
    local side = tonumber(e.side) or 0
    if side == 0 then return ({ "bottom_left", "bottom_center", "bottom_right" })[t]
    elseif side == 1 then return ({ "top_left", "top_center", "top_right" })[t]
    elseif side == 2 then return ({ "top_left", "center_left", "bottom_left" })[t]
    else return ({ "top_right", "center_right", "bottom_right" })[t] end
end
local function waction(e, action)
    local panel = action:match("^panel%-toggle%s+(%S+)")
    local key = panel and PANEL_KEY[panel]
    if not key then nmsg(action); return end
    local want = near_pos(e.entry)
    if panel_at[key] == want then nmsg(action); return end
    panel_at[key] = want
    run("latte-kvapky", { "panel-poloha", key, want }, function() after(120, function() nmsg(action) end) end)
end
on("w_click", function(k)
    local e = wnth(k)
    if not e then return end
    if e.kind == "tray" then pcall(sys.call, "tray.activate", e.item.key) else waction(e, WIDGETS[e.entry.id].left) end
end)
-- ponuka ikony z lišty: strom (dbusmenu) ako naše kapsuly; položka s podponukou ju otvorí na tom istom mieste
local function tray_menu(key, nodes)
    local items = {}
    for _, n in ipairs(nodes or {}) do
        if not n.separator and (n.label or "") ~= "" then
            local label = (n.label or ""):gsub("_", "")
            local kids = n.children
            items[#items + 1] = { label = label .. ((kids and #kids > 0) and "  ›" or ""), on = n.checked == true, off = n.enabled == false,
                                  run = function()
                                      if n.enabled == false then return end
                                      if kids and #kids > 0 then tray_menu(key, kids)
                                      else pcall(sys.call, "tray.menu_click", key, n.id) end
                                  end }
        end
    end
    menu(items)
end
on("w_right", function(k)
    local e = wnth(k)
    if not e then return end
    if e.kind == "tray" then
        local ok, nodes = pcall(sys.ask, "tray.menu", e.item.key)
        if ok and type(nodes) == "table" and #nodes > 0 then tray_menu(e.item.key, nodes)
        else pcall(sys.call, "tray.context", e.item.key) end            -- program bez dbusmenu: svoju ponuku ukáže sám
    elseif WIDGETS[e.entry.id].right then waction(e, WIDGETS[e.entry.id].right) end
end)
on("w_wheel", function(code)
    code = tonumber(code) or 0
    local e = wnth(math.floor(code / 2))
    if not e then return end
    local up = code % 2 == 1
    if e.kind == "tray" then pcall(sys.call, "tray.scroll", e.item.key, up and 1 or -1); return end
    local d = WIDGETS[e.entry.id]
    local a = up and d.up or d.down
    if a then nmsg(a) end
end)
-- pustená kvapka: k najbližšiemu okraju; ďaleko od všetkých (nad 170 px) steká preč
on("w_drop", function(k)
    local e = wnth(k)
    if not e then return end
    local w = e.entry
    if e.kind == "tray" and w.auto then w.auto = nil; wlist[#wlist + 1] = w end   -- odteraz si miesto pamätá
    local i = nil
    for n, x in ipairs(wlist) do if x == w then i = n end end
    local x, y = tonumber(fact["wd.x"]) or 0, tonumber(fact["wd.y"]) or 0
    local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
    local d = { H - y, y, x, W - x }
    local side, best = 0, d[1]
    for s = 2, 4 do if d[s] < best then side, best = s - 1, d[s] end end
    if best > 170 then
        if e.kind == "tray" then w.hidden = true elseif i then table.remove(wlist, i) end
    else
        w.side = side
        w.pos = math.max(0.02, math.min(0.98, (side <= 1) and (x / W) or (y / H)))
    end
    wsave(); wpaint(); layout()
end)
-- pridať / odobrať zo spúšťača (riadok „Kvapka“)
function widget_toggle(id)
    if id:sub(1, 5) == "tray:" then
        for _, w in ipairs(wlist) do if w.id == id then w.hidden = not w.hidden or nil end end
        wsave(); wpaint(); layout(); return
    end
    for i, w in ipairs(wlist) do
        if w.id == id then table.remove(wlist, i); wsave(); wpaint(); layout(); return end
    end
    if #wlist >= WMAX then return end
    -- voľné miesto dole vpravo, od pravého kraja doľava
    local pos = 0.95
    local taken = true
    while taken and pos > 0.5 do
        taken = false
        for _, w in ipairs(wlist) do if w.side == 0 and math.abs(w.pos - pos) < 0.025 then taken = true end end
        if taken then pos = pos - 0.03 end
    end
    wlist[#wlist + 1] = { id = id, side = 0, pos = pos }
    wsave(); wpaint(); layout()
end
function widget_rows(q)
    local rows = {}
    for _, id in ipairs(WORDER) do
        local name = tr(WIDGETS[id].name)
        if name:lower():find(q, 1, true) or id:find(q, 1, true) then
            local on = false
            for _, w in ipairs(wlist) do if w.id == id then on = true end end
            rows[#rows + 1] = { id = id, name = name, on = on, icon = (wstate(id)) }
        end
    end
    for _, it in ipairs(tray) do
        local t = it.title or it.id or ""
        if t ~= "" and (t:lower():find(q, 1, true) or (it.id or ""):lower():find(q, 1, true)) then
            local w = tray_place(it)
            rows[#rows + 1] = { id = "tray:" .. it.id, name = t, on = not (w and w.hidden), icon = it.icon }
        end
    end
    return rows
end
-- najbližšia kvapka widgetu na tom istom okraji ako lišta (pozdĺž okraja, v px) — šnúra okien ju neprekryje
function widget_limit(side, len)
    local sid = ({ dole = 0, hore = 1, vlavo = 2, vpravo = 3 })[side] or 0
    local lim = nil
    for _, w in ipairs(wlist) do
        if w.side == sid then
            local u = (sid == 1 or sid == 3) and (1 - w.pos) * len or w.pos * len   -- hore a vpravo je lišta zrkadlená
            if not lim or u < lim then lim = u end
        end
    end
    return lim
end
local function wload()
    if not wfile then return end
    run("cat", { wfile }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if ok and type(c) == "table" and type(c.list) == "table" then
            wlist = {}
            for _, w in ipairs(c.list) do
                if type(w) == "table" and (WIDGETS[w.id] or tostring(w.id):sub(1, 5) == "tray:") and #wlist < 40 then
                    wlist[#wlist + 1] = { id = w.id, side = tonumber(w.side) or 0, pos = tonumber(w.pos) or 0.9, hidden = w.hidden == true or nil }
                end
            end
        else
            wlist = { { id = "control-center", side = 0, pos = 0.95 }, { id = "volume", side = 0, pos = 0.92 },
                      { id = "network", side = 0, pos = 0.89 } }
            if st.bt.present then wlist[#wlist + 1] = { id = "bluetooth", side = 0, pos = 0.86 } end
            wsave()
        end
        wpaint(); layout()
    end)
end
sys.watch("audio", function(v) st.snd = v or {}; wpaint() end)
sys.watch("network", function(v) st.net = v or {}; wpaint() end)
sys.watch("bluetooth", function(v) st.bt = v or {}; wpaint() end)
sys.watch("battery", function(v) st.bat = v or {}; wpaint() end)
sys.watch("media", function(v) st.media = v or {}; wpaint() end)
sys.watch("tray", function(list) tray = list or {}; wpaint() end)
-- vyťaženie CPU (kvapka Systém): z /proc/stat každé 3 s, iba keď tá kvapka je
local cpu_prev = nil
every(3000, function()
    local want = false
    for _, w in ipairs(wlist) do if w.id == "sysmon" then want = true end end
    if not want then return end
    run("cat", { "/proc/stat" }, function(out)
        local u, n, s, idle, io, irq, sirq = (out or ""):match("^cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
        if not u then return end
        local busy = u + n + s + irq + sirq
        local total = busy + idle + io
        if cpu_prev then
            local dt = total - cpu_prev[2]
            if dt > 0 then st.cpu = math.floor((busy - cpu_prev[1]) * 100 / dt + 0.5); wpaint() end
        end
        cpu_prev = { busy, total }
    end)
end)

-- počasie: Open-Meteo (bez kľúča), miesto z Nastavení › Účet › Prihlasovanie (greeter.conf), každých 20 min
local WX = { [0] = "☀", [1] = "🌤", [2] = "⛅", [3] = "☁", [45] = "🌫", [48] = "🌫", [95] = "⛈", [96] = "⛈", [99] = "⛈" }
local function wx_glyph(c)
    if WX[c] then return WX[c] end
    if (c >= 51 and c <= 67) or (c >= 80 and c <= 82) then return "🌧" end
    if (c >= 71 and c <= 77) or c == 85 or c == 86 then return "❄" end
    return "☁"
end
local function weather()
    run("cat", { "/var/lib/latteos/greeter/greeter.conf" }, function(conf)
        conf = conf or ""
        local lat = conf:match('lat%s*=%s*"([%d.-]+)"') or "48.74"
        local lon = conf:match('lon%s*=%s*"([%d.-]+)"') or "19.15"
        local place = conf:match('place%s*=%s*"([^"]*)"') or ""
        run("curl", { "-s", "-m", "8", "https://api.open-meteo.com/v1/forecast?latitude=" .. lat .. "&longitude=" .. lon
                      .. "&current=temperature_2m,weather_code" }, function(out)
            local ok, d = pcall(json.decode, out or "")
            if ok and d and d.current then
                local t = math.floor((d.current.temperature_2m or 0) + 0.5)
                st.temp = t; wpaint()
                text.weather = wx_glyph(d.current.weather_code or 3) .. "  " .. t .. " °C" .. (place ~= "" and (" · " .. place) or "")
            end
        end)
    end)
end

-- relácia LatteOS Kvapky (bez Noctalie): Hodiny, vypínač a upozornenia
run("printenv", { "LATTE_VARIANT" }, function(out)
    if (out or ""):match("kvapky") then fact.solo = true; watch_notes(); weather(); every(20 * 60 * 1000, weather) end
end)

-- káva v kvapkách (Barista / Nastavenia: ~/.config/latteos/kava): pomer vody a mlieka
local kavy = {
    espresso = { 0, 0 }, ristretto = { 0, 0 }, lungo = { 0.35, 0 }, americano = { 0.7, 0 },
    macchiato = { 0, 0.25 }, cortado = { 0, 0.4 }, flatwhite = { 0.05, 0.5 }, cappuccino = { 0, 0.55 },
    latte = { 0, 0.85 }, ["cierna-s-mliekom"] = { 0.4, 0.3 },
}
local kava_file = nil
local function read_kava()
    if not kava_file then return end
    run("cat", { kava_file }, function(out)
        local k = kavy[(out or ""):match("[%w-]+") or "espresso"] or kavy.espresso
        if fact.voda ~= k[1] then fact.voda = k[1] end
        if fact.mlieko ~= k[2] then fact.mlieko = k[2] end
    end)
end
run("printenv", { "HOME" }, function(out)
    local home = (out or ""):match("[^\n]+")
    if home then
        state = home .. "/.local/state/latteos/window-mode"; read_mode()
        kava_file = home .. "/.config/latteos/kava"; read_kava()
        HOME = home
        cfg_file = home .. "/.config/latteos/spustac.json"
        wfile = home .. "/.config/latteos/kvapky-widgety.json"
        after(600, wload)                                    -- po prvej správe služby bluetooth (predvolené)
        -- doterajšie pripnuté (~/.config/latteos/pripnute) sú pri prvom štarte obľúbené spúšťača
        run("cat", { home .. "/.config/latteos/pripnute" }, function(out)
            local ids = {}
            for line in (out or ""):gmatch("[^\n]+") do
                local id = line:match("^%s*([%w%.%-_]+)")
                if id then ids[#ids + 1] = id end
            end
            if #ids > 0 then pin_ids = ids end
            load_cfg()
        end)
    end
end)
every(2000, function() read_mode(); read_kava() end)   -- režim sa dá zmeniť aj inde (Super+W, Nastavenia)
