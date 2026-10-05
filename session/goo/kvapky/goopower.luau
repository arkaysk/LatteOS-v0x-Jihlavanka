-- GooPower (napájanie a monitor systému, LATTEOS-GOO.md „Nová architektúra“ §1; predtým PowerGoo): základná kvapka.
-- Polomer 19, skoro celý v okraji (stred 3 px nad ním), pri kurzore sa nadnesie najviac zo všetkých (~26 px),
-- 62 px vľavo od LensGoo. Hlavička ponuky ukazuje presné percento batérie a stav nabíjania.
-- Ľavý klik = ponuka Goo (Nastavenia, Monitor | Zamknúť, Odhlásiť, Uspať, Reštartovať, Vypnúť); akcie relácie robí
-- Noctalia. Batéria (notebook): guľky 3 zelené (≥ 60 %), 2 žlté (≥ 30 %), 1 červená; pod 10 % jadro pulzuje,
-- pri nabíjaní dýcha. Na stolnom PC žiadne.
local E = require("lib/engine")
local function session(a) return function() after(200, function() run("noctalia", { "msg", "session", a }) end) end end
return {
    id = "goopower", nazov = "GooPower", zaklad = true, ikona = "power", povaha = "pokojna", velkost = 19, rast = 0.21, vyska = 3,
    vznos = 1.8, gravitacia = 0.3, dosah = 110, zoom = true, pri = "lensgoo", odstup = -62,
    start = function(d)
        sys.watch("battery", function(b)
            if not b or not b.present then d.bat = nil d:gulky(0) d:jadro() return end
            local p = tonumber(b.percent) or 0
            if p >= 60 then d:gulky(3, "siet") elseif p >= 30 then d:gulky(2, "zlta") else d:gulky(1, "hardver") end
            if p < 10 and not b.charging then d:jadro("hardver", 0.8, true) else d:jadro() end
            d:efekt(b.charging and "dych" or "nic", 0.7)
            d.bat = math.floor(p) .. " %" .. (b.charging and " · " .. tr("charging") or "")
        end)
    end,
    klik = function(d)
        local items = {}
        if d.bat then items[1] = { label = tr("Battery") .. " " .. d.bat, glyph = "battery-2", off = true } end
        for _, it in ipairs({
            { label = tr("Settings"), glyph = "settings", run = function() run("latte-app", { "nastavenia" }) end },
            { label = tr("Monitor"), glyph = "chart-bar", run = function() run("latte-app", { "monitor" }) end },
            { label = tr("Lock"), glyph = "lock", sep = true, run = session("lock") },
            { label = tr("Log out"), glyph = "logout", run = session("logout") },
            { label = tr("Sleep"), glyph = "moon", run = session("suspend") },
            { label = tr("Restart"), glyph = "refresh", run = session("reboot") },
            { label = tr("Shut down"), glyph = "power", danger = true, run = session("shutdown") },
        }) do items[#items + 1] = it end
        if d.bat then items[2].sep = true end
        E.menu(items, 230, { owner = d })                                 -- ucho = kvapka GooPower v rohu ponuky
    end,
    popis = function(d) return d.bat or "" end,
}
