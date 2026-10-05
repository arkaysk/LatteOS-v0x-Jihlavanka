-- ClockGoo (čas, kalendár, upozornenia a pohoda, LATTEOS-GOO.md „Nová architektúra“ §2): voliteľná kvapka, ktorá
-- spája čas a centrum upozornení (predtým TimeGoo a DaNoGoo). V kvapke veľký čas a dátum; guľky počtu upozornení —
-- systémové/kritické červeno-kávové, ostatné žlté (do 4, nad 4 s počtom); nové upozornenie zvlní hladinu.
-- Ľavý klik = HROZNO UPOZORNENÍ: kvapka sa vymrští od okraja a nechá za sebou visieť kapsuly na lepkavom vlákne
-- (najnovšie hore, najviac 8). Bobuľa: ľavý = otvoriť, pravý = akcie (ak má), odtiahnutie = zahodiť. Zavrie ho klik
-- na kvapku alebo mimo. Kritické a systémové majú červené jadro. Pravý klik = čas a pohoda.
-- Karta z kvapky (stopky, minútka, budíky, kalendár, počasie) je zatiaľ v scéne plochy Kvapky. Upozornenia prijíma
-- pleamar — iba jeden proces.
local E = require("lib/engine")
local DNI = { "ne", "po", "ut", "st", "št", "pi", "so" }
local notes, seen = {}, {}
-- hrozno: polomer bobule, polovica rovnej časti kapsuly, rozostup a výška prvej nad okrajom (nad hlavou GooBaru)
local R, KW, STEP, Y0, MAX = 19, 118, 46, 96, 8
local open, shown = false, {}

local function close(d)
    if not open then return end
    open = false
    for id in pairs(shown) do E.remove(id) end
    shown = {}
    fact.hr_open = false
    if d.yRest then d.y, d.yRest = d.yRest, nil end
    d:stlac()
    E.publish()
end

local function hang(d)
    local edge = d.edge or 0
    local n = math.min(#notes, MAX)
    if n == 0 or edge % 2 == 1 then close(d) return false end       -- na bočnom okraji hrozno nie je (ponuka)
    local len, sh = E.len(d), tonumber(fact.sh) or 1080
    -- kapsuly sa musia zmestiť na obrazovku a nesmú do rohovej lišty Noctalie
    local hi = math.min(len - 10, E.hiAlong(d) + d.v.velkost * d.z)
    local ax = math.max(KW + R + 10, math.min(E.along(d), hi - KW - R))
    local keep = {}
    for i = 1, n do
        local x = notes[i]                                            -- služba ich dáva od najnovšieho
        local id = "nt:" .. tostring(x.id)
        local crit = (x.urgency or 1) >= 2
        local body = tostring(x.body or ""):gsub("%s+", " ")
        local acts = type(x.actions) == "table" and x.actions or {}
        keep[id] = true
        local c = E.upsert({
            id = id, nazov = x.app or "", velkost = R, kw = KW, visi = true, okraj = edge,
            poloha = { x = ax / len, y = Y0 + (n - i) * STEP },
            gravitacia = 0, vznos = 0, dosah = 1, rast = 0.04, svetlo = 0.3, mlaka = 0, zliatie = 0.6,
            ikona = crit and "alert-triangle" or "bell", obr = (x.icon or "") ~= "" and x.icon or nil,
            text = ((x.app or "") ~= "" and x.app .. " · " or "") .. (x.title or ""), t2 = body,
            klik = function()
                pcall(sys.call, "notifications.invoke", x.id, "default")
                pcall(sys.call, "notifications.dismiss", x.id)
            end,
            pravy = #acts > 0 and function()
                local items = {}
                for _, a in ipairs(acts) do
                    items[#items + 1] = { label = a.label or a.key or "", glyph = "chevron-right", run = function()
                        pcall(sys.call, "notifications.invoke", x.id, a.key)
                        pcall(sys.call, "notifications.dismiss", x.id)
                    end }
                end
                items[#items + 1] = { label = tr("Dismiss"), glyph = "x", sep = true, run = function() pcall(sys.call, "notifications.dismiss", x.id) end }
                E.menu(items, 260)
            end or nil,
            -- odtiahnutá preč = zahodená; inak sa vráti na vlákno
            pustenie = function(c, X, Y)
                local cy = edge == 0 and (sh - 6 - c.y) or (6 + c.y)
                if math.abs(X - ax) > KW + 60 or math.abs(Y - cy) > 70 then pcall(sys.call, "notifications.dismiss", x.id) end
                return false
            end,
        })
        if c then if crit then c:jadro("hardver", 0.75, false) else c:jadro() end end
    end
    for id in pairs(shown) do if not keep[id] then E.remove(id) end end
    shown = keep
    -- kvapka nad hroznom, lepkavé vlákno od okraja k nej
    if not d.yRest then d.yRest = d.y end
    d.y = Y0 + n * STEP + 14
    fact.vlx = E.along(d)
    fact.vly0 = edge == 0 and sh - 6 or 6
    fact.vly1 = edge == 0 and sh - 6 - d.y or 6 + d.y
    fact.hr_open = true
    E.publish()
    return true
end

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
            if open then hang(d) end                                  -- otvorené hrozno sleduje zoznam
        end)
        -- upozornenia neexpirujú samy (kvapka je centrum upozornení, ako v Kvapkách)
        if ok then pcall(sys.call, "notifications.keep", true) end
        on("hr_close", function() close(d) end)
    end,
    klik = function(d)
        if open then close(d) return end
        if #notes == 0 then d:bublina(tr("No notifications")) return end
        open = true
        if hang(d) then d:poskoc() return end
        -- bočný okraj: zoznam v ponuke Goo
        open = false
        local items = {}
        for i, x in ipairs(notes) do                            -- služba ich dáva od najnovšieho: najnovšie hore
            if i > MAX then break end
            items[#items + 1] = { label = (x.app or "") .. ": " .. (x.title or ""), glyph = (x.urgency or 1) >= 2 and "alert-triangle" or "bell",
                                  run = function() pcall(sys.call, "notifications.invoke", x.id, "default") end }
        end
        items[#items + 1] = { label = tr("Clear all") .. " (" .. #notes .. ")", glyph = "trash", sep = true, danger = true,
                              run = function() pcall(sys.call, "notifications.clear") end }
        E.menu(items, 340)
    end,
    -- počas otvoreného hrozna sa kvapka neťahá inam (ostane nad ním)
    pustenie = function(d) if open then return false end end,
    pravy = function(d)
        local items = {}
        if #notes > 0 then
            items[1] = { label = tr("Clear all") .. " (" .. #notes .. ")", glyph = "trash", danger = true,
                         run = function() pcall(sys.call, "notifications.clear") end }
        end
        for _, it in ipairs({
            { label = tr("Well-being"), glyph = "heart", run = function() run("latte-app", { "monitor", "pohoda" }) end },
            { label = tr("Date and time settings"), glyph = "clock", sep = true, run = function() run("latte-app", { "nastavenia", "cas" }) end },
        }) do items[#items + 1] = it end
        if #notes > 0 then items[2].sep = true end
        E.menu(items, 260)
    end,
    popis = function(d)
        return (#notes > 0 and (#notes .. " " .. tr("notifications") .. " · ") or "") .. tr("left: notifications · right: time and calendar")
    end,
}
