-- Goobar (lišta s oknami, LATTEOS-GOO.md 4.1): hlava = obraz režimu okien (plávajúce / dlaždice / páska); vpravo od
-- nej okná ako ikry/hrozno po aplikáciách (lib/goobar.luau). Ľavý klik na hlavu = ďalší režim okien, koliesko =
-- páska sa posúva / ďalšie okno. Rozmery a rozostupy ako v ploche Kvapky (TimeGoo 92 px vľavo, PowerGoo ďalších 66).
local goobar = require("lib/goobar")
return {
    id = "goobar", nazov = "Goobar", ikona = "app-window", povaha = "pokojna", velkost = 44, vyska = 22,
    poloha = { x = 0.42, y = 22 }, gravitacia = 0.25, vznos = 0.7,
    popis = "klik: režim okien · koliesko: ďalšie okno / posun pásky",
    start = function(d) goobar.start() end,
    klik = function(d) goobar.head_click() end,
    koliesko = function(d, smer) goobar.head_wheel(smer) end,
}
