-- LensGoo (univerzálny spúšťač a lupa, LATTEOS-GOO.md „Nová architektúra“ §1): základná kvapka s lupou — hľadanie,
-- spúšťač a AI. Stojí na mieste Štartu: 88 px vľavo od hlavy GooBaru, GooPower vľavo od nej (trojica sa prelieva).
-- Ľavý klik = spúšťač. Okno spúšťača z kvapky (režimy Aplikácie, Súbory, Web, Terminál, AI) je zatiaľ v scéne plochy
-- Kvapky (kvapka.plm); engine otvára spúšťač LatteOS (latte-spustac).
return {
    id = "lensgoo", nazov = "LensGoo", zaklad = true, ikona = "search", povaha = "pokojna", velkost = 30, rast = 0.09,
    vyska = 21, vznos = 1, gravitacia = 0.3, dosah = 130, zoom = true, pri = "goobar", odstup = -88,
    klik = function(d) run("latte-spustac", { "prepni" }) end,
    popis = function(d) return tr("search, apps, files, web, AI") end,
}
