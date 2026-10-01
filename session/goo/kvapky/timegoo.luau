-- TimeGoo (Hodiny) ako v ploche Kvapky: polomer 33 (+3 nad ňou), stred 22 px nad okrajom, nadnesie sa o ~24 px,
-- 92 px vľavo od hlavy Goobaru; veľký čas a dátum (druh 2), koliesko mení veľkosť (zoom). Klik v teste iba bublina.
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
    klik = function(d) d:bublina("(test) ľavý klik: spúšťač") end,
    pravy = function(d) d:bublina("(test) pravý klik: časové menu") end,
    popis = function(d) return "koliesko: veľkosť" end,
}
