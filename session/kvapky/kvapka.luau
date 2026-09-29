-- Logika Kvapky: iba fakty a príkazy. Zoznam okien plní služba `window` priamo v scéne (model wins),
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

local function windows()
    local out = {}
    for _, w in ipairs(model.wins or {}) do
        if not w.minimized then table.insert(out, w) end
    end
    return out
end

on("cycle", function()
    run("hyprctl", { "eval", 'require("latte.windows").cycle()' }, function() after(250, read_mode) end)
end)

on("pick", function(k)
    local w = (model.wins or {})[(k or 0) + 1]
    if w then pcall(sys.call, "window.activate", w.id) end
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
