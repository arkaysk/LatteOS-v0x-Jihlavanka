-- engine Goo — Goobar (lišta s oknami, LATTEOS-GOO.md 4.1) prenesený z plochy Kvapky (kvapka.luau › layout):
-- každé okno je kvapka enginu (E.upsert) s ikonou aplikácie; okná tej istej aplikácie sa zlepia do strapca ako ikry
-- (prvé pri lište, ďalšie smerom od nej, „náhodne“, ale pre každé poradie rovnako), čím viac okien, tým menšie
-- (do 72 %); myš nad strapcom ho rozvinie do radu. Aktívne okno je plnšie, minimalizované menšie a stlmené.
--
-- POMENOVANIE OKIEN (problém z plochy Kvapky): služba `window` (wlr-foreign-toplevel) dá iba triedu (app_id),
-- titulok a vlastné id — žiadnu adresu Hyprlandu. Skupina a ikona = aplikácia zo spúšťača (služba `apps`, súbory
-- .desktop): podľa StartupWMClass, id spúšťača alebo jeho koncovky (Flatpak: trieda „firefox“, id
-- „org.mozilla.firefox“), inak podľa mena. Aplikácie LatteOS (Quickshell) majú všetky triedu „org.quickshell“ →
-- podľa titulku („Súbory — LatteOS“ = Name spúšťača), kým nedostanú vlastné app_id (ROADMAP). Okno sa v Hyprlande
-- hľadá podľa triedy, titulku a poradia (`nth_of`: terminály majú často rovnaký titulok „~“).
local E = require("lib/engine")
local M = {}

local HEAD = "goobar"
local SLOTS = 96                    -- okien v lište najviac (engine má 128 miest, ostatné kvapky potrebujú svoje)
local R0 = 29
local OFFS = { { 0, 0 }, { 1.72, -0.42 }, { 0.78, -1.62 }, { -0.98, -1.3 }, { 2.28, -1.86 },
               { 0.02, -3.0 }, { 1.62, -3.12 }, { -1.25, -2.85 }, { 2.9, -3.0 }, { 0.85, -4.2 },
               { -0.6, -4.3 }, { 2.2, -4.3 }, { 3.4, -1.1 }, { 0.1, -5.4 }, { 1.55, -5.5 },
               { -1.3, -5.2 }, { 3.1, -4.4 }, { -1.9, -1.9 }, { 0.8, -6.6 }, { 2.4, -6.4 } }
local JIT = { { 0, 0 }, { 0.06, -0.04 }, { -0.05, 0.07 }, { 0.08, 0.03 }, { -0.07, -0.05 },
              { 0.05, 0.06 }, { -0.04, 0.05 }, { 0.07, -0.06 }, { -0.06, 0.04 }, { 0.04, -0.07 },
              { 0.03, 0.05 }, { -0.05, -0.03 }, { 0.06, 0.02 }, { -0.03, -0.06 }, { 0.05, 0.04 },
              { -0.06, 0.03 }, { 0.02, -0.05 }, { 0.04, 0.06 }, { -0.04, -0.04 }, { 0.06, -0.02 } }
local MODE_ICON = { plavajuce = "app-window", dlazdice = "layout-grid", paska = "layout-columns" }

local wins = {}                     -- zoznam okien (služba window), v jej poradí
local hidden = {}                   -- index → minimalizované (plocha special:minimized)
local live = {}                     -- id kvapky okna → true (na zmazanie zatvorených)
local group_order = {}              -- poradie aplikácií, ktoré si používateľ nastavil ťahaním
local spans = {}                    -- kľúč skupiny → stred strapca (px od hlavy)
local hot, hot_gen = nil, 0         -- strapec pod myšou (rozvinutý)
local mode = "plavajuce"

-- ── okno → aplikácia ─────────────────────────────────────────────────────────────────────────────────────────
local apps_by = { wm = {}, id = {}, tail = {}, name = {} }
local function index_apps(list)
    apps_by = { wm = {}, id = {}, tail = {}, name = {} }
    for _, a in ipairs(list or {}) do
        if a.wmclass and a.wmclass ~= "" then apps_by.wm[a.wmclass:lower()] = a end
        if a.id then
            local id = a.id:lower()
            local tail = (id:match("([^%.]+)$") or id)
            apps_by.id[id] = a
            apps_by.tail[tail] = apps_by.tail[tail] or a
        end
        if a.name then apps_by.name[a.name:lower()] = apps_by.name[a.name:lower()] or a end
    end
end
local function latte_title(w) return ((w.title or ""):match("^(.-) — ") or w.title or "") end
function M.app_of(w)
    local c = (w.class or ""):lower()
    if c == "org.quickshell" then return apps_by.name[latte_title(w):lower()] end
    return apps_by.wm[c] or apps_by.id[c] or apps_by.tail[c] or apps_by.name[c]
end
function M.group_key(w)
    local a = M.app_of(w)
    if a then return "app:" .. (a.id or a.name) end
    if (w.class or "") == "org.quickshell" then return "latte:" .. latte_title(w) end
    return w.class or "?"
end
-- ikona zo spúšťača; okno bez spúšťača (aj bez ikony v téme) dostane znak okna (pole `ikona`), nie prázdnu guľu
local function icon_of(w)
    local a = M.app_of(w)
    return (a and a.icon and a.icon ~= "") and a.icon or ""
end
function M.wins() return wins end
local function app_name(w)
    local a = M.app_of(w)
    return (a and a.name) or (w.class ~= "org.quickshell" and w.class) or latte_title(w)
end

-- koľké okno s tou istou triedou a titulkom je okno i (Hyprland ho hľadá rovnako, latte/bars.lua)
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
    if w then run("hyprctl", { "eval", string.format("latte.win.%s(%q, %q, %d)", fn, w.class or "", w.title or "", nth_of(i)) }) end
end

-- ── rozloženie (kvapka.luau › layout, bez okien nad lištou a „tight“ — zatiaľ) ─────────────────────────────────
local function index_of(id) for i, w in ipairs(wins) do if ("w:" .. tostring(w.id or i)) == id then return i end end end

local function layout()
    local groups, first = {}, {}
    local over = #wins > SLOTS
    for i, w in ipairs(wins) do
        if i > SLOTS then break end
        local k = (over and i == SLOTS) and "~viac" or M.group_key(w)
        if not groups[k] then groups[k] = {} first[#first + 1] = k end
        table.insert(groups[k], i)
    end
    local order, used = {}, {}
    for _, k in ipairs(group_order) do if groups[k] and not used[k] then order[#order + 1] = k used[k] = true end end
    for _, k in ipairs(first) do if not used[k] then order[#order + 1] = k used[k] = true end end
    local paska = mode == "paska"
    local lay, u = {}, 52                 -- u: ľavý okraj ďalšieho strapca (px od stredu hlavy, hlava má polomer 44)
    for _, key in ipairs(order) do
        local idx = groups[key]
        local m = #idx
        local r = (paska and 24 or R0) * math.max(0.72, 1 - 0.07 * (m - 1))
        local lo, hi = 0, 0
        for j = 1, math.min(m, #OFFS) do
            local ox = OFFS[j][1] + JIT[j][1]
            lo, hi = math.min(lo, ox), math.max(hi, ox)
        end
        local row = m == 1 or key == hot or m > #OFFS
        if key == hot then r = paska and 24 or R0 end
        if row then
            local step = r * 1.86
            for j, i in ipairs(idx) do lay[i] = { x = u + r + (j - 1) * step, y = 0, r = r } end
            u = u + 2 * r + (m - 1) * step + 12
        else
            local ax = u + r - lo * r
            for j, i in ipairs(idx) do
                local rr = r * (1 + 0.06 * (((j - 1) * 37) % 5 - 2) / 2)
                lay[i] = { x = ax + (OFFS[j][1] + JIT[j][1]) * r, y = (OFFS[j][2] + JIT[j][2]) * r, r = rr }
            end
            u = ax + hi * r + r + 12
        end
    end
    -- šnúra sa musí zmestiť po kraj: všetko sa zmenší rovnakým pomerom (čím viac ikier, tým menšie)
    local head = E.get(HEAD)
    local sw = tonumber(fact.sw) or 0
    if head and sw > 0 then
        local avail = sw * (1 - head.x) - 60
        if u > avail and u > 0 then
            local f = math.max(avail / u, 0.25)
            for _, e in pairs(lay) do e.x = e.x * f e.y = e.y * math.max(f, 0.5) e.r = e.r * math.max(f, 0.5) end
        end
    end
    -- kvapky okien: pridať / zmeniť / zmazať zatvorené
    local now = {}
    for i, w in ipairs(wins) do
        local e = lay[i]
        if e then
            local id = "w:" .. tostring(w.id or i)
            now[id] = true
            local more = over and i == SLOTS
            local r = e.r * (hidden[i] and 0.84 or 1) * (w.active and 1.06 or 1)
            local d = E.upsert({
                id = id, nazov = more and tr("More windows") or (w.title or ""), popis = more and "" or app_name(w),
                obr = more and "preferences-system-windows" or icon_of(w), velkost = r,
                ikona = "app-window",            -- bez spúšťača (žiadna ikona aplikácie): znak okna
                pri = HEAD, odstup = e.x, vyska = r * 0.8 - e.y, povaha = "pokojna",
                gravitacia = 0.15, vznos = 0.55, lepivost = 0.35, rast = 0.1, dosah = 160, okno = i,
                klik = function(dd) M.click(dd) end, pravy = function(dd) M.menu(dd) end,
                nad = function(dd) M.hover(dd) end, prec = function(dd) M.unhover(dd) end,
                pustenie = function(dd, x) return M.drop(dd, x) end,
            })
            if d then d:stlm(hidden[i] and 1 or 0) end
        end
    end
    for id in pairs(live) do if not now[id] then E.remove(id) end end
    live = now
    spans = {}
    for _, key in ipairs(order) do
        local sx, n = 0, 0
        for _, i in ipairs(groups[key]) do sx = sx + (lay[i] and lay[i].x or 0) n = n + 1 end
        spans[#spans + 1] = { key = key, x = n > 0 and sx / n or 0 }
    end
end
M.layout = layout

-- ── vstupy na oknách ─────────────────────────────────────────────────────────────────────────────────────────
-- ľavý klik ako vo Windows: neaktívne okno sa ukáže, aktívne sa minimalizuje (LatteOS plocha special:minimized —
-- Hyprland žiadosť o minimalizáciu z wlr-foreign-toplevel ignoruje); „ďalšie okná“ = prehľad
function M.click(d)
    local i = index_of(d.id)
    if not i then return end
    if #wins > SLOTS and i == SLOTS then run("noctalia", { "msg", "panel-toggle", "latteos/overview:panel" }) return end
    win_eval("toggle_by", i)
end
function M.hover(d)
    local i = index_of(d.id)
    hot_gen = hot_gen + 1
    local key = i and M.group_key(wins[i])
    if key ~= hot then hot = key layout() end
end
function M.unhover(d)
    hot_gen = hot_gen + 1
    local mine = hot_gen
    after(500, function() if mine == hot_gen and hot then hot = nil layout() end end)
end
-- pustená po ťahaní: jej aplikácia sa presunie pred strapec, nad ktorým je (poradie aplikácií), okno ostane v lište
function M.drop(d, x)
    local i = index_of(d.id)
    local head = E.get(HEAD)
    local sw = tonumber(fact.sw) or 1920
    if not i or not head then return false end
    local key = M.group_key(wins[i])
    local rel = (x - head.x) * sw - (head.ox or 0)
    local keys = {}
    for _, sp in ipairs(spans) do if sp.key ~= key then keys[#keys + 1] = sp end end
    local at = #keys + 1
    for k, sp in ipairs(keys) do if rel < sp.x then at = k break end end
    local new = {}
    for k, sp in ipairs(keys) do
        if k == at then new[#new + 1] = key end
        new[#new + 1] = sp.key
    end
    if at > #keys then new[#new + 1] = key end
    group_order = new
    after(30, layout)
    return false
end

-- ponuka okna (pravý klik, ako vo Windows): Obnoviť, Minimalizovať, Maximalizovať, Rozloženie ›, Navrchu,
-- Na plochu ›, Zavrieť — akcie robí Hyprland (latte/okno.lua), okno sa najprv aktivuje, aby malo adresu
function M.menu(d)
    local i = index_of(d.id)
    if not i or (#wins > SLOTS and i == SLOTS) then return end
    win_eval("focus_by", i)
    after(120, function()
        run("hyprctl", { "-j", "activewindow" }, function(out)
            local ok, w = pcall(json.decode, out or "")
            if not ok or type(w) ~= "table" or not w.address then return end
            local a = w.address
            local function q(lua) return function() run("hyprctl", { "eval", lua }) end end
            local function ok_(fn, arg) return q(string.format("latte.okno.%s('%s'%s)", fn, a, arg and ("," .. arg) or "")) end
            local function lay(z, label, glyph) return { label = tr(label), glyph = glyph, run = q(string.format("latte.okno.rozlozenie('%s','%s')", a, z)) } end
            local ws = (type(w.workspace) == "table" and tonumber(w.workspace.id)) or 0
            local desks = {}
            for n = 1, 4 do desks[#desks + 1] = { label = tr("Desktop") .. " " .. n, on = ws == n, run = ok_("na_plochu", n) } end
            desks[#desks + 1] = { label = tr("New desktop"), glyph = "plus", run = ok_("na_plochu", 0) }
            E.menu({
                { label = tr("Restore"), glyph = "arrows-minimize", run = ok_("obnovit") },
                { label = tr("Minimize"), glyph = "minus", run = ok_("minimalizovat") },
                { label = tr("Maximize"), glyph = "square", off = w.fullscreen == 1, run = ok_("maximalizovat") },
                { label = tr("Layout"), glyph = "layout-grid", sub = {
                    lay("lava", "Left half", "layout-sidebar"), lay("prava", "Right half", "layout-sidebar-right"),
                    lay("lh", "Top left", "layout-grid"), lay("ph", "Top right", "layout-grid"),
                    lay("ld", "Bottom left", "layout-grid"), lay("pd", "Bottom right", "layout-grid"),
                    lay("stred", "Center", "focus-centered") } },
                { label = tr("Always on top (all desktops)"), glyph = "pin", on = w.pinned == true, run = ok_("navrchu") },
                { label = tr("Move to desktop"), glyph = "stack-2", sub = desks },
                { label = tr("Close"), glyph = "x", hint = "Alt+F4", danger = true, sep = true, run = ok_("zavriet") },
            }, 320)
        end)
    end)
end

-- ── hlava: režim okien ───────────────────────────────────────────────────────────────────────────────────────
local function read_mode()
    run("latte-goo", { "rezim" }, function(out)
        local m = (out or ""):match("%a+")
        if m and MODE_ICON[m] and m ~= mode then
            mode = m
            local h = E.get(HEAD)
            if h then h:ikona(MODE_ICON[m]) h:nazov(tr(({ plavajuce = "Floating windows", dlazdice = "Tiles", paska = "Tape" })[m])) end
            layout()
        end
    end)
end
-- ľavý klik = ďalší režim okien; koliesko: páska = posun, plávajúce = ďalšie okno (Alt+Tab), dlaždice = nič
function M.head_click() run("hyprctl", { "eval", 'require("latte.windows").cycle()' }, function() after(250, read_mode) end) end
function M.head_wheel(dir)
    if mode == "paska" then
        local px = math.floor((tonumber(fact.sw) or 1920) * 0.25)
        run("hyprctl", { "eval", string.format('hl.dispatch(hl.dsp.layout("move %s%d"))', dir > 0 and "-" or "+", px) })
    elseif mode == "plavajuce" then
        run("hyprctl", { "eval", "latte.win.cycle(" .. dir .. ")" })
    end
end

-- ── minimalizované okná (plocha special:minimized): priradenie cez triedu, titulok a poradie ─────────────────────
local function mark_hidden()
    run("hyprctl", { "-j", "clients" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        if not ok or type(list) ~= "table" then return end
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
        hidden = new
        if changed then layout() end
    end)
end

function M.start()
    sys.watch("apps", function(list) index_apps(list) layout() end)
    -- `window` dá zoznam iba cez wlr-foreign-toplevel (na Hyprlande so záplatou PLEAMAR_GENERIC=window)
    local ok = sys.watch("window", function(v) wins = (v and v.list) or {} layout() end)
    if not ok then log("goobar: tento systém nehlási okná") end
    read_mode()
    every(2000, function() read_mode() mark_hidden() end)
end

return M
