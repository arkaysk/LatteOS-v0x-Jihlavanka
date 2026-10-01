-- DaNoGoo (dátum + upozornenia, LATTEOS-GOO.md 4.2b): dátum v kvapke, guľky počtu — systémové/kritické výstrahy
-- červeno-kávové, ostatné žlté (do 4, nad 4 s počtom); nové upozornenie zvlní hladinu. Ľavý klik = najnovšie
-- upozornenia v ponuke Goo (klik otvorí, „Vymazať všetko“). Hrozno na lepkavom vlákne, odhodenie bobule, počasie
-- a karta kalendára (pravý klik) sú zatiaľ iba v ploche Kvapky. Upozornenia prijíma pleamar — iba jeden proces:
-- v relácii engine test je to táto scéna.
local E = require("lib/engine")
local DNI = { "nedeľa", "pondelok", "utorok", "streda", "štvrtok", "piatok", "sobota" }
local notes, seen = {}, {}

local function paint(d)
    local crit, n = 0, #notes
    for _, x in ipairs(notes) do if (x.urgency or 1) >= 2 then crit = crit + 1 end end
    if n == 0 then d:gulky(0) return end
    d:gulky(n, crit > 0 and "system" or "zlta")
end

return {
    id = "danogoo", nazov = "DaNoGoo", druh = 2, povaha = "pokojna", velkost = 30, vyska = 20,
    poloha = { x = 0.79, y = 20 }, gravitacia = 0.25, kazdych = 30000,
    tik = function(d)
        run("date", { "+%w %-d %-m" }, function(out)
            local w, dd, mm = (out or ""):match("(%d) (%d+) (%d+)")
            if w then d:ikona(dd .. ". " .. mm .. ".") d:text(DNI[tonumber(w) + 1]) end
        end)
    end,
    start = function(d)
        local ok = sys.watch("notifications", function(list)
            notes = list or {}
            local fresh = false
            for _, x in ipairs(notes) do if not seen[x.id] then seen[x.id] = true fresh = true end end
            if fresh then d:vlnka(5) end
            paint(d)
        end)
        -- upozornenia neexpirujú samy (hrozno je centrum upozornení, ako v Kvapkách)
        if ok then pcall(sys.call, "notifications.keep", true) end
    end,
    klik = function(d)
        if #notes == 0 then d:bublina(tr("No notifications")) return end
        local items = {}
        for i, x in ipairs(notes) do
            if i > 8 then break end
            items[#items + 1] = { label = (x.app or "") .. ": " .. (x.title or ""), glyph = (x.urgency or 1) >= 2 and "alert-triangle" or "bell",
                                  run = function() pcall(sys.call, "notifications.invoke", x.id, "default") end }
        end
        items[#items + 1] = { label = tr("Clear all") .. " (" .. #notes .. ")", glyph = "trash", sep = true, danger = true,
                              run = function() pcall(sys.call, "notifications.clear") end }
        E.menu(items, 340)
    end,
    popis = function(d) return #notes .. " " .. tr("notifications") end,
}
