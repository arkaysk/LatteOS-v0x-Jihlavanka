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
sys.watch("window", function(v) wins = (v and v.list) or {} end)

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

-- relácia LatteOS Kvapky (bez Noctalie): kvapky Štart a vypínač
run("printenv", { "LATTE_VARIANT" }, function(out)
    if (out or ""):match("kvapky") then fact.solo = true end
end)

run("printenv", { "HOME" }, function(out)
    local home = (out or ""):match("[^\n]+")
    if home then state = home .. "/.local/state/latteos/window-mode"; read_mode() end
end)
every(2000, read_mode)   -- režim sa dá zmeniť aj inde (Super+W, Nastavenia)
