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
        if i > 20 then break end
        local k = group_key(w)
        if not groups[k] then groups[k] = {}; first[#first + 1] = k end
        table.insert(groups[k], i)
    end
    local order, used = {}, {}
    for _, k in ipairs(group_order) do if groups[k] and not used[k] then order[#order + 1] = k; used[k] = true end end
    for _, k in ipairs(first) do if not used[k] then order[#order + 1] = k; used[k] = true end end
    local tight = fact.tight == true
    local paska = tostring(fact.mode) == "paska"
    local lay, u = {}, 21                  -- u: ľavý okraj ďalšieho strapca (od hlavy; hlava končí na +36)
    for _, key in ipairs(order) do
        local idx = groups[key]
        local m = #idx
        local r = (paska and 24 or R0) * math.max(0.72, 1 - 0.07 * (m - 1))
        local row = tight or m == 1 or key == hot
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
            local lo, hi = 0, 0
            for j = 1, m do
                local ox = OFFS[j][1] + JIT[j][1]
                lo = math.min(lo, ox); hi = math.max(hi, ox)
            end
            local ax = u + r - lo * r
            for j, i in ipairs(idx) do
                local rr = r * (1 + 0.06 * (((j - 1) * 37) % 5 - 2) / 2)
                local x, y = ax + (OFFS[j][1] + JIT[j][1]) * r, (OFFS[j][2] + JIT[j][2]) * r
                lay[i] = { x = x, y = y, r = rr, icon = icon_of(wins[i]), ax = ax, ay = 0 }
            end
            u = ax + hi * r + r + 12
        end
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
    if wins[i] then win_eval("toggle_by", i) end
end)

-- pravý klik: ponuka okna (apps/ponuka.qml) pri kurzore, pre to okno (najprv dostane fokus)
on("win_menu", function(k)
    local i = (k or 0) + 1
    if not wins[i] then return end
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
            if ok and list and okw and ws and mon then
                local side = tostring(fact.side or "dole")
                for _, w in ipairs(list) do
                    if w.workspace and w.workspace.id == ws.id and w.mapped ~= false and not w.hidden and w.at and w.size then
                        local x, y = w.at[1] - mon.x, w.at[2] - mon.y
                        local gap = ({ dole = mon.height - (y + w.size[2]), hore = y, vlavo = x,
                                       vpravo = mon.width - (x + w.size[1]) })[side] or 999
                        if (w.fullscreen or 0) ~= 0 then gap = 0 end
                        room = math.min(room, gap)
                        if gap < 64 + 16 then tight = true end
                    end
                end
            end
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

-- ── dashboard (vyteká z Hodín) ─────────────────────────────────────────────────
-- Hľadanie aplikácií je úloha Štartu: aplikácie zo služby `apps` (súbory .desktop), ako hľadanie v Marei.
local apps = {}
local found = {}
local function search()
    local q = (text.query or ""):lower()
    fact.typing = q ~= ""
    found = {}
    if q ~= "" then
        local starts, inside = {}, {}
        for _, a in ipairs(apps) do
            local n = (a.name or ""):lower()
            if n:sub(1, #q) == q then starts[#starts + 1] = a
            elseif n:find(q, 1, true) then inside[#inside + 1] = a end
        end
        for _, a in ipairs(starts) do if #found < 6 then found[#found + 1] = a end end
        for _, a in ipairs(inside) do if #found < 6 then found[#found + 1] = a end end
    end
    local out = {}
    for _, a in ipairs(found) do out[#out + 1] = { name = a.name, icon = a.icon } end
    model.results = out
    fact.sel = 0
end
on("text:query", search)

-- pripnuté: ~/.config/latteos/pripnute (id súborov .desktop po riadkoch), inak predvolené
local PINS = { "latteos-subory", "org.mozilla.firefox", "latteos-nastavenia", "latteos-aplikacie" }
local pinned = {}
local pin_ids = PINS
local function paint_pins()
    local by_id = {}
    for _, a in ipairs(apps) do by_id[a.id] = a end
    pinned = {}
    local out = {}
    for _, id in ipairs(pin_ids) do
        local a = by_id[id]
        if a and #pinned < 6 then pinned[#pinned + 1] = a; out[#out + 1] = { name = a.name, icon = a.icon } end
    end
    model.pins = out
end
sys.watch("apps", function(list) apps = list or {}; index_apps(apps); paint_pins(); search(); layout() end)

local function launch(a)
    if a and a.exec then pcall(sys.call, "apps.launch", a.exec) end
    fact.dash = false
end
on("open_result", function(i) launch(found[(i or 0) + 1]) end)
on("pin_open", function(i) launch(pinned[(i or 0) + 1]) end)
on("fact:dash", function(open) if not open then text.query = "" end end)

-- upozornenie v dashboarde: klik = otvoriť (predvolená akcia aplikácie) a zavrieť; „Vymazať všetko“
on("note_open", function(i)
    local n = (model.notes or {})[(i or 0) + 1]
    if not n then return end
    pcall(sys.call, "notifications.invoke", n.id, "default")
    pcall(sys.call, "notifications.dismiss", n.id)
end)
on("notes_clear", function() pcall(sys.call, "notifications.clear") end)

-- rýchle nastavenia: prepína Noctalia (ukáže svoje OSD), „Viac“ otvorí jej ovládacie centrum; hlasitosť priamo
local function noctalia(...) run("noctalia", { "msg", ... }) end
on("qs_wifi", function() noctalia("wifi-toggle") end)
on("qs_bt", function() noctalia("bluetooth-toggle") end)
on("qs_mute", function() noctalia("volume-mute") end)
on("qs_more", function() fact.dash = false; run("latte-app", { "nastavenia" }) end)

-- stránky ovládacieho centra v dashboarde: rovnaké zoznamy ako v scéne (služby), klik = akcia
local nets, bts, outs = {}, {}, {}
sys.watch("network", function(v) nets = (v and v.networks) or {} end)
sys.watch("bluetooth", function(v) bts = (v and v.devices) or {} end)
sys.watch("audio", function(v) outs = (v and v.outputs) or {} end)
on("pg_pick", function(k)
    local i = (k or 0) + 1
    local page = tonumber(fact.page) or 0
    if page == 1 then
        local n = nets[i]
        if not n or n.active then return end
        if n.known or not n.secure then
            pcall(sys.call, "network.connect", n.ssid)
        else
            -- nová zabezpečená sieť potrebuje heslo: to vie Noctalia (jej stránka Wi-Fi)
            fact.dash = false
            after(150, function() noctalia("panel-toggle", "control-center", "wifi") end)
        end
    elseif page == 2 then
        local d = bts[i]
        if not d then return end
        pcall(sys.call, d.connected and "bluetooth.disconnect" or "bluetooth.connect", d.address)
    elseif page == 3 then
        local o = outs[i]
        if o and not o.default then pcall(sys.call, "audio.default", o.id) end
    end
end)
on("qs_vol", function(v) pcall(sys.call, "audio.volume", math.max(0, math.min(1, tonumber(v) or 0))) end)

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
        run("cat", { home .. "/.config/latteos/pripnute" }, function(out)
            local ids = {}
            for line in (out or ""):gmatch("[^\n]+") do
                local id = line:match("^%s*([%w%.%-_]+)")
                if id then ids[#ids + 1] = id end
            end
            if #ids > 0 then pin_ids = ids; paint_pins() end
        end)
    end
end)
every(2000, function() read_mode(); read_kava() end)   -- režim sa dá zmeniť aj inde (Super+W, Nastavenia)
