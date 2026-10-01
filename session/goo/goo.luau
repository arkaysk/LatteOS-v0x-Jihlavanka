-- engine Goo — logika skúšobnej scény (relácia „LatteOS Kvapky – engine test“). Celé správanie je v lib/engine.luau;
-- tu sa iba spustí: moduly programátorov (kvapky/zoznam.luau) a kvapky používateľa (+ príklady z priklady/).
local engine = require("lib/engine")
local moduly = require("kvapky/zoznam")

engine.start({
    moduly = moduly,
    priklady = true,      -- test: aj JSON z priklady/ (používateľove sú v ~/.config/latteos/goo/kvapky/)
    ladenie = true,       -- vľavo hore posledná udalosť (klik, koliesko, pustenie…), na overovanie vstupov
})
