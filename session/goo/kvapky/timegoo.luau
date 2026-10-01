-- TimeGoo (Hodiny) ako v ploche Kvapky: polomer 33 (+3 nad ňou), stred 22 px nad okrajom, nadnesie sa o ~24 px,
-- 92 px vľavo od hlavy Goobaru; veľký čas a dátum (druh 2), koliesko mení veľkosť.
-- Ľavý klik = spúšťač. Spúšťač Goo (vyteká z Hodín) je zatiaľ v scéne plochy Kvapky (kvapka.plm), engine volá
-- spúšťač LatteOS (latte-spustac). Pravý klik = ponuka času (časové menu so stopkami a minútkou je zatiaľ v Kvapkách).
local E = require("lib/engine")
local DNI = { "ne", "po", "ut", "st", "št", "pi", "so" }
return {
    id = "timegoo", nazov = "TimeGoo", druh = 2, povaha = "pokojna", velkost = 33, rast = 0.09, vyska = 22,
    vznos = 1, gravitacia = 0.3, dosah = 130, zoom = true, pri = "goobar", odstup = -92,
    kazdych = 10000,
    tik = function(d)
        run("date", { "+%H:%M %w %-d %-m" }, function(out)
            local hm, w, dd, mm = (out or ""):match("(%d+:%d+) (%d) (%d+) (%d+)")
            if hm then d:ikona(hm) d:text(DNI[tonumber(w) + 1] .. " " .. dd .. ". " .. mm .. ".") end
        end)
    end,
    klik = function(d) run("latte-spustac", { "prepni" }) end,
    pravy = function(d)
        E.menu({
            { label = tr("Date and time settings"), glyph = "clock", run = function() run("latte-app", { "nastavenia", "cas" }) end },
            { label = tr("Well-being"), glyph = "heart", run = function() run("latte-app", { "monitor", "pohoda" }) end },
        }, 260)
    end,
    popis = function(d) return tr("left: launcher · wheel: size") end,
}
