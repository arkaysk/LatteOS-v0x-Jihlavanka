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

-- ── strapce okien (ikry) ──────────────────────────────────────────────────────
-- Okná tej istej aplikácie sa zlepia do strapca: prvé sedí pri lište, ďalšie sa lepia smerom od nej (ako ikry),
-- „náhodne“, ale pre každé poradie rovnako, aby strapec pri prekreslení neskákal. Čím viac okien, tým menšie
-- guľôčky (do 72 %, aby sa dali trafiť myšou). Myš nad strapcom ho rozvinie do radu v plnej veľkosti; keď
-- aktívne okno siaha k lište (fact.tight), všetko sa zrovná do jedného radu v páse.
local R0 = 29
local OFFS = { { 0, 0 }, { 1.72, -0.42 }, { 0.78, -1.62 }, { -0.98, -1.3 }, { 2.28, -1.86 },
               { 0.02, -3.0 }, { 1.62, -3.12 }, { -1.25, -2.85 }, { 2.9, -3.0 }, { 0.85, -4.2 } }
local JIT = { { 0, 0 }, { 0.06, -0.04 }, { -0.05, 0.07 }, { 0.08, 0.03 }, { -0.07, -0.05 },
              { 0.05, 0.06 }, { -0.04, 0.05 }, { 0.07, -0.06 }, { -0.06, 0.04 }, { 0.04, -0.07 } }
local hot = nil          -- aplikácia, ktorej strapec je pod myšou (rozvinutý)
local hot_gen = 0

-- skupina: aplikácia; aplikácie LatteOS sú zatiaľ všetky „org.quickshell“ → rozlíšiť podľa titulku („Súbory — LatteOS“)
local function group_key(w)
    local c = w.class or ""
    if c == "org.quickshell" then return "latte:" .. ((w.title or ""):match("^(.-) — ") or w.title or "") end
    return c
end

function layout()
    local groups, order = {}, {}
    for i, w in ipairs(wins) do
        if i > 10 then break end
        local k = group_key(w)
        if not groups[k] then groups[k] = {}; order[#order + 1] = k end
        table.insert(groups[k], i)
    end
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
        if row then
            local step = r * 1.86
            for j, i in ipairs(idx) do lay[i] = { x = u + r + (j - 1) * step, y = 0, r = r } end
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
                lay[i] = { x = ax + (OFFS[j][1] + JIT[j][1]) * r, y = (OFFS[j][2] + JIT[j][2]) * r, r = rr }
            end
            u = ax + hi * r + r + 12
        end
    end
    model.lay = lay
    fact.chain_w = math.max(50, u - 12)
end

sys.watch("window", function(v) wins = (v and v.list) or {}; layout() end)
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

local function windows()
    local out = {}
    for _, w in ipairs(wins) do
        if not w.minimized then table.insert(out, w) end
    end
    return out
end

on("cycle", function()
    run("hyprctl", { "eval", 'require("latte.windows").cycle()' }, function() after(250, read_mode) end)
end)

-- hrbolček s oknom, ľavý klik: ako vo Windows — neaktívne okno sa ukáže, aktívne sa minimalizuje.
-- Minimalizuje LatteOS (plocha special:minimized, latte/bars.lua), nie protokol: Hyprland žiadosť o minimalizáciu
-- z wlr-foreign-toplevel ignoruje. Okno sa hľadá podľa triedy a titulku (adresy Hyprlandu zoznam nemá).
local function win_eval(fn, w)
    run("hyprctl", { "eval", string.format("latte.win.%s(%q, %q)", fn, w.class or "", w.title or "") })
end
on("pick", function(k)
    local w = wins[(k or 0) + 1]
    if w then win_eval("toggle_by", w) end
end)

-- pravý klik: ponuka okna (apps/ponuka.qml) pri kurzore, pre to okno (najprv dostane fokus)
on("win_menu", function(k)
    local w = wins[(k or 0) + 1]
    if not w then return end
    win_eval("focus_by", w)
    local x, y = math.floor(fact["menu.x"] or 0), math.floor(fact["menu.y"] or 0)
    after(150, function() run("latte-ponuka", { "okno", tostring(x), tostring(y) }) end)
end)

-- koliesko nad očami: páska = posun (fokus doľava/doprava posúva scrolling layout Hyprlandu),
-- plávajúce = ďalšie/predošlé okno ako Alt+Tab, dlaždice = nič
on("wheel_turn", function(d)
    local dir = (d or 0) > 0 and 1 or -1
    if mode == "paska" then
        run("hyprctl", { "eval", 'hl.dispatch(hl.dsp.focus({ direction = "' .. (dir > 0 and "r" or "l") .. '" }))' })
    elseif mode == "plavajuce" then
        local list = windows()
        if #list == 0 then return end
        local cur = 1
        for i, w in ipairs(list) do if w.active then cur = i end end
        local nxt = ((cur - 1 + dir) % #list) + 1
        pcall(sys.call, "window.activate", list[nxt].id)
    end
end)

on("start_open", function() run("latte-spustac", { "prepni" }) end)
on("power_open", function() run("latte-ponuka", { "vypnut" }) end)

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
local mon = nil
run("hyprctl", { "-j", "monitors" }, function(out)
    local ok, ms = pcall(json.decode, out or "")
    if ok and ms then for _, m in ipairs(ms) do if m.focused then mon = m end end end
end)
local function check_tight()
    run("hyprctl", { "-j", "activewindow" }, function(out)
        local ok, w = pcall(json.decode, out or "")
        local tight = false
        if ok and w and w.at and w.size and mon then
            local x, y = w.at[1] - mon.x, w.at[2] - mon.y
            local side = tostring(fact.side or "dole")
            local gap = ({ dole = mon.height - (y + w.size[2]), hore = y, vlavo = x, vpravo = mon.width - (x + w.size[1]) })[side] or 999
            tight = (w.fullscreen or 0) ~= 0 or gap < 64 + 16
        end
        if fact.tight ~= tight then fact.tight = tight end
    end)
end
every(700, check_tight)

-- relácia LatteOS Kvapky (bez Noctalie): kvapky Štart a vypínač
run("printenv", { "LATTE_VARIANT" }, function(out)
    if (out or ""):match("kvapky") then fact.solo = true end
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
    end
end)
every(2000, function() read_mode(); read_kava() end)   -- režim sa dá zmeniť aj inde (Super+W, Nastavenia)
