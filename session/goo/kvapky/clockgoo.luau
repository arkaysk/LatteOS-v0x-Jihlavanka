-- ClockGoo (čas, kalendár, upozornenia a pohoda, LATTEOS-GOO.md „Nová architektúra“ §2): voliteľná kvapka, ktorá
-- spája čas a centrum upozornení (predtým TimeGoo a DaNoGoo). V kvapke veľký čas a dátum; guľky počtu upozornení —
-- systémové/kritické červeno-kávové, ostatné žlté (do 4, nad 4 s počtom); nové upozornenie zvlní hladinu.
-- Ľavý klik = upozornenia (najnovšie hore; „Vymazať všetko“), pravý = čas, kalendár a pohoda.
-- Hrozno upozornení na lepkavom vlákne a karta z kvapky (stopky, minútka, budíky, kalendár, počasie) sú zatiaľ
-- v scéne plochy Kvapky; engine ich ukazuje v ponuke Goo. Upozornenia prijíma pleamar — iba jeden proces.
local E = require("lib/engine")
local DNI = { "ne", "po", "ut", "st", "št", "pi", "so" }
local notes, seen = {}, {}

local function paint(d)
    local crit, n = 0, #notes
    for _, x in ipairs(notes) do if (x.urgency or 1) >= 2 then crit = crit + 1 end end
    if n == 0 then d:gulky(0) return end
    d:gulky(n, crit > 0 and "system" or "zlta")
end

return {
    id = "clockgoo", nazov = "ClockGoo", druh = 2, povaha = "pokojna", velkost = 33, rast = 0.09, vyska = 22,
    poloha = { x = 0.79, y = 22 }, gravitacia = 0.25, dosah = 130, zoom = true,
    kazdych = 10000,
    tik = function(d)
        run("date", { "+%H:%M %w %-d %-m" }, function(out)
            local hm, w, dd, mm = (out or ""):match("(%d+:%d+) (%d) (%d+) (%d+)")
            if hm then d:ikona(hm) d:text(DNI[tonumber(w) + 1] .. " " .. dd .. ". " .. mm .. ".") end
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
        -- upozornenia neexpirujú samy (kvapka je centrum upozornení, ako v Kvapkách)
        if ok then pcall(sys.call, "notifications.keep", true) end
    end,
    klik = function(d)
        if #notes == 0 then d:bublina(tr("No notifications")) return end
        local items = {}
        for i, x in ipairs(notes) do                            -- služba ich dáva od najnovšieho: najnovšie hore
            if i > 8 then break end
            items[#items + 1] = { label = (x.app or "") .. ": " .. (x.title or ""), glyph = (x.urgency or 1) >= 2 and "alert-triangle" or "bell",
                                  run = function() pcall(sys.call, "notifications.invoke", x.id, "default") end }
        end
        items[#items + 1] = { label = tr("Clear all") .. " (" .. #notes .. ")", glyph = "trash", sep = true, danger = true,
                              run = function() pcall(sys.call, "notifications.clear") end }
        E.menu(items, 340)
    end,
    pravy = function(d)
        E.menu({
            { label = tr("Well-being"), glyph = "heart", run = function() run("latte-app", { "monitor", "pohoda" }) end },
            { label = tr("Date and time settings"), glyph = "clock", sep = true, run = function() run("latte-app", { "nastavenia", "cas" }) end },
        }, 260)
    end,
    popis = function(d)
        return (#notes > 0 and (#notes .. " " .. tr("notifications") .. " · ") or "") .. tr("left: notifications · right: time and calendar")
    end,
}
