-- The settings of the Goo desktop itself, as a card: which drops there are, what the goo is made of, the
-- wallpaper, how windows are arranged. What is chosen is kept where each thing keeps it (settings.json in the
-- scene's folder, the user's coffee and wallpaper under ~/.config/latteos) and shows at once.
local E = require("lib/engine")
local card = require("lib/card")
local wm = require("lib/wm")
local bar = require("lib/bar")
local open = require("lib/open")
local M = {}
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local COFFEES = { espresso = "Espresso", ristretto = "Ristretto", lungo = "Lungo", americano = "Americano", macchiato = "Macchiato",
                  cortado = "Cortado", flatwhite = "Flat white", cappuccino = "Cappuccino", latte = "Latte", ["white-coffee"] = N("White coffee") }
local MODES = { [0] = N("Tape"), N("Tiles"), N("Floating windows") }
local SHARE = (function() local ok, v = pcall(sys.ask, "env", "LATTE_SHARE") return ok and type(v) == "string" and v ~= "" and v or "/usr/share/latteos" end)()
local coffees = { chosen = "", all = {} }
local open_main

local function back(d) return { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_main(d) end } end
local function coffee_name(id) return tr(COFFEES[id] or id) end

local function open_coffee(d)
    local rows = { back(d) }
    for i, c in ipairs(coffees.all) do
        local id = c[1]
        rows[#rows + 1] = { label = coffee_name(id), glyph = "cup", on = id == coffees.chosen, line = i == 1, keep = true, run = function()
            run("latte-login", { "coffee", id }, function()
                coffees.chosen = id
                E.tell("emit coffee_changed")
                open_coffee(d)
            end)
        end }
    end
    card.open(rows, { owner = d, id = "settings", width = 300, keep = card.id() == "settings" })
end
local function open_wallpaper(d)
    local tiles = {}
    for i = 1, 4 do
        local path = SHARE .. "/wallpapers/latteos-" .. i .. ".jpg"
        tiles[i] = { label = tostring(i), icon = path, glyph = "photo", run = function() wm.wallpaper(path) end }
    end
    card.open({ back(d), { head = true, label = tr("WALLPAPER"), line = true }, { tiles = tiles, per = 4 } }, { owner = d, id = "settings", width = 300 })
end

open_main = function(d, keep)
    local s = E.settings()
    local rows = { { head = true, label = tr("DROPS") } }
    for _, drop in ipairs(E.optional()) do
        rows[#rows + 1] = { label = drop.name, glyph = "droplet", on = not drop.hidden, keep = true, run = function()
            local hidden = {}
            for _, id in ipairs(type(s.hidden) == "table" and s.hidden or {}) do if id ~= drop.id then hidden[#hidden + 1] = id end end
            if not drop.hidden then hidden[#hidden + 1] = drop.id end
            E.set("hidden", hidden)
            open_main(d, true)
        end }
    end
    rows[#rows + 1] = { label = tr("Put every drop back in its place"), glyph = "arrow-back-up", keep = true, run = function() E.reset_places() end }
    rows[#rows + 1] = { head = true, label = tr("LOOK"), line = true }
    rows[#rows + 1] = { pills = {
        { label = tr("Coffee"), glyph = "cup", on = (tonumber(s.material) or (s.material == "glass" and 1 or 0)) < 0.5, keep = true, run = function() E.set("material", 0) open_main(d, true) end },
        { label = tr("Coffee in glass"), glyph = "glass", on = (tonumber(s.material) or (s.material == "glass" and 1 or 0)) >= 0.5, keep = true, run = function() E.set("material", 1) open_main(d, true) end },
    } }
    rows[#rows + 1] = { label = tr("Lively drops"), line2 = tr("Left alone they fall asleep and show the weather"), glyph = "sparkles", on = s.lively ~= false, keep = true,
                        run = function() E.set("lively", s.lively == false) open_main(d, true) end }
    rows[#rows + 1] = { label = tr("The coffee"), line2 = coffees.chosen ~= "" and coffee_name(coffees.chosen) or "", glyph = "cup", keep = true, more = true,
                        run = function() open_coffee(d) end }
    rows[#rows + 1] = { label = tr("Wallpaper"), glyph = "photo", keep = true, more = true, run = function() open_wallpaper(d) end }
    rows[#rows + 1] = { head = true, label = tr("WINDOWS"), line = true }
    local modes = {}
    for m = 0, 2 do modes[#modes + 1] = { label = tr(MODES[m]), on = bar.mode() == m, keep = true, run = function() wm.set_mode(m) after(300, function() if card.id() == "settings" then open_main(d, true) end end) end } end
    rows[#rows + 1] = { pills = modes }
    rows[#rows + 1] = { label = tr("All settings…"), glyph = "settings", hint = "Win+I", line = true, run = function() after(80, function() open.settings() end) end }
    card.open(rows, { owner = d, id = "settings", width = 360, keep = keep })
end

function M.open(d)
    open_main(d)
    run("latte-login", { "coffees" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" and type(t.all) == "table" then coffees = { chosen = t.chosen or "", all = t.all } end
        if card.id() == "settings" then open_main(d, true) end
    end)
end

return M
