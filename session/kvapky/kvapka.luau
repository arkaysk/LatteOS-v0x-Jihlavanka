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
        -- rohová lišta Noctalie vpravo dole (latte-kvapky): šnúra okien sa zastaví pred ňou
        if side == "dole" and roh_len then
            local r = len - roh_len()
            if not lim or r < lim then lim = r end
        end
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

sys.watch("window", function(v) wins = (v and v.list) or {}; layout(); if qg_windows then qg_windows(wins) end end)

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
-- PowerGoo (1. 10.): 0 Nastavenia, 1 Monitor, potom Zamknúť … Vypnúť (akcie robí Noctalia)
on("power_do", function(k)
    fact.pmenu = false
    k = tonumber(k) or 0
    if k == 0 then run("latte-app", { "nastavenia" }); return end
    if k == 1 then run("latte-app", { "monitor" }); return end
    local a = POWER[k - 1]
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
        dn_paint(list)
        if fresh and not first_report then
            text.toast = (fresh.app ~= "" and (fresh.app .. " · ") or "") .. (fresh.title or "")
            emit("new_note")
        end
        first_report = false
    end)
    -- centrum upozornení (hrozno DaNoGoo): nevypršia samy; až po spustení služby, inak sa neuplatní
    pcall(sys.call, "notifications.keep", true)
end

-- ── spúšťač (1. 10., náčrt používateľa): vyteká z TimeGoo (ľavý klik alebo kláves Win) ────────────────────────
-- Pole s ikonou režimu — AI, aplikácie, súbory, web, Linux príkaz; pod ním obsah režimu; riadok režimu (záložky
-- obľúbených, služba a model AI, vyhľadávač…); úplne dole úzky riadok počasia. Prevzaté z klasického LatteOS: AI cez
-- `latte-ai` (Nastavenia › Softvér › AI: Ollama, domáci server, cloud s kľúčom, webové čety), kontrola nebezpečných
-- príkazov z Text Baru (plugin textbar/cmd.luau), terminál `latte-terminal`.
-- Nastavenia: ~/.config/latteos/spustac.json (logika nevie zapisovať súbory → `latte-kvapky uloz spustac`).
local ENGINES = {
    { id = "google", name = "Google", url = "https://www.google.com/search?q=%s" },
    { id = "bing", name = "Bing", url = "https://www.bing.com/search?q=%s" },
    { id = "duckduckgo", name = "DuckDuckGo", url = "https://duckduckgo.com/?q=%s" },
    { id = "startpage", name = "Startpage", url = "https://www.startpage.com/do/search?q=%s" },
    { id = "ecosia", name = "Ecosia", url = "https://www.ecosia.org/search?q=%s" },
    { id = "brave", name = "Brave Search", url = "https://search.brave.com/search?q=%s" },
}
-- ikony Tabler (písmo Noctalie) a poradie tém LatteOS — vygeneroval spustac.py
local IK = require("ikony")
local G = IK.glyph
-- režimy v poradí scény (fact smode)
local MODES = {
    { id = "ai", name = "AI", glyph = G.sparkles, hint = "Ask AI anything…" },
    { id = "apps", name = "Applications", glyph = G.search, hint = "Search apps…" },
    { id = "files", name = "Files", glyph = G.folder, hint = "Search files…" },
    { id = "web", name = "Web", glyph = G.world, hint = "Search the web…" },
    { id = "cmd", name = "Linux command", glyph = G["terminal-2"], hint = "Run a command…" },
}
local MAXH = 7                                      -- riadkov obsahu v scéne (model hits)
-- služby AI na výber (latte-ai set …); web = odpoveď v prehliadači s prihlásením, bez kľúča
local AI_PRESETS = {
    { name = "Claude (web)", provider = "web", key = "web", value = "claude" },
    { name = "ChatGPT (web)", provider = "web", key = "web", value = "chatgpt" },
    { name = "Perplexity (web)", provider = "web", key = "web", value = "perplexity" },
    { name = "Copilot (web)", provider = "web", key = "web", value = "copilot" },
    { name = "Ollama", provider = "lokalne" },
    { name = "Home server", provider = "domaci" },
    { name = "Claude (API key)", provider = "cloud", key = "cloud", value = "anthropic" },
    { name = "ChatGPT (API key)", provider = "cloud", key = "cloud", value = "openai" },
    { name = "Gemini (API key)", provider = "cloud", key = "cloud", value = "gemini" },
    { name = "Mistral (API key)", provider = "cloud", key = "cloud", value = "mistral" },
}
local HOME = nil                                    -- domovský priečinok (printenv, nižšie)
local MAX_TABS = 5
local apps, by_id = {}, {}
local cfg = { engine = "google", mode = 1, tabs = {}, cmds = {}, recent = {} }
local cfg_file = nil
local pin_ids = { "latteos-subory", "org.mozilla.firefox", "latteos-nastavenia", "latteos-aplikacie" }
local hits, file_hits, favs, places = {}, {}, {}, {}
local renaming_tab = nil
local ctx_actions = {}
local chip_do = {}                                  -- čip → { pick = fn, menu = fn }
local confirm_cmd = nil                             -- nebezpečný príkaz čaká na druhý Enter
local ai = {}                                       -- latte-ai status (provider, target, model, ok, web, disabled)
local conv = {}                                     -- rozhovor s AI, najstarší prvý: { role, content }
local paint_chips                                   -- (nižšie)

local function fill(s, vars) return (s:gsub("{(%w+)}", function(k) return vars[k] or "" end)) end
local function urlencode(s)
    return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end
local function engine() for _, e in ipairs(ENGINES) do if e.id == cfg.engine then return e end end return ENGINES[1] end
local function mode_id() return (MODES[(tonumber(fact.smode) or 1) + 1] or MODES[2]).id end
local function tilde(path) return (path:gsub("^" .. (HOME or "~"):gsub("%p", "%%%0"), "~")) end

local function save_cfg()
    run("latte-kvapky", { "uloz", "spustac", json.encode(cfg) })
end

-- ── ponuka Goo (pravý klik, rozbaľovacie čipy): položky { label, glyph, hint, on, off, danger, sep, run, sub } ──
-- sub = zoznam položiek podponuky: riadok s › ponuku nezavrie, vnorí sa do nej (prvý riadok „‹ Späť“); sep = čiara nad
local CTX_MAX = 12
local function menu(items, width)
    ctx_actions = {}
    local out, y = {}, 6
    for _, it in ipairs(items) do
        if #out >= CTX_MAX then break end
        if it.sep and #out > 0 then y = y + 12 end
        out[#out + 1] = { label = it.label, on = it.on and 1 or 0, off = it.off == true, glyph = it.glyph or "",
                          hint = it.hint or "", danger = it.danger == true, sub = it.sub ~= nil or it.back ~= nil, back = it.back ~= nil, sep = it.sep == true and #out > 0, y = y }
        y = y + 36
        if it.sub then
            local parent = items
            ctx_actions[#out] = function()
                local kids = { { label = tr("Back"), glyph = G["chevron-left"], back = parent } }
                for j, c in ipairs(it.sub) do
                    local c2 = {}; for kk, vv in pairs(c) do c2[kk] = vv end
                    if j == 1 then c2.sep = true end
                    kids[#kids + 1] = c2
                end
                menu(kids, width)
            end
        elseif it.back then
            ctx_actions[#out] = function() menu(it.back, width) end
        else
            ctx_actions[#out] = it.run or function() end
        end
    end
    model.ctx = out
    fact.ctx_w = width or 248
    fact.ctx_h = y + 6
    fact.ctx_hot = -1
    fact.ctx_open = #out > 0
end
on("ctx_pick", function(k) local f = ctx_actions[(k or 0) + 1]; if f then f() end end)

-- pravý klik na guľôčku: ponuka okna vo vzhľade Goo (1. 10., pravidlo 10) — funkcie ako klasická ponuka okna
-- (apps/ponuka.qml → latte.okno.* v Hyprlande), vzhľad Goo: karta pripojená rohom ku guľôčke, rastie od okraja lišty
on("win_menu", function(k)
    local i = (k or 0) + 1
    if not wins[i] or (overflow() and i == SLOTS) then return end
    win_eval("focus_by", i)
    run("hyprctl", { "-j", "cursorpos" }, function(out)
        local ok, c = pcall(json.decode, out or "")
        local x = (ok and c and c.x) or math.floor(fact["menu.x"] or 0)
        local y = (ok and c and c.y) or math.floor(fact["menu.y"] or 0)
        after(120, function()
            run("hyprctl", { "-j", "activewindow" }, function(o2)
                local ok2, w = pcall(json.decode, o2 or "")
                if not ok2 or type(w) ~= "table" or not w.address then return end
                local a = w.address
                local function q(lua) return function() run("hyprctl", { "eval", lua }) end end
                local function ok_(fn, ...) local args = { ... }; return q(string.format("latte.okno.%s('%s'%s)", fn, a, (#args > 0) and ("," .. table.concat(args, ",")) or "")) end
                local function lay(z, label, glyph) return { label = tr(label), glyph = G[glyph], run = q(string.format("latte.okno.rozlozenie('%s','%s')", a, z)) } end
                local max, full = w.fullscreen == 1, w.fullscreen == 2
                local ws = (type(w.workspace) == "table" and tonumber(w.workspace.id)) or 0
                local desks = {}
                for d = 1, 4 do desks[#desks + 1] = { label = fill(tr("Desktop {n}"), { n = tostring(d) }), on = ws == d, run = ok_("na_plochu", d) } end
                desks[#desks + 1] = { label = tr("New desktop"), glyph = G.plus, run = ok_("na_plochu", 0) }
                local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
                fact["ctx.x"] = x; fact["ctx.y"] = y
                fact.ctx_up = y > H / 2
                menu({
                    { label = tr("Restore"), glyph = G["arrows-minimize"], run = ok_("obnovit") },
                    { label = tr("Minimize"), glyph = G.minus, run = ok_("minimalizovat") },
                    { label = tr("Maximize"), glyph = G.square, off = max, run = ok_("maximalizovat") },
                    { label = tr("Layout"), glyph = G["layout-grid"], sub = {
                        lay("lava", "Left half", "layout-sidebar"), lay("prava", "Right half", "layout-sidebar-right"),
                        lay("lh", "Top left", "layout-grid"), lay("ph", "Top right", "layout-grid"),
                        lay("ld", "Bottom left", "layout-grid"), lay("pd", "Bottom right", "layout-grid"),
                        lay("l23", "Two thirds left", "layout-columns"), lay("p13", "One third right", "layout-columns"),
                        lay("stred", "Center", "focus-centered") } },
                    { label = tr("Always on top (all desktops)"), glyph = G.pin, on = w.pinned == true, run = ok_("navrchu") },
                    { label = tr("Move to desktop"), glyph = G["stack-2"], sub = desks },
                    { label = tr("Close"), glyph = G.x, hint = "Alt+F4", danger = true, sep = true, run = ok_("zavriet") },
                }, 320)
            end)
        end)
    end)
end)

local function has(list, id) for i, v in ipairs(list) do if v == id then return i end end return nil end
local function move(list, i, d)
    local j = i + d
    if j < 1 or j > #list then return end
    list[i], list[j] = list[j], list[i]
end

-- ── obľúbené v záložke ──
local function paint_favs()
    favs = {}
    local out = {}
    local t = cfg.tabs[tonumber(fact.tab) or 1]
    if t then
        for _, id in ipairs(t.apps or {}) do
            local a = by_id[id]
            if a and #favs < 12 then favs[#favs + 1] = a; out[#out + 1] = { name = a.name, icon = a.icon } end
        end
    end
    model.favs = out
    text.fav_title = t and t.name or ""
end
-- nedávno spustené (pod obľúbenými, ako „Recent“ vo Windows)
local recent = {}
local function paint_recent()
    recent = {}
    local out = {}
    for _, id in ipairs(cfg.recent or {}) do
        local a = by_id[id]
        if a and #recent < 4 then recent[#recent + 1] = a; out[#out + 1] = { name = a.name, icon = a.icon } end
    end
    model.recent = out
end

-- ── Linux príkaz: nebezpečné príkazy chcú druhý Enter (zoznam z Text Baru klasického LatteOS) ──
local DANGER_WORDS = {
    sudo = true, pkexec = true, su = true, doas = true,
    rm = true, rmdir = true, shred = true, truncate = true, srm = true, unlink = true,
    dd = true, wipefs = true, fdisk = true, sfdisk = true, parted = true, blkdiscard = true,
    kill = true, killall = true, pkill = true, poweroff = true, reboot = true, shutdown = true, halt = true,
}
local DANGER = {
    "mkfs", "%-delete", "chmod%s+%-[%a]*R", "chown%s+%-[%a]*R",
    ">%s*/dev/[sn]", ">%s*/etc/", ">%s*/boot/", ">%s*/usr/",
    "%f[%w]mv%s.-%s/[%a]*%s*$",
    "dnf%s+remove", "dnf%s+erase", "dnf%s+autoremove", "rpm%s+%-e", "flatpak%s+uninstall", "flatpak%s+remove",
    "systemctl%s+stop", "systemctl%s+disable", "systemctl%s+mask", "systemctl%s+poweroff", "systemctl%s+reboot",
    "git%s+reset%s+%-%-hard", "git%s+clean%s", "git%s+push%s.-%-%-force", "git%s+push%s.-%-f%f[%W]",
    "|%s*s?h%f[%W]", "|%s*bash", "|%s*zsh", ":%(%)%s*{",
}
local function dangerous(cmd)
    for seg in string.gmatch(cmd .. ";", "(.-)[;&|`(\n]") do
        local w = string.match(seg, "^[%s$]*([%w%._/%-]+)")
        if w then
            w = string.match(w, "([^/]+)$")
            if DANGER_WORDS[w] or string.find(w, "^mkfs") then return true end
        end
    end
    for _, p in ipairs(DANGER) do if string.find(cmd, p) then return true end end
    return false
end

-- ── obsah podľa režimu ──
local function note(s) text.note = s end
local function paint_hits()
    local q = text.query or ""
    local ql = q:lower()
    local m = mode_id()
    hits = {}
    if m == "apps" and ql ~= "" then
        local starts, inside = {}, {}
        for _, a in ipairs(apps) do
            local n = (a.name or ""):lower()
            if n:sub(1, #ql) == ql then starts[#starts + 1] = a
            elseif n:find(ql, 1, true) then inside[#inside + 1] = a end
        end
        for _, list in ipairs({ starts, inside }) do
            for _, a in ipairs(list) do
                if #hits < 4 then hits[#hits + 1] = { kind = "app", name = a.name, sub = a.comment or a.generic or tr("Application"), icon = a.icon, app = a } end
            end
        end
        -- kvapky widgetov: napíš napr. „hlas“ → Hlasitosť; klik ju pridá na okraj (alebo odoberie)
        for _, w in ipairs(widget_rows(ql)) do
            if #hits < 4 then
                hits[#hits + 1] = { kind = "wdg", name = w.name, sub = w.on and tr("Drop · shown") or tr("Drop"), icon = w.icon, id = w.id }
            end
        end
        -- to isté inde: prepne režim a text ostane
        hits[#hits + 1] = { kind = "jump", to = 2, name = fill(tr("Search files for “{q}”"), { q = q }), sub = tr("Files"), icon = "folder" }
        hits[#hits + 1] = { kind = "jump", to = 3, name = fill(tr("Search the web for “{q}”"), { q = q }), sub = engine().name, icon = "internet-web-browser" }
        if not ai.disabled then
            hits[#hits + 1] = { kind = "jump", to = 0, name = fill(tr("Ask AI: {q}"), { q = q }), sub = tr("AI"), icon = "dialog-question" }
        end
        note(tr("Nothing found"))
    elseif m == "files" then
        local list = ql ~= "" and file_hits or places
        for _, f in ipairs(list) do
            if #hits < 10 then
                local name = f.path:match("([^/]+)/?$") or f.path
                local sub = (ql == "" and tilde(f.path)) or tilde(f.path:match("^(.*)/[^/]*$") or f.path)
                hits[#hits + 1] = { kind = "file", name = f.name or name, sub = sub,
                                    icon = f.dir and "folder" or "text-x-generic", path = f.path, dir = f.dir }
            end
        end
        note(ql ~= "" and tr("Nothing found") or tr("Type a file or folder name. Enter opens it; right click opens the folder it is in."))
    elseif m == "web" and ql ~= "" then
        local first = engine()
        local order = { first }
        for _, e in ipairs(ENGINES) do if e ~= first then order[#order + 1] = e end end
        for _, e in ipairs(order) do
            hits[#hits + 1] = { kind = "web", name = fill(tr("Search “{q}”"), { q = q }), sub = e.name,
                                icon = "internet-web-browser", url = e.url:format(urlencode(q)) }
        end
    elseif m == "web" then
        note(tr("Type what to look for. Enter searches with your search engine; choose it below."))
    elseif m == "cmd" then
        local cmd = q:gsub("^%s+", "")
        if cmd ~= "" then
            local bad = dangerous(cmd)
            hits[#hits + 1] = { kind = "cmd", cmd = cmd, name = cmd, icon = bad and "dialog-warning" or "utilities-terminal",
                                warn = bad, sub = bad and (confirm_cmd == cmd and tr("Enter again to run") or tr("Careful: changes the system")) or tr("Run in terminal") }
        end
        for _, c in ipairs(cfg.cmds) do
            if #hits < 10 and c ~= cmd and (ql == "" or c:lower():find(ql, 1, true)) then
                hits[#hits + 1] = { kind = "cmd", cmd = c, name = c, sub = tr("Recent"), icon = "utilities-terminal" }
            end
        end
        note(tr("Type a Linux command. It runs in the terminal; commands that can delete or change the system need a second Enter."))
    elseif m == "ai" then
        if ai.disabled then note(tr("AI is turned off. Settings › Software › AI turns it on."))
        elseif ai.web then note(fill(tr("Ask anything. {ai} answers in the browser, signed in as you. For answers right here, choose a service below."), { ai = ai.target or "AI" }))
        else note(tr("Ask anything. The answer appears here; the service and the model are chosen below.")) end
    end
    while #hits > MAXH do table.remove(hits) end
    local out = {}
    for _, h in ipairs(hits) do out[#out + 1] = { name = h.name, sub = h.sub or "", icon = h.icon, warn = h.warn == true } end
    model.hits = out
    if (tonumber(fact.sel) or 0) >= #hits then fact.sel = 0 end
end

local fd_gen = 0
local function search()
    if fact.renaming then fact.typing = false; return end
    local q = text.query or ""
    local was = fact.typing
    fact.typing = q ~= ""
    if was ~= fact.typing and mode_id() == "apps" and paint_chips then paint_chips() end
    fact.sel = 0
    if confirm_cmd and confirm_cmd ~= q:gsub("^%s+", "") then confirm_cmd = nil end
    file_hits = {}
    paint_hits()
    -- súbory: fd po krátkej pauze v písaní (nie po každom písmene)
    fd_gen = fd_gen + 1
    local gen = fd_gen
    if mode_id() == "files" and #q >= 2 and HOME then
        after(220, function()
            if gen ~= fd_gen then return end
            run("fd", { "--ignore-case", "--max-results", "10", "--max-depth", "6", "--absolute-path", "--", q, HOME }, function(out)
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
-- priečinky domova (pri prázdnom poli v režime súborov)
local function load_places()
    if not HOME then return end
    run("fd", { "--max-depth", "1", "--type", "d", "--absolute-path", ".", HOME }, function(out)
        places = { { path = HOME, dir = true, name = tr("Home") } }
        local list = {}
        for line in (out or ""):gmatch("[^\n]+") do list[#list + 1] = line:gsub("/$", "") end
        table.sort(list, function(a, b) return a:lower() < b:lower() end)
        for _, p in ipairs(list) do places[#places + 1] = { path = p, dir = true } end
        paint_hits()
    end)
end

-- ── AI: rozhovor cez latte-ai (bubliny: najnovšia navrchu, text zalomený do ~56 znakov) ──
local function wrap(s, width)
    s = s:gsub("\r", ""):gsub("%*%*", ""):gsub("__", ""):gsub("`", "")
    local out = {}
    for para in (s .. "\n"):gmatch("(.-)\n") do
        para = para:gsub("^#+%s*", ""):gsub("^%s*[%*%-]%s+", "• ")
        local line = ""
        for word in para:gmatch("%S+") do
            if line == "" then line = word
            elseif (utf8.len(line) or #line) + 1 + (utf8.len(word) or #word) <= width then line = line .. " " .. word
            else out[#out + 1] = line; line = word end
        end
        out[#out + 1] = line
    end
    while #out > 0 and out[#out] == "" do table.remove(out) end
    return table.concat(out, "\n")
end
local function paint_chat()
    local out = {}
    for i = #conv, math.max(1, #conv - 7), -1 do
        out[#out + 1] = { txt = wrap(conv[i].content, 56), me = conv[i].role == "user" }
    end
    model.chat = out
    fact.chst = 0
    paint_hits()
    if paint_chips then paint_chips() end
end
local function ai_status(done)
    run("latte-ai", { "status" }, function(out)
        local st = {}
        for k, v in (out or ""):gmatch("(%w+)=([^\n]*)") do st[k] = v end
        ai = { provider = st.provider, target = st.target, model = st.model, ok = st.ok == "1",
               web = st.web == "1", disabled = st.disabled == "1" }
        if ai.web then ai.target = (st.model ~= "" and st.model) or "AI" end
        if paint_chips then paint_chips() end
        paint_hits()
        if done then done() end
    end)
end
local ai_job = nil                                  -- beží otázka (spawn), klik na kvapku „…“ ju zruší
on("ai_cancel", function()
    if ai_job then kill(ai_job); ai_job = nil end
    fact.ai_wait = false
    conv[#conv + 1] = { role = "assistant", content = tr("Stopped.") }
    paint_chat()
end)
local function ai_send(q)
    q = q:gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" or fact.ai_wait then return end
    text.query = ""
    conv[#conv + 1] = { role = "user", content = q }
    if ai.disabled then
        conv[#conv + 1] = { role = "assistant", content = tr("AI is turned off. Settings › Software › AI turns it on.") }
        paint_chat(); return
    end
    if ai.web then
        run("latte-ai", { "open", q })
        conv[#conv + 1] = { role = "assistant", content = fill(tr("I opened {ai} in the browser with your question."), { ai = ai.target or "AI" }) }
        paint_chat(); return
    end
    paint_chat()
    fact.ai_wait = true
    local msgs = {}
    for i = math.max(1, #conv - 19), #conv do msgs[#msgs + 1] = conv[i] end
    local lines = {}
    ai_job = spawn("latte-ai", { "chat", json.encode(msgs) }, function(line) lines[#lines + 1] = line end, function(_, code)
        if not ai_job then return end                   -- zrušené
        ai_job = nil
        fact.ai_wait = false
        local a = table.concat(lines, "\n"):gsub("%s+$", "")
        if code ~= 0 or a == "" then
            a = tr("The AI did not answer.") .. (a ~= "" and ("\n" .. a) or "") .. "\n" .. tr("Settings › Software › AI")
        end
        conv[#conv + 1] = { role = "assistant", content = a }
        paint_chat()
    end)
end
on("bubble_menu", function(k)
    local i = #conv - (tonumber(k) or 0)
    local m = conv[i]
    if not m then return end
    menu({ { label = tr("Copy"), run = function() pcall(sys.call, "clipboard.set", m.content) end } })
end)

-- ── riadok režimu: čipy ──
local function set_chips(list)
    chip_do = {}
    local out = {}
    for _, c in ipairs(list) do
        out[#out + 1] = { label = c.label or "", label_on = (c.label or "") ~= "", glyph = c.glyph or "", hasg = c.glyph ~= nil,
                          on = c.on == true, drop = c.drop == true }
        chip_do[#chip_do + 1] = c
    end
    model.chips = out
end
local start_rename
local function tab_menu(i)
    menu({
        { label = tr("Rename"), run = function() start_rename(i) end },
        { label = tr("Move left"), run = function() if i > 1 then move(cfg.tabs, i, -1); fact.tab = i - 1 end; save_cfg(); paint_chips(); paint_favs() end },
        { label = tr("Move right"), run = function() if i < #cfg.tabs then move(cfg.tabs, i, 1); fact.tab = i + 1 end; save_cfg(); paint_chips(); paint_favs() end },
        { label = tr("Delete tab"), run = function() table.remove(cfg.tabs, i); fact.tab = 1; save_cfg(); paint_chips(); paint_favs() end },
    })
end
local function ai_set(pairs_)
    local n = #pairs_
    local function step(i)
        if i > n then ai_status(); return end
        run("latte-ai", { "set", pairs_[i][1], pairs_[i][2] }, function() step(i + 1) end)
    end
    step(1)
end
function paint_chips()
    if tonumber(fact.tview) == 1 and time_chips then set_chips(time_chips()); return end
    local m = mode_id()
    local list = {}
    if m == "apps" then
        local cur = tonumber(fact.tab) or 1
        for i, t in ipairs(cfg.tabs) do
            list[#list + 1] = { label = t.name, on = i == cur and not fact.typing,
                pick = function() fact.tab = i; text.query = ""; paint_chips(); paint_favs() end,
                menu = function() fact.tab = i; paint_chips(); paint_favs(); tab_menu(i) end }
        end
        if #cfg.tabs < MAX_TABS then
            list[#list + 1] = { glyph = G.plus, pick = function()
                cfg.tabs[#cfg.tabs + 1] = { name = tr("New tab"), apps = {} }
                save_cfg(); fact.tab = #cfg.tabs; paint_chips(); paint_favs(); start_rename(#cfg.tabs)
            end }
        end
    elseif m == "ai" then
        list[#list + 1] = { glyph = G.settings, label = tr("Settings"), pick = function() run("latte-app", { "nastavenia", "ai" }); fact.dash = false end }
        local cur = ai.web and ai.target or ({ lokalne = "Ollama", domaci = tr("Home server") })[ai.provider or ""] or ai.target or "AI"
        list[#list + 1] = { glyph = G.sparkles, label = cur, drop = true, pick = function()
            local items = {}
            for _, p in ipairs(AI_PRESETS) do
                items[#items + 1] = { label = tr(p.name), run = function()
                    local sets = { { "provider", p.provider } }
                    if p.key then sets[#sets + 1] = { p.key, p.value } end
                    ai_set(sets)
                end }
            end
            menu(items)
        end }
        if not ai.web and not ai.disabled then
            list[#list + 1] = { label = (ai.model and ai.model ~= "") and ai.model or tr("Model"), drop = true, pick = function()
                run("latte-ai", { "models" }, function(out)
                    local items = {}
                    for id in (out or ""):gmatch("([^\t\n]+)[^\n]*") do
                        if #items < 10 then
                            items[#items + 1] = { label = id, on = id == ai.model, run = function()
                                ai_set({ { ai.provider == "cloud" and "cloud_model" or "model", id } })
                            end }
                        end
                    end
                    if #items == 0 then items[1] = { label = tr("No models found"), off = true } end
                    menu(items)
                end)
            end }
        end
        if #conv > 0 then
            list[#list + 1] = { glyph = G["message-plus"], label = tr("New chat"), pick = function() conv = {}; paint_chat(); paint_chips() end }
        end
    elseif m == "files" then
        list[#list + 1] = { glyph = G["folder-open"], label = tr("Open Files"), pick = function() run("latte-app", { "subory" }); fact.dash = false end }
    elseif m == "web" then
        list[#list + 1] = { glyph = G.world, label = engine().name, drop = true, pick = function()
            local items = {}
            for _, e in ipairs(ENGINES) do
                items[#items + 1] = { label = e.name, on = e.id == cfg.engine, run = function()
                    cfg.engine = e.id; save_cfg(); paint_chips(); paint_hits()
                end }
            end
            menu(items)
        end }
    elseif m == "cmd" then
        list[#list + 1] = { glyph = G["terminal-2"], label = tr("Open terminal"), pick = function() run("latte-terminal", {}); fact.dash = false end }
        if #cfg.cmds > 0 then
            list[#list + 1] = { glyph = G.trash, label = tr("Clear history"), pick = function() cfg.cmds = {}; save_cfg(); paint_chips(); paint_hits() end }
        end
    end
    set_chips(list)
end
on("chip_pick", function(k) local c = chip_do[(k or 0) + 1]; if c and c.pick then c.pick() end end)
on("chip_menu", function(k) local c = chip_do[(k or 0) + 1]; if c and c.menu then c.menu() end end)

local function paint_modes()
    local out = {}
    for _, m in ipairs(MODES) do out[#out + 1] = { name = tr(m.name), glyph = m.glyph } end
    model.modes = out
end
local function paint_mode()
    text.hint = tr((MODES[(tonumber(fact.smode) or 1) + 1] or MODES[2]).hint)
    paint_chips()
    if mode_id() == "ai" then ai_status() end
    search()
end
on("fact:smode", function(v)
    cfg.mode = tonumber(v) or 1
    save_cfg()
    fact.wx_detail = false
    paint_mode()
end)

-- ── otvorenie riadkov ──
local function launch(a)
    if a and a.exec then pcall(sys.call, "apps.launch", a.exec) end
    if a and a.id then
        local i = has(cfg.recent, a.id)
        if i then table.remove(cfg.recent, i) end
        table.insert(cfg.recent, 1, a.id)
        while #cfg.recent > 8 do table.remove(cfg.recent) end
        save_cfg(); paint_recent()
    end
    fact.dash = false
end
on("rec_open", function(i) launch(recent[(i or 0) + 1]) end)
on("rec_menu", function(k)
    local a = recent[(k or 0) + 1]
    if not a then return end
    menu({ { label = tr("Remove from recent"), run = function()
        local i = has(cfg.recent, a.id)
        if i then table.remove(cfg.recent, i); save_cfg(); paint_recent() end
    end } })
end)
local function run_cmd(cmd)
    if dangerous(cmd) and confirm_cmd ~= cmd then confirm_cmd = cmd; paint_hits(); return end
    confirm_cmd = nil
    local i = has(cfg.cmds, cmd)
    if i then table.remove(cfg.cmds, i) end
    table.insert(cfg.cmds, 1, cmd)
    while #cfg.cmds > 10 do table.remove(cfg.cmds) end
    save_cfg()
    -- terminál ostane otvorený, kým ho používateľ nezavrie Enterom (ako Text Bar)
    run("latte-terminal", { "sh", "-c", cmd .. "; echo; read -r -p '" .. tr("[LatteOS] Enter closes the terminal…"):gsub("'", "") .. " ' _" })
    text.query = ""
    fact.dash = false
end
local function open_hit(i)
    local h = hits[(i or 0) + 1]
    if not h then return end
    if h.kind == "wdg" then widget_toggle(h.id); paint_hits(); return end
    if h.kind == "jump" then fact.smode = h.to; return end
    if h.kind == "app" then launch(h.app)
    elseif h.kind == "cmd" then run_cmd(h.cmd)
    elseif h.kind == "file" then run("xdg-open", { h.path }); fact.dash = false
    else run("xdg-open", { h.url }); fact.dash = false end
end
on("open_hit", open_hit)
on("fav_open", function(i) launch(favs[(i or 0) + 1]) end)

-- ── premenovanie záložky: pole slúži ako názov (Enter uloží, Esc zruší) ──
function start_rename(t)
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
        paint_chips()
        return
    end
    if mode_id() == "ai" then ai_send(text.query or ""); return end
    open_hit(tonumber(fact.sel) or 0)
end)
on("fact:dash", function(open)
    if not open then
        renaming_tab = nil; fact.renaming = false; text.query = ""; fact.ctx_open = false; confirm_cmd = nil
    elseif mode_id() == "ai" then ai_status()
    end
end)

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
    elseif h.kind == "cmd" and h.sub == tr("Recent") then
        items[#items + 1] = { label = tr("Remove from history"), run = function()
            local i = has(cfg.cmds, h.cmd)
            if i then table.remove(cfg.cmds, i); save_cfg(); paint_hits() end
        end }
    end
    menu(items)
end)
on("fav_menu", function(k)
    local t = cfg.tabs[tonumber(fact.tab) or 1]
    local a = favs[(k or 0) + 1]
    if not t or not a then return end
    local i = has(t.apps, a.id)
    menu({
        { label = tr("Remove from this tab"), run = function() if i then table.remove(t.apps, i) end; save_cfg(); paint_favs() end },
        { label = tr("Move left"), run = function() if i then move(t.apps, i, -1) end; save_cfg(); paint_favs() end },
        { label = tr("Move right"), run = function() if i then move(t.apps, i, 1) end; save_cfg(); paint_favs() end },
    })
end)

-- nastavenia: zo súboru; prvý raz obľúbené z doterajších pripnutých (~/.config/latteos/pripnute) a prázdne Hry
local function load_cfg()
    if not cfg_file then return end
    run("cat", { cfg_file }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if ok and type(c) == "table" and type(c.tabs) == "table" then
            cfg.engine = c.engine or cfg.engine
            cfg.mode = tonumber(c.mode) or cfg.mode
            cfg.cmds = type(c.cmds) == "table" and c.cmds or {}
            cfg.recent = type(c.recent) == "table" and c.recent or {}
            if type(c.queengoo) == "table" then
                cfg.queengoo = c.queengoo
                fact["qg.side"] = tonumber(c.queengoo.side) or 0
                fact["qg.pos"] = tonumber(c.queengoo.pos) or 0.70
            end
            for n, key in pairs({ tg = "timegoo", pg = "powergoo" }) do
                local g = c[key]
                if type(g) == "table" then
                    cfg[key] = g
                    fact[n .. "_free"] = g.free == true
                    fact[n .. ".side"] = tonumber(g.side) or 0
                    fact[n .. ".pos"] = tonumber(g.pos) or 0.3
                end
            end
            if type(c.danogoo) == "table" then
                cfg.danogoo = c.danogoo
                fact["dn.side"] = tonumber(c.danogoo.side) or 0
                fact["dn.pos"] = tonumber(c.danogoo.pos) or 0.78
            end
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
        paint_modes()
        if (tonumber(fact.smode) or 1) ~= cfg.mode then fact.smode = cfg.mode end
        paint_mode(); paint_favs(); paint_recent(); load_places()
    end)
end

sys.watch("apps", function(list)
    apps = list or {}
    by_id = {}
    for _, a in ipairs(apps) do by_id[a.id] = a end
    index_apps(apps); paint_favs(); paint_recent(); search(); layout()
end)

-- téma LatteOS (~/.config/latteos/theme): farby karty spúšťača; mení sa aj v Nastaveniach, preto sa číta dookola
local tema_file = nil
local function read_tema()
    if not tema_file then return end
    run("cat", { tema_file }, function(out)
        local id = (out or ""):match("[%w-]+") or "latte"
        local idx = 0
        for i, t in ipairs(IK.temy) do if t == id then idx = i - 1 end end
        if fact.tema ~= idx then fact.tema = idx end
    end)
end

-- upozornenie v spúšťači: klik = otvoriť (predvolená akcia aplikácie) a zavrieť; „Vymazať všetko“
on("note_open", function(i)
    local n = (model.notes or {})[(i or 0) + 1]
    if not n then return end
    pcall(sys.call, "notifications.invoke", n.id, "default")
    pcall(sys.call, "notifications.dismiss", n.id)
end)
on("notes_clear", function() pcall(sys.call, "notifications.clear") end)

local function noctalia(...) run("noctalia", { "msg", ... }) end
-- ── DaNoGoo (1. 10., LATTEOS-GOO.md 4.2b): hrozno upozornení, guľky počtu, dátum a počasie na kvapke ──
-- Farba bobule = farba ikony aplikácie (latte-kvapky farba → číslo v palete scény), pamätá sa.
local dn_list = {}
local pal_of, pal_wait, no_icon = {}, {}, {}
local LIGHT = { [2] = true, [3] = true, [4] = true, [14] = true }     -- svetlé farby: tmavý text
function dn_paint(list)
    dn_list = list or dn_list
    local out, crit, norm = {}, 0, 0
    for _, n in ipairs(dn_list) do
        if urgency(n.urgency) == 2 then crit = crit + 1 else norm = norm + 1 end
    end
    for i, n in ipairs(dn_list) do
        if i > 6 then break end
        local key = (n.icon and n.icon ~= "") and n.icon or ((n.app or ""):lower():gsub("%s+", "-"))
        local p = pal_of[key]
        if p == nil and key ~= "" and not pal_wait[key] then
            pal_wait[key] = true
            run("latte-kvapky", { "farba", key }, function(o)
                pal_of[key] = tonumber((o or ""):match("%d+")) or 15
                if (o or ""):find("-", 1, true) then no_icon[key] = true end
                pal_wait[key] = nil
                dn_paint()
            end)
        end
        p = p or 15
        if urgency(n.urgency) == 2 then p = 16 end                     -- systémová výstraha: červeno-kávová
        local acts = false
        for _, act in ipairs(n.actions or {}) do if act.key ~= "default" then acts = true end end
        out[#out + 1] = { app = n.app or "", title = n.title or "", body = (n.body or ""):gsub("%s+", " "),
                          icon = (n.icon and n.icon ~= "" and not no_icon[key]) and n.icon or "preferences-system-notifications",
                          pal = p, dark = LIGHT[p] == true, acts = acts }
    end
    model.berries = out
    fact.dn_crit = crit
    fact.dn_norm = norm
    text.dn_clear = #dn_list > 6 and fill(tr("Clear all ({n})"), { n = tostring(#dn_list) }) or tr("Clear all")
    if #dn_list == 0 and fact.dn_open then fact.dn_open = false end
end
on("berry_open", function(k)
    local n = dn_list[(tonumber(k) or 0) + 1]
    if not n then return end
    pcall(sys.call, "notifications.invoke", n.id, "default")
    pcall(sys.call, "notifications.dismiss", n.id)
end)
on("berry_dismiss", function(k)
    local n = dn_list[(tonumber(k) or 0) + 1]
    if n then pcall(sys.call, "notifications.dismiss", n.id) end
end)
on("berry_menu", function(k)
    local n = dn_list[(tonumber(k) or 0) + 1]
    if not n then return end
    local items = {}
    for _, act in ipairs(n.actions or {}) do
        if act.key ~= "default" then
            items[#items + 1] = { label = act.label or act.key, run = function()
                pcall(sys.call, "notifications.invoke", n.id, act.key)
                pcall(sys.call, "notifications.dismiss", n.id)
            end }
        end
    end
    menu(items)
end)
-- Vymazať všetko: každé upozornenie zvlášť (hromadné notifications.clear pri trvalom uchovávaní nezaberie), potom
-- aj zvyšok a história
on("dn_clear_all", function()
    local ids = {}
    for _, n in ipairs(dn_list) do ids[#ids + 1] = n.id end
    for _, id in ipairs(ids) do pcall(sys.call, "notifications.dismiss", id) end
    pcall(sys.call, "notifications.clear")
    pcall(sys.call, "notifications.clear_history")
    dn_paint({})
end)
-- poloha DaNoGoo: pustená pri okraji sa prilepí k najbližšiemu (ako kvapky widgetov), uloží sa v spustac.json
on("dn_drop", function()
    local x, y = tonumber(fact["dnd.x"]) or 0, tonumber(fact["dnd.y"]) or 0
    local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
    local d = { H - y, y, x, W - x }
    local side, best = 0, d[1]
    for i = 2, 4 do if d[i] < best then side, best = i - 1, d[i] end end
    local pos = math.max(0.03, math.min(0.97, (side <= 1) and (x / W) or (y / H)))
    fact["dn.side"] = side; fact["dn.pos"] = pos
    cfg.danogoo = { side = side, pos = pos }
    save_cfg()
end)
-- dátum a počasie na kvapke (počasie z weather(), dátum každú minútu)
local WDAY_SHORT = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local function dn_date()
    local t = os.date("*t")
    text.dn_date = tr(WDAY_SHORT[t.wday]) .. " " .. t.day .. ". " .. t.month .. "."
end
dn_date()
every(60000, dn_date)

-- ── QueenGoo (1. 10., LATTEOS-GOO.md 4.4b): kvapka s korunkou — ľavý klik App Manager, pravý Správca zariadení ──
-- Okno sa otvorí rohom pri jej uchu (latte-kvapky miesto → Hyprland latte/windows.lua); kým je otvorené, ostane
-- vystúpená. Guľka = čakajúce aktualizácie (latte-apps updates, z cache, každých 30 min).
local QG_WIN = { { app = "aplikacie", title = "Aplikácie — LatteOS" }, { app = "zariadenia", title = "Správca zariadení — LatteOS" } }
local qg_devwarn, qg_offline = 0, false
local bub_wait = nil                                                         -- titulok okna, na ktoré bublina čaká
function qg_windows(list)
    local up = false
    for _, w in ipairs(list or {}) do
        for _, q in ipairs(QG_WIN) do if w.title == q.title then up = true end end
    end
    if fact.qg_up ~= up then fact.qg_up = up end
    if bub_wait then
        for _, w in ipairs(list or {}) do
            if w.title == bub_wait then bub_wait = nil; emit("bub_done"); after(250, function() fact.bub_on = false end) end
        end
    end
end
-- okno z bubliny (pravidlo 14, 1. 10.): App Manager a Správca zariadení sú riadne okná — kráľovná ostane na mieste a
-- vypľuje bublinu (bublina.py), tá sa nafúkne na obdĺžnik okna vedľa nej; okno sa otvorí presne tam, bez animácie
-- Hyprlandu (latte-kvapky okno → latte/windows.lua), a keď naskočí, bublina zmizne
local QG_SIZE = { aplikacie = { 1220, 780 }, zariadenia = { 1100, 780 } }   -- implicitWidth/Height v session/apps
local function clampn(v, lo, hi) return math.max(lo, math.min(hi, v)) end
on("qg_open", function(k)
    local q = QG_WIN[(tonumber(k) or 0) + 1]
    if not q then return end
    for _, w in ipairs(wins) do
        if w.title == q.title then run("hyprctl", { "eval", "latte.win.focus_by('org.quickshell', '" .. q.title .. "')" }); return end
    end
    if bub_wait then return end                                              -- bublina už letí
    local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
    local side, pos = tonumber(fact["qg.side"]) or 0, tonumber(fact["qg.pos"]) or 0.7
    local nx = ({ [0] = 0, 0, 1, -1 })[side] or 0
    local ny = ({ [0] = -1, 1, 0, 0 })[side] or -1
    local qx = ((side <= 1) and W * pos or (side == 2 and 0 or W)) + nx * 36   -- stred kráľovnej
    local qy = ((side <= 1) and (side == 0 and H or 0) or H * pos) + ny * 36
    local sz = QG_SIZE[q.app] or { 1000, 700 }
    local w, h = math.min(sz[1], W - 32), math.min(sz[2], H - 32)
    local gap = 36 + 34                                                        -- kráľovná + medzera
    local cx, cy = qx + nx * (gap + w / 2), qy + ny * (gap + h / 2)
    cx = clampn(cx, 16 + w / 2, W - 16 - w / 2)
    cy = clampn(cy, 16 + h / 2, H - 16 - h / 2)
    fact["bub.x"] = cx; fact["bub.y"] = cy; fact["bub.w"] = w; fact["bub.h"] = h
    emit("bub_go")
    bub_wait = q.title
    -- okno rovno na tom, čo guľka hlási: aktualizácie (App Manager), siete pri výpadku (Správca zariadení)
    local args = { q.app }
    if q.app == "aplikacie" and (tonumber(fact.qg_upd) or 0) > 0 then args[2] = "aktualizacie" end
    if q.app == "zariadenia" and qg_offline then args[2] = "siete" end
    run("latte-kvapky", { "okno", q.title, tostring(math.floor(cx - w / 2)), tostring(math.floor(cy - h / 2)), tostring(w), tostring(h) }, function()
        after(650, function() run("latte-app", args) end)                    -- naskočí, keď je bublina nafúknutá
    end)
    after(7000, function() if bub_wait == q.title then bub_wait = nil; emit("bub_done"); fact.bub_on = false end end)
end)
on("qg_drop", function()
    local x, y = tonumber(fact["qgd.x"]) or 0, tonumber(fact["qgd.y"]) or 0
    local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
    local d = { H - y, y, x, W - x }
    local side, best = 0, d[1]
    for i = 2, 4 do if d[i] < best then side, best = i - 1, d[i] end end
    local pos = math.max(0.03, math.min(0.97, (side <= 1) and (x / W) or (y / H)))
    fact["qg.side"] = side; fact["qg.pos"] = pos
    cfg.queengoo = { side = side, pos = pos }
    save_cfg()
end)
-- Hodiny (TimeGoo) a vypínač (PowerGoo) ťahaním (pravidlo 16): pustené pri svojom mieste v lište sa vrátia do nej,
-- inak samostatná kvapka pri najbližšom okraji; uloží sa do spustac.json (timegoo / powergoo = { free, side, pos })
local function free_drop(n, key)
    local x, y = tonumber(fact[n .. "d.x"]) or 0, tonumber(fact[n .. "d.y"]) or 0
    local W, H = tonumber(fact["wd.w"]) or 1920, tonumber(fact["wd.h"]) or 1080
    if (tonumber(fact[n .. "d.dd"]) or 999) < 110 then
        fact[n .. "_free"] = false
        cfg[key] = { free = false }
    else
        local d = { H - y, y, x, W - x }
        local side, best = 0, d[1]
        for i = 2, 4 do if d[i] < best then side, best = i - 1, d[i] end end
        local pos = math.max(0.03, math.min(0.97, (side <= 1) and (x / W) or (y / H)))
        fact[n .. ".side"] = side; fact[n .. ".pos"] = pos; fact[n .. "_free"] = true
        cfg[key] = { free = true, side = side, pos = pos }
    end
    save_cfg()
end
on("tg_drop", function() free_drop("tg", "timegoo") end)
on("pg_drop", function() free_drop("pg", "powergoo") end)
-- červená guľka = hardvér (zariadenia, ktoré potrebujú pozornosť — latte-devices), zelená = sieť (výpadok)
local function qg_hw_paint() fact.qg_hw = qg_devwarn; fact.qg_net = qg_offline and 1 or 0 end
local function qg_devices()
    run("latte-devices", { "list" }, function(out)
        local ok, d = pcall(json.decode, out or "")
        if ok and type(d) == "table" then qg_devwarn = type(d.faults) == "table" and #d.faults or 0; qg_hw_paint() end
    end)
end
function qg_network(n) qg_offline = n ~= nil and n.online == false; qg_hw_paint() end
after(45000, qg_devices)
every(30 * 60 * 1000, qg_devices)
local function qg_updates()
    run("latte-apps", { "updates" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        if ok and type(list) == "table" then fact.qg_upd = #list end
    end)
end
after(60000, qg_updates)
every(30 * 60 * 1000, qg_updates)

-- ── časové menu TimeGoo (pravý klik, 1. 10.): Prehľad · Stopky · Minútka · Budíky ─────────────────────────────
-- Tá istá karta ako spúšťač (fact tview 1). Údaje spoločné s klasickým LatteOS: stopky, minútka a budíky v
-- ~/.local/share/latteos/casovace.json (zápis cez `latte-kvapky uloz casovace`), časové pásma v
-- ~/.config/latteos/clock.conf, Digitálna pohoda v ~/.local/share/latteos/pohoda/RRRR-MM-DD.json. Minútku a budíky
-- v Goo stráži a zvoní táto logika (v klasickom LatteOS widget hodín na lište Noctalie, ktorý Goo nemá).
local T = { data = nil, epoch = nil, c0 = 0, alh = 7, alm = 0, file = nil, cfg = nil, share = nil }
local function now_ms()
    if T.epoch then return T.epoch + math.floor((os.clock() - T.c0) * 1000) end
    return os.time() * 1000
end
run("date", { "+%s%3N" }, function(out)
    local v = tonumber((out or ""):match("%d+"))
    if v then T.epoch = v; T.c0 = os.clock() end
end)
local function fmt_ms(ms, tenths)
    ms = math.max(0, math.floor(ms))
    local s = ms // 1000
    local h, m, sec = s // 3600, (s // 60) % 60, s % 60
    local out = h > 0 and string.format("%d:%02d:%02d", h, m, sec) or string.format("%02d:%02d", m, sec)
    if tenths then out = out .. "," .. tostring((ms // 100) % 10) end
    return out
end
local function dur_s(s)
    s = math.floor(s or 0)
    local h, m = s // 3600, (s % 3600) // 60
    if h > 0 then return string.format("%d h %02d min", h, m) end
    return string.format("%d min", m)
end
local function timers()
    local t = T.data or {}
    t.sw = t.sw or { running = false, start = 0, acc = 0, laps = {} }
    t.sw.laps = t.sw.laps or {}
    t.timer = t.timer or { endMs = 0, durMs = 5 * 60000, left = 0 }
    t.alarms = t.alarms or {}
    T.data = t
    return t
end
local function save_timers() run("latte-kvapky", { "uloz", "casovace", json.encode(timers()) }) end
local function sw_elapsed(sw) return (sw.acc or 0) + ((sw.running and (sw.start or 0) > 0) and (now_ms() - sw.start) or 0) end
local function ring(title, body)
    run("notify-send", { "-a", "LatteOS", "-i", "alarm-clock", title, body })
    local n = 0
    local function again()
        n = n + 1
        if n <= 3 then run("paplay", { "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga" }, again) end
    end
    again()
end

-- minútka a stopky: to, čo sa mení každú desatinu sekundy
local function paint_running()
    local tm = timers()
    local sw, tim = tm.sw, tm.timer
    text.t_sw = fmt_ms(sw_elapsed(sw), true)
    if fact.sw_run ~= (sw.running == true) then fact.sw_run = sw.running == true end
    local now = now_ms()
    local run_ = (tim.endMs or 0) > 0
    local left = run_ and (tim.endMs - now) or (tim.left or 0)
    local active = run_ or (tim.left or 0) > 0
    text.t_timer = fmt_ms(active and (left + (run_ and 999 or 0)) or tim.durMs)
    local frac = active and math.max(0, math.min(1, left / math.max(tim.durMs or 1, 1))) or 1
    fact.t_frac = math.floor(frac * 1000) / 1000
    if fact.t_run ~= run_ then fact.t_run = run_ end
    if fact.t_active ~= active then fact.t_active = active end
end
local function paint_alarms()
    local tm = timers()
    local out = {}
    for i, a in ipairs(tm.alarms) do
        if i <= 5 then out[#out + 1] = { hm = a.time or "", label = a.label or "", on = a.on == true } end
    end
    model.alarms = out
    text.t_alh = string.format("%02d", T.alh)
    text.t_alm = string.format("%02d", T.alm)
    -- prehľad: najbližší zapnutý budík a bežiaca minútka
    local hm = os.date("%H:%M")
    local nxt = nil
    for _, a in ipairs(tm.alarms) do
        if a.on and (not nxt or ((a.time > hm) and (nxt.time <= hm or a.time < nxt.time))) then nxt = a end
    end
    local parts = {}
    if nxt then parts[#parts + 1] = fill(tr("Alarm {t}"), { t = nxt.time }) .. ((nxt.label or "") ~= "" and (" " .. nxt.label) or "") end
    if (tm.timer.endMs or 0) > 0 then parts[#parts + 1] = fill(tr("Timer {t}"), { t = fmt_ms(tm.timer.endMs - now_ms() + 999) }) end
    text.t_next = table.concat(parts, "  ·  ")
    fact.t_has_next = #parts > 0
end
local function paint_laps()
    local laps = timers().sw.laps
    local out = {}
    for i, lap in ipairs(laps) do
        if i > 5 then break end
        out[#out + 1] = { label = fill(tr("Lap {n}"), { n = tostring(#laps - i + 1) }), time = fmt_ms(lap, true) }
    end
    model.laps = out
end
local function load_timers(done)
    if not T.file then if done then done() end; return end
    run("cat", { T.file }, function(out)
        local ok, d = pcall(json.decode, out or "")
        T.data = (ok and type(d) == "table") and d or {}
        timers()
        if done then done() end
    end)
end

-- dátum, Digitálna pohoda, svetové hodiny
local WDAY_FULL = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local function paint_static()
    local t = os.date("*t")
    text.t_date = tr(WDAY_FULL[t.wday]) .. "  " .. t.day .. ". " .. t.month .. ". " .. t.year
    -- týždeň podľa ISO 8601 (Luau os.date nepozná %V): pondelok = 1
    local iso_wd = (t.wday + 5) % 7 + 1
    local week = (t.yday - iso_wd + 10) // 7
    if week < 1 then week = 52 elseif week == 53 and (t.yday - iso_wd + 10 - 7 * 53) >= 0 and iso_wd < 4 then week = 1 end
    text.t_week = fill(tr("Week {w} · day {d} of the year"), { w = tostring(week), d = tostring(t.yday) })
    if T.share then
        run("cat", { string.format("%s/latteos/pohoda/%04d-%02d-%02d.json", T.share, t.year, t.month, t.day) }, function(out)
            local ok, d = pcall(json.decode, out or "")
            local rows = {}
            if ok and type(d) == "table" and type(d.apps) == "table" then
                local screen = 0
                for _, seg in ipairs(d.screen or {}) do screen = screen + ((seg[2] or 0) - (seg[1] or 0)) end
                local list = {}
                for cls, v in pairs(d.apps) do list[#list + 1] = { cls = cls, s = v.s or 0 } end
                table.sort(list, function(a, b) return a.s > b.s end)
                local top = math.max(list[1] and list[1].s or 1, 1)
                for i = 1, math.min(3, #list) do
                    local cls = list[i].cls
                    local name = cls:sub(1, 6) == "latte:" and cls:sub(7) or ((cls:match("([^%.]+)$") or cls):gsub("^%l", string.upper))
                    rows[#rows + 1] = { name = name, dur = dur_s(list[i].s), frac = list[i].s / top }
                end
                text.wb_total = fill(tr("{t} on screen"), { t = dur_s(screen) })
            else
                text.wb_total = ""
            end
            model.wbl = rows
        end)
    end
    if T.cfg then
        run("cat", { T.cfg .. "/latteos/clock.conf" }, function(conf)
            local zs = (conf or ""):match('zones = "([^"]*)"') or ""
            local argv = { "-c", "printf 'local|%s\\n' \"$(date +%z)\"; for z in \"$@\"; do printf '%s|' \"$z\"; TZ=\"$z\" date '+%H:%M|%z'; done", "sh" }
            local n = 0
            for z in zs:gmatch("[^,%s]+") do if n < 4 then argv[#argv + 1] = z; n = n + 1 end end
            if n == 0 then model.zones = {}; return end
            run("sh", argv, function(out)
                local function mins(z) local s, h, m = z:match("([+-])(%d%d)(%d%d)"); if not s then return 0 end; local v = tonumber(h) * 60 + tonumber(m); return s == "-" and -v or v end
                local loc = mins((out or ""):match("local|([^\n]+)") or "+0000")
                local rows = {}
                for z, hm, off in (out or ""):gmatch("([^|\n]+)|(%d%d:%d%d)|([^\n]+)") do
                    local d = (mins(off) - loc) / 60
                    local ds = d == 0 and "" or ((d > 0 and "+" or "−") .. (tostring(math.abs(d)):gsub("%.0$", ""):gsub("%.", ",")) .. " h")
                    rows[#rows + 1] = { city = ((z:match("([^/]+)$") or z):gsub("_", " ")), hm = hm, diff = ds }
                end
                model.zones = rows
            end)
        end)
    end
end
local function paint_time()
    paint_static(); paint_running(); paint_alarms(); paint_laps()
end

-- čipy riadku režimu v časovom menu
function time_chips()
    local cur = tonumber(fact.ttab) or 0
    local function tab(i, glyph, label) return { glyph = glyph, label = tr(label), on = cur == i, pick = function() fact.ttab = i; time_chips_paint() end } end
    return {
        tab(0, G["layout-dashboard"], "Overview"), tab(1, G.stopwatch, "Stopwatch"), tab(2, G.hourglass, "Timer"),
        tab(3, G.alarm, "Alarms"),
        { glyph = G.settings, pick = function() run("latte-app", { "nastavenia", "cas" }); fact.dash = false end },
    }
end
function time_chips_paint() if paint_chips then paint_chips() end end
on("fact:ttab", function() time_chips_paint() end)
on("fact:tview", function(v)
    time_chips_paint()
    if tonumber(v) == 1 then load_timers(paint_time) end
end)
on("time_menu", function() load_timers(paint_time) end)

on("t_do", function(code)
    code = tonumber(code) or 0
    local tm = timers()
    local sw, tim = tm.sw, tm.timer
    if code == 1 then
        if sw.running then sw.acc = sw_elapsed(sw); sw.running = false else sw.start = now_ms(); sw.running = true end
    elseif code == 2 then
        if sw.running then table.insert(sw.laps, 1, sw_elapsed(sw)) end
    elseif code == 3 then
        tm.sw = { running = false, start = 0, acc = 0, laps = {} }
    elseif code == 20 then
        if (tim.endMs or 0) > 0 then tim.left = tim.endMs - now_ms(); tim.endMs = 0
        elseif (tim.left or 0) > 0 then tim.endMs = now_ms() + tim.left; tim.left = 0
        else tim.endMs = now_ms() + (tim.durMs or 300000); tim.left = 0 end
    elseif code == 21 then
        tim.endMs = 0; tim.left = 0
    elseif code >= 30 and code <= 35 then
        local m = ({ 1, 5, 10, 15, 25, 45 })[code - 29]
        tim.durMs = m * 60000; tim.endMs = now_ms() + tim.durMs; tim.left = 0
    elseif code == 40 then
        if #tm.alarms < 10 then
            table.insert(tm.alarms, { time = string.format("%02d:%02d", T.alh, T.alm), label = "", on = true, last = "" })
            table.sort(tm.alarms, function(a, b) return a.time < b.time end)
        end
    elseif code >= 50 and code < 60 then
        local a = tm.alarms[code - 49]
        if a then a.on = not a.on; a.last = "" end
    elseif code >= 60 and code < 70 then
        table.remove(tm.alarms, code - 59)
    elseif code == 70 then
        run("latte-app", { "monitor", "pohoda" }); fact.dash = false; return
    end
    save_timers(); paint_running(); paint_alarms(); paint_laps()
end)
on("t_wheel", function(code)
    code = tonumber(code) or 0
    local tim = timers().timer
    if code <= 1 then
        if (tim.endMs or 0) > 0 or (tim.left or 0) > 0 then return end        -- beží alebo stojí: najprv zrušiť
        local m = math.floor((tim.durMs or 300000) / 60000 + 0.5) + (code == 1 and 1 or -1)
        tim.durMs = math.max(1, math.min(180, m)) * 60000
        save_timers(); paint_running()
    elseif code <= 3 then
        T.alh = (T.alh + (code == 3 and 1 or -1)) % 24; paint_alarms()
    else
        T.alm = (T.alm + (code == 5 and 5 or -5)) % 60; paint_alarms()
    end
end)

-- stráženie: minútka a budíky (každú sekundu), zobrazenie stopiek a minútky (každú desatinu, iba keď sú vidieť)
every(100, function()
    if fact.dash and tonumber(fact.tview) == 1 and T.data then paint_running() end
end)
every(1000, function()
    if not fact.solo or not T.data then return end
    local tm = timers()
    local changed = false
    if (tm.timer.endMs or 0) > 0 and tm.timer.endMs - now_ms() <= 0 then
        tm.timer.endMs = 0; changed = true
        ring(tr("Timer"), fill(tr("Time is up ({t})"), { t = fmt_ms(tm.timer.durMs) }))
    end
    local hm, today = os.date("%H:%M"), os.date("%Y-%m-%d")
    for _, a in ipairs(tm.alarms) do
        if a.on and a.time == hm and a.last ~= today then
            a.last = today; changed = true
            ring(fill(tr("Alarm {t}"), { t = hm }), (a.label or "") ~= "" and a.label or tr("LatteOS alarm"))
            if a.once then a.on = false end
        end
    end
    if changed then save_timers(); paint_running(); paint_alarms() end
end)
-- súbor s časovačmi sa môže zmeniť aj v klasickom LatteOS (iná relácia) — pri štarte a raz za minútu znova
every(60000, function() if not (fact.dash and tonumber(fact.tview) == 1) then load_timers() end end)

-- ── kalendár v karte DaNoGoo (pravý klik, 1. 10.): mesiac od pondelka, udalosti a úlohy (spoločné s klasickým
-- LatteOS: ~/.local/share/latteos/events.json a todo.json, zápis cez `latte-kvapky uloz udalosti|ulohy`), počasie
-- (presunuté z TimeGoo). Nová udalosť: „10:30 Porada“ (s časom), „Porada“ (celý deň), „! úloha“ (úloha na vybraný deň).
local K = { y = nil, m = nil, sel = nil, events = {}, todos = {}, cells = {}, evrow = {}, tdrow = {} }
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
                 "November", "December" }
local function iso(t) return string.format("%04d-%02d-%02d", t.year, t.month, t.day) end
local function cal_paint()
    local now = os.date("*t")
    K.y = K.y or now.year; K.m = K.m or now.month
    K.sel = K.sel or iso(now)
    local today = iso(now)
    local first = os.date("*t", os.time({ year = K.y, month = K.m, day = 1, hour = 12 }))
    local lead = (first.wday + 5) % 7                                   -- pondelok = 0
    local has = {}
    for _, e in ipairs(K.events) do if type(e) == "table" and e.date then has[e.date] = true end end
    local out = {}
    K.cells = {}
    for i = 0, 41 do
        local t = os.date("*t", os.time({ year = K.y, month = K.m, day = 1 - lead + i, hour = 12 }))
        local d = iso(t)
        K.cells[i + 1] = d
        out[#out + 1] = { d = tostring(t.day), inm = t.month == K.m, today = d == today, sel = d == K.sel and d ~= today, dot = has[d] == true }
    end
    model.days = out
    text.dc_month = tr(MONTHS[K.m]) .. " " .. K.y
    local y, m, d = K.sel:match("(%d+)-(%d+)-(%d+)")
    local st = os.date("*t", os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }))
    text.dc_seltitle = (K.sel == today and (tr("Today") .. " · ") or "") .. tr(WDAY_FULL[st.wday]) .. " " .. tonumber(d) .. ". " .. tonumber(m) .. "."
    local evs = {}
    K.evrow = {}
    for i, e in ipairs(K.events) do
        if type(e) == "table" and e.date == K.sel then evs[#evs + 1] = { i = i, e = e } end
    end
    table.sort(evs, function(a, b) return (a.e.time or "") < (b.e.time or "") end)
    local eo = {}
    for n, it in ipairs(evs) do
        if n > 5 then break end
        K.evrow[n] = it.i
        eo[n] = { hm = (it.e.time and it.e.time ~= "") and it.e.time or tr("All day"), title = it.e.title or "" }
    end
    model.evs = eo
    local open, done = {}, {}
    for i, t in ipairs(K.todos) do
        if type(t) == "table" and ((t.date or "") == "" or t.date == K.sel) then
            if t.done then done[#done + 1] = i else open[#open + 1] = i end
        end
    end
    local to = {}
    K.tdrow = {}
    for _, list in ipairs({ open, done }) do
        for _, i in ipairs(list) do
            if #to < 5 then K.tdrow[#to + 1] = i; to[#to + 1] = { title = K.todos[i].title or "", done = K.todos[i].done == true } end
        end
    end
    model.tds = to
    text.dc_hint = tr("New event… 10:30 Meeting · ! task")
end
local function cal_load()
    if not T.share then cal_paint(); return end
    run("cat", { T.share .. "/latteos/events.json" }, function(out)
        local ok, d = pcall(json.decode, out or "")
        K.events = (ok and type(d) == "table") and d or {}
        run("cat", { T.share .. "/latteos/todo.json" }, function(o2)
            local ok2, d2 = pcall(json.decode, o2 or "")
            K.todos = (ok2 and type(d2) == "table") and d2 or {}
            cal_paint()
        end)
    end)
end
local function save_events()
    table.sort(K.events, function(a, b) return ((a.date or "") .. (a.time or "")) < ((b.date or "") .. (b.time or "")) end)
    run("latte-kvapky", { "uloz", "udalosti", json.encode(K.events) })
end
local function save_todos() run("latte-kvapky", { "uloz", "ulohy", json.encode(K.todos) }) end
on("fact:dc_open", function(v) if v then K.y = nil; K.m = nil; K.sel = nil; cal_load(); if wx_repaint then wx_repaint() end end end)
on("dc_nav", function(d)
    d = tonumber(d) or 0
    if d == 0 then local now = os.date("*t"); K.y, K.m, K.sel = now.year, now.month, iso(now)
    else
        K.m = K.m + d
        if K.m < 1 then K.m = 12; K.y = K.y - 1 elseif K.m > 12 then K.m = 1; K.y = K.y + 1 end
    end
    cal_paint()
end)
on("dc_day", function(k)
    local d = K.cells[(tonumber(k) or 0) + 1]
    if not d then return end
    K.sel = d
    local y, m = d:match("(%d+)-(%d+)")
    K.y, K.m = tonumber(y), tonumber(m)
    cal_paint()
end)
on("dc_todo", function(k)
    local i = K.tdrow[(tonumber(k) or 0) + 1]
    if i and K.todos[i] then K.todos[i].done = not K.todos[i].done; save_todos(); cal_paint() end
end)
on("dc_ev_menu", function(k)
    local i = K.evrow[(tonumber(k) or 0) + 1]
    if not i then return end
    menu({ { label = tr("Delete event"), run = function() table.remove(K.events, i); save_events(); cal_paint() end } })
end)
on("text:dc_new", function() fact.dc_empty = (text.dc_new or "") == "" end)
on("dc_add", function()
    local v = (text.dc_new or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if v == "" then return end
    if v:sub(1, 1) == "!" then
        local title = v:sub(2):gsub("^%s+", "")
        if title ~= "" then K.todos[#K.todos + 1] = { title = title, done = false, date = K.sel }; save_todos() end
    else
        local h, mi, title = v:match("^(%d%d?):(%d%d)%s+(.+)$")
        if h and tonumber(h) < 24 and tonumber(mi) < 60 then
            K.events[#K.events + 1] = { date = K.sel, time = string.format("%02d:%02d", tonumber(h), tonumber(mi)), title = title }
        else
            K.events[#K.events + 1] = { date = K.sel, time = "", title = v }
        end
        save_events()
    end
    text.dc_new = ""
    fact.dc_empty = true
    cal_paint()
end)

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
        -- ikona programu je kvapkou, iba ak ju tam používateľ dal (spúšťač); inak je v rohovej lište Noctalie
        if w and not w.hidden and #out < WMAX then
            local e = w
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
        local found = false
        for i, w in ipairs(wlist) do if w.id == id then table.remove(wlist, i); found = true; break end end
        if not found then wlist[#wlist + 1] = { id = id, side = 0, pos = free_pos() } end
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
            rows[#rows + 1] = { id = "tray:" .. it.id, name = t, on = (w ~= nil and not w.hidden), icon = it.icon }
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
            -- (1. 10.) widgety a ikony programov sú predvolene v rohovej lište Noctalie vpravo dole (latte-kvapky);
            -- samostatné kvapky sú na iné veci — pridať sa dajú cez spúšťač
            wlist = {}
            wsave()
        end
        wpaint(); layout()
    end)
end
sys.watch("audio", function(v) st.snd = v or {}; wpaint() end)
sys.watch("network", function(v) st.net = v or {}; wpaint(); if qg_network then qg_network(st.net) end end)
sys.watch("bluetooth", function(v) st.bt = v or {}; wpaint() end)
sys.watch("battery", function(v)
    st.bat = v or {}; wpaint()
    -- PowerGoo: minibublinky a hlavička ponuky (iba notebook)
    fact.bat_present = st.bat.present == true
    fact.bat_pct = math.floor((tonumber(st.bat.percent) or 0) + 0.5)
    fact.bat_chg = st.bat.charging == true
end)
sys.watch("media", function(v) st.media = v or {}; wpaint() end)
-- rohová lišta Noctalie (ikony programov sú v nej): šírka podľa ich počtu, s oneskorením (programy štartujú naraz);
-- roh_len: jej približná dĺžka pre šnúru okien (rovnaký vzorec ako latte-kvapky roh_start, 3 widgety)
function roh_len() return 26 + 48 * 3 + 28 * #tray + 20 end
local roh_gen, roh_n = 0, -1
local function roh_update()
    roh_gen = roh_gen + 1
    local g = roh_gen
    after(900, function()
        if g ~= roh_gen or #tray == roh_n then return end
        roh_n = #tray
        run("latte-kvapky", { "roh-sirka", tostring(#tray) })
    end)
end
sys.watch("tray", function(list) tray = list or {}; wpaint(); roh_update() end)
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
-- predpoveď na 7 dní (hodinová aj denná); riadok počasia v spúšťači ukazuje zvolenú variantu, Detaily 8 stĺpcov
local wxd, wx_place = nil, ""
local WDAY = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local function weekday(date)                          -- „2026-10-01“ → 0 nedeľa … 6 sobota (Sakamoto)
    local y, m, d = date:match("(%d+)-(%d+)-(%d+)")
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if not y then return 0 end
    local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
    if m < 3 then y = y - 1 end
    return (y + y // 4 - y // 100 + y // 400 + t[m] + d) % 7
end
local function deg(v) return math.floor((v or 0) + 0.5) .. "°" end
-- ikony počasia v spúšťači: Tabler (kódy WMO z Open-Meteo)
local function wx_icon(c)
    c = tonumber(c) or 3
    if c == 0 then return G.sun end
    if c == 1 or c == 2 then return G["sun-low"] end
    if c == 45 or c == 48 then return G["cloud-fog"] end
    if c >= 95 then return G["cloud-storm"] end
    if (c >= 71 and c <= 77) or c == 85 or c == 86 then return G["cloud-snow"] end
    if (c >= 51 and c <= 67) or (c >= 80 and c <= 82) then return G["cloud-rain"] end
    return G.cloud
end
local function paint_wx()
    text.wx_place = wx_place ~= "" and wx_place or tr("Weather")
    local d = wxd
    if not d or not d.daily or not d.hourly then text.wx_sum = tr("No forecast yet"); text.wx_icon = ""; model.wx = {}; return end
    local view = tonumber(fact.wx_view) or 0
    local dl, hr = d.daily, d.hourly
    local rain = function(i) local p = dl.precipitation_probability_max and dl.precipitation_probability_max[i]; return p and p > 0 and ("  ·  " .. p .. " %") or "" end
    if view == 0 then
        text.wx_icon = wx_icon(d.current.weather_code)
        text.wx_sum = deg(d.current.temperature_2m) .. "  ·  " .. deg(dl.temperature_2m_max[1]) .. " / " .. deg(dl.temperature_2m_min[1]) .. rain(1)
    elseif view == 1 then
        text.wx_icon = wx_icon(dl.weather_code[2])
        text.wx_sum = deg(dl.temperature_2m_max[2]) .. " / " .. deg(dl.temperature_2m_min[2]) .. rain(2)
    else
        text.wx_icon = G.sun
        local parts = {}
        for i = 2, math.min(6, #dl.time) do parts[#parts + 1] = tr(WDAY[weekday(dl.time[i]) + 1]) .. " " .. deg(dl.temperature_2m_max[i]) end
        text.wx_sum = table.concat(parts, "  ·  ")
    end
    -- Detaily: dnes od tejto hodiny po 3 h, zajtra 0:00…21:00, týždeň po dňoch
    local out = {}
    if view == 2 then
        for i = 1, math.min(8, #dl.time) do
            out[#out + 1] = { label = tr(WDAY[weekday(dl.time[i]) + 1]), glyph = wx_icon(dl.weather_code[i]),
                              temp = deg(dl.temperature_2m_max[i]) .. " / " .. deg(dl.temperature_2m_min[i]) }
        end
    else
        local now = tonumber((d.current.time or ""):match("T(%d+)")) or 0
        local first = view == 0 and now + 1 or 25
        for n = 0, 7 do
            local i = first + n * 3
            if hr.time[i] then
                out[#out + 1] = { label = hr.time[i]:match("T(%d+:%d+)") or "", glyph = wx_icon(hr.weather_code[i]), temp = deg(hr.temperature_2m[i]) }
            end
        end
    end
    model.wx = out
end
on("wx_pick", function() paint_wx() end)
wx_repaint = paint_wx                               -- karta DaNoGoo (kalendár je v súbore vyššie)
local function weather()
    run("cat", { "/var/lib/latteos/greeter/greeter.conf" }, function(conf)
        conf = conf or ""
        local lat = conf:match('lat%s*=%s*"([%d.-]+)"') or "48.74"
        local lon = conf:match('lon%s*=%s*"([%d.-]+)"') or "19.15"
        local place = conf:match('place%s*=%s*"([^"]*)"') or ""
        wx_place = place:match("^[^,]+") or place
        run("curl", { "-s", "-m", "8", "https://api.open-meteo.com/v1/forecast?latitude=" .. lat .. "&longitude=" .. lon
                      .. "&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code"
                      .. "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
                      .. "&timezone=auto&forecast_days=8" }, function(out)
            local ok, d = pcall(json.decode, out or "")
            if ok and d and d.current then
                local t = math.floor((d.current.temperature_2m or 0) + 0.5)
                st.temp = t; wpaint()
                text.weather = wx_glyph(d.current.weather_code or 3) .. "  " .. t .. " °C" .. (place ~= "" and (" · " .. place) or "")
                wxd = d
                text.dn_wx = wx_icon(d.current.weather_code)
                text.dn_temp = t .. "°"
            end
            paint_wx()
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
        tema_file = home .. "/.config/latteos/theme"; read_tema()
        HOME = home
        cfg_file = home .. "/.config/latteos/spustac.json"
        T.file = home .. "/.local/share/latteos/casovace.json"; T.cfg = home .. "/.config"; T.share = home .. "/.local/share"
        load_timers()
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
every(2000, function() read_mode(); read_kava(); read_tema() end)   -- režim sa dá zmeniť aj inde (Super+W, Nastavenia)
