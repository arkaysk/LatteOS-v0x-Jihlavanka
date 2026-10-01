-- engine Goo — logika: register kvapiek. Jedny pravidlá pre všetky kvapky; kvapka je iba DEFINÍCIA (tabuľka)
-- s číslami (povaha) a voliteľnými háčikmi (správanie). Scéna (goo.plm) robí fyziku a vstupy myši, táto vrstva
-- rozhoduje, čo sa stane: klik, pravé a stredné tlačidlo, podržanie, koliesko, prechod, ťahanie a pustenie,
-- nečinnosť. Pravidlá plochy sú v LATTEOS-GOO.md (§2, §3): kontextový klik iba tam, kde ho má funkcia (8) —
-- čo kvapka nemá, nerobí nič; engine za ňu robí iba spoločné veci (ťahanie, prilepenie k lište, uloženie, hra).
--
-- Zdroje kvapiek (README.md):
--   programátor  modul Luau v kvapky/<meno>.luau, vracia definíciu (aj s háčikmi); zoznam.luau = gen.py
--   používateľ   JSON v ~/.config/latteos/goo/kvapky/*.json (latte-goo zoznam); kedykoľvek, bez reštartu
--
-- Definícia (všetko voliteľné okrem id):
--   id, nazov, ikona (meno Tabler alebo znak), text, popis (bublina pri prechode myšou)
--   povaha     "pokojna" | "zvedava" | "lepkava" | "tazka" | "hrava" — balík čísel nižšie
--   velkost    polomer (px)   (farbu nemá: kvapky sú vždy káva podľa Baristu — pravidlo 6)
--   gravitacia 0…1 (kurzor iba priťahuje)   dosah px   vznos 0…1 (nadnesenie pri priblížení kurzora)
--   lepivost 0…1   trhanie px   svetlo 0…1   rast (nafúknutie nad kvapkou)   tahat (bool)
--   hmotnost 0…1 (po pustení padne na lištu)   zoom (bool: koliesko mení veľkosť, ak nemá vlastný háčik)
--   efekt      "dych" "kmit" "tras" "obeh" "tlkot" (+ sila 0…2); rezerva: čísla 6–9 a kanály e1…e4
--   druh       "ikona" | "ukazovatel" (prstenec podľa hodnota 0…1)
--   poloha     { x = 0…1 šírky, y = px nad lištou }   (inak sa kvapky radia zľava po lište)
--   pri, odstup  kvapka vedľa inej o presný odstup v px (napr. PowerGoo 66 px vľavo od TimeGoo)
--   vyska      výška stredu nad lištou v px, keď na nej sedí (inak 0,8 · velkost)
--   vznos      0…2 (1 = nadnesie sa o 0,75 polomeru; PowerGoo v Kvapkách skoro 1,4)
-- Háčiky (funkcie, dostanú kvapku `d`, na ktorej sú metódy nižšie):
--   start(d) · klik(d) · pravy(d) · stredny(d) · podrz(d) · koliesko(d, smer ±1) · nad(d) · prec(d)
--   popis(d) → text bubliny · tahanie(d) · pustenie(d, x, y) → false = nepresúvať · necinnost(d, uroven 0…3)
--   tik(d) každých `kazdych` ms
-- Metódy kvapky: d:text(s) d:ikona(meno) d:hodnota(v) d:nazov(s) d:efekt(meno, sila) d:rezerva(i, v)
--   d:velkost(z) d:presun(x, y) d:domov() d:poskoc() d:bublina(text) d:nastav{…pole = hodnota…}
--   d:jadro(farba, sila, pulz) — farebné jadro (predvolene upozornenie): "hardver" "siet" "softver" "vystraha"
--     "svetlo" "ine"; d:jadro() zhasne · d:vlnka(sila) kameň do vody pri kvapke · d:vibruj(sila)
-- Hladina: E.vlnka(x_px, sila, "kamen"|"vibracia"); zvonka `pleamar --say goo "emit goo_kamen 512"` (x v px),
--   napr. minimalizované okno padne do lišty (pravidlo 14: „žblnkne ako voda“)

local E = {}
local N = 128            -- = gen.py N (miesta v scéne): Goobar nesie okná ako ikry/hrozno, pri veľkej RAM ich je veľa
E.N = N

-- efekty scény (čísla v goo.plm); 6–9 rezerva pre efekty, ktoré ešte nie sú
local EFEKTY = { nic = 0, dych = 1, kmit = 2, tras = 3, obeh = 4, tlkot = 5 }
local DRUHY = { ikona = 0, ukazovatel = 1, hodiny = 2 }
-- jadro: farby upozornení podľa pravidla 15 (červená hardvér, zelená sieť, modrá softvér) + výstraha, svetlo, iné
local JADRO = { hardver = 0, siet = 1, softver = 2, vystraha = 3, svetlo = 4, ine = 5 }
-- povahy: balíky čísel (dajú sa prepísať jednotlivo v definícii)
E.POVAHY = {
    pokojna = { gravitacia = 0.12, lepivost = 0.2, efekt = "dych", sila = 0.6 },
    zvedava = { gravitacia = 0.6, dosah = 280, efekt = "dych", rast = 0.12 },
    lepkava = { gravitacia = 0.25, lepivost = 0.9, trhanie = 120, efekt = "kmit", sila = 0.4 },
    tazka   = { gravitacia = 0.05, hmotnost = 1, lepivost = 0.35, velkost = 30, vznos = 0.5 },
    hrava   = { gravitacia = 0.4, dosah = 240, efekt = "kmit", sila = 0.8, hrava = true },
}
local PREDVOLENE = { velkost = 26, gravitacia = 0.3, dosah = 220, vznos = 1, lepivost = 0, trhanie = 90, svetlo = 0.5,
                     rast = 0.08, tahat = true, hmotnost = 0, efekt = "nic", sila = 1, druh = "ikona", zoom = false }
local ZOOM_MIN, ZOOM_MAX = 0.6, 2.4

local slots = {}          -- k (0…N−1) → kvapka
local byId = {}           -- id → kvapka
local glyphs = {}         -- meno ikony → znak (latte-goo ikony)
local saved = {}          -- id → { x, y, z } (latte-goo stav)
local dirty, publishing = false, false
local Kvapka = {}
Kvapka.__index = Kvapka

local function num(v, d) return type(v) == "number" and v or d end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- meno ikony (napr. "eye", "123") vs. hotový znak písma (jeden znak mimo ASCII, napr. "\u{EA38}")
local function isName(s) return type(s) == "string" and s ~= "" and s:byte(1) < 128 end

-- logika → scéna pre jednu kvapku: `emit` v Luau nenesie hodnotu, preto počítadlo (scéna: on change)
local function bump(name, k)
    local n = name .. "." .. k
    fact[n] = (fact[n] or 0) + 1
end
E.bump = bump

local function hud(s)
    if E.ladenie then text.hud = s end
end

-- ── záznam pre scénu ─────────────────────────────────────────────────────────────────────────────────────────
local function record(d)
    local v = d.v
    local ik = v.ikona or ""
    -- meno ikony → znak (kým nepríde, bez ikony); druh 2 (hodiny) má v poli ikony veľký text, nie ikonu
    if isName(ik) and v.druh ~= 2 then ik = glyphs[ik] or "" end
    return {
        on = true, hx = d.x, ox = d.ox or 0, hy = d.y, r = v.velkost, z = d.z, rast = v.rast,
        grav = clamp(num(v.gravitacia, 0), 0, 1), dosah = v.dosah, vz = clamp(num(v.vznos, 1), 0, 2),
        lep = v.lepivost, trh = v.trhanie, svetlo = v.svetlo, tahat = v.tahat,
        fx = EFEKTY[v.efekt] or num(v.efekt, 0), fa = v.sila,
        e1 = d.e[1], e2 = d.e[2], e3 = d.e[3], e4 = d.e[4],
        druh = DRUHY[v.druh] or num(v.druh, 0), hodnota = num(v.hodnota, 0),
        ikona = ik, text = v.text or "",
        jadro = d.jadroS or 0, jf = d.jadroF or 0, jp = d.jadroP or false,
    }
end

-- susedia na lište: kvapky, ktoré na nej sedia, zoradené zľava; susedné do vzdialenosti ~2,6 súčtu polomerov sa
-- navzájom nadnášajú, nakláňajú a spája ich goo vlákno (ako vypínač ↔ Hodiny ↔ hlava v Kvapkách). Logika nepozná
-- šírku obrazovky: poradie a medzera sa rátajú pri bežnej šírke 1920 px, scéna polohu prepočíta presne.
local NOMINAL_W = 1920
local function neighbours(list)
    local docked = {}
    for _, d in ipairs(list) do
        d.nl, d.nr = nil, nil
        -- ťahaná nie je susedom (inak by k jej starému miestu viselo dlhé vlákno)
        if d.y < d.v.velkost * 1.6 and not d.dragging then table.insert(docked, d) end
    end
    table.sort(docked, function(a, b) return a.x * NOMINAL_W + (a.ox or 0) < b.x * NOMINAL_W + (b.ox or 0) end)
    for i = 1, #docked - 1 do
        local a, b = docked[i], docked[i + 1]
        local gap = (b.x - a.x) * NOMINAL_W + (b.ox or 0) - (a.ox or 0)
        if gap < 2.6 * (a.v.velkost * a.z + b.v.velkost * b.z) then a.nr, b.nl = b, a end
    end
end

local function publish()
    if publishing then dirty = true return end
    publishing = true
    after(16, function()                                 -- viac zmien v jednom kroku = jeden zápis
        local live = {}
        for k = 0, N - 1 do if slots[k] then table.insert(live, slots[k]) end end
        neighbours(live)
        local list = {}
        for k = 0, N - 1 do
            local d = slots[k]
            if d then
                local r = record(d)
                if d.nl then r.nl, r.nlh, r.nlo = true, d.nl.x, d.nl.ox or 0 end
                if d.nr then r.nr, r.nrh, r.nro, r.nry, r.nrr = true, d.nr.x, d.nr.ox or 0, d.nr.y, d.nr.v.velkost * d.nr.z end
                list[k + 1] = r
            else
                list[k + 1] = { on = false }
            end
        end
        model.goo = list
        publishing = false
        if dirty then dirty = false publish() end
    end)
end
E.publish = publish

-- ── uloženie polôh a veľkostí (latte-goo stav / uloz-stav) ─────────────────────────────────────────────────────
local saveTimer
local function save()
    if saveTimer then cancel(saveTimer) end
    saveTimer = after(1200, function()
        saveTimer = nil
        local out = {}
        for id, d in pairs(byId) do
            if d.moved or d.z ~= 1 then out[id] = { x = d.x, y = d.y, z = d.z } end
        end
        run("latte-goo", { "uloz-stav", json.encode(out) }, nil, { output = false })
    end)
end

-- ── metódy kvapky (pre háčiky) ───────────────────────────────────────────────────────────────────────────────
function Kvapka:nastav(t) for key, val in pairs(t) do self.v[key] = val end publish() end
function Kvapka:text(s) self.v.text = s or "" publish() end
function Kvapka:nazov(s) self.v.nazov = s or "" publish() end
function Kvapka:ikona(s) self.v.ikona = s if self.v.druh ~= 2 then E.needGlyph(s) end publish() end
function Kvapka:hodnota(x) self.v.hodnota = x publish() end
function Kvapka:efekt(meno, sila) self.v.efekt = meno self.v.sila = sila or self.v.sila publish() end
function Kvapka:rezerva(i, x) self.e[i] = x publish() end
function Kvapka:velkost(z) self.z = clamp(z, ZOOM_MIN, ZOOM_MAX) publish() save() end
function Kvapka:presun(x, y) self.x, self.y, self.ox = clamp(x, 0.02, 0.98), math.max(0, y), 0 self.moved = true publish() save() end
function Kvapka:domov() self.x, self.y, self.ox, self.z, self.moved = self.hx0, self.hy0, self.ox0, 1, false publish() save() end
function Kvapka:poskoc() bump("hopn", self.k) end
function Kvapka:stlac() bump("sqn", self.k) end
function Kvapka:bublina(s) text.tip = s or "" end
function Kvapka:jadro(farba, sila, pulz)
    if farba == nil then self.jadroS = 0
    else self.jadroS, self.jadroF, self.jadroP = sila or 1, JADRO[farba] or num(farba, 5), pulz ~= false end
    publish()
end
-- poloha kvapky v px (vlnky): šírku obrazovky povie scéna (fact sw)
function Kvapka:px() local w = num(fact.sw, 0) return self.x * (w > 0 and w or 1920) + (self.ox or 0) end
function Kvapka:vlnka(sila) E.vlnka(self:px(), sila or 6, "kamen") end
function Kvapka:vibruj(sila) E.vlnka(self:px(), sila or 3, "vibracia") end

-- ── hladina: vlnky (4 naraz, strieda sa) ───────────────────────────────────────────────────────────────────────
local nextRipple = 0
function E.vlnka(x, sila, druh)
    local i = nextRipple
    nextRipple = (nextRipple + 1) % 4
    fact["rpx." .. i], fact["rpa." .. i], fact["rpk." .. i] = x, sila or 6, druh == "vibracia" and 1 or 0
    bump("rpn", i)
end
on("goo_kamen", function(x) E.vlnka(x, 8, "kamen") end)
on("goo_vibracia", function(x) E.vlnka(x, 3, "vibracia") end)

-- ── registrácia ──────────────────────────────────────────────────────────────────────────────────────────────
local function freeSlot()
    for k = 0, N - 1 do if not slots[k] then return k end end
end

-- miesto na lište pre kvapku bez polohy: zľava doprava, rozostupy podľa veľkosti
local function nextDock()
    local x = 0.06
    if E.prva then x = E.prva end                       -- test: ďalšie kvapky od tohto miesta (trojica ostane sama)
    for k = 0, N - 1 do
        local d = slots[k]
        if d and d.hy0 < d.v.velkost * 1.6 and not d.def.pri then x = math.max(x, d.hx0 + 0.045) end
    end
    return x
end

function E.define(def, zdroj)
    assert(type(def) == "table" and type(def.id) == "string", "kvapka potrebuje id")
    local prev = byId[def.id]                            -- znova (zmenený JSON): ostane, kde ju používateľ nechal
    if prev then
        saved[def.id] = { x = prev.x, y = prev.y, z = prev.z }
        E.remove(def.id)
    end
    local k = freeSlot()
    if not k then log("goo: plno (" .. N .. " miest), kvapka " .. def.id .. " sa nezmestí") return nil end
    local v = {}
    for key, val in pairs(PREDVOLENE) do v[key] = val end
    if def.povaha and E.POVAHY[def.povaha] then for key, val in pairs(E.POVAHY[def.povaha]) do v[key] = val end end
    for key, val in pairs(def) do v[key] = val end
    local d = setmetatable({ id = def.id, k = k, v = v, def = def, zdroj = zdroj or "luau", e = { 0, 0, 0, 0 } }, Kvapka)
    local seat = num(v.vyska, v.velkost * 0.8)          -- výška stredu nad lištou, keď na nej sedí
    local anchor = def.pri and byId[def.pri]
    d.ox0 = 0
    if anchor then                                      -- pri inej kvapke o presný odstup (px)
        d.hx0, d.hy0, d.ox0 = anchor.hx0, seat, (anchor.ox0 or 0) + num(def.odstup, 0)
    elseif type(def.poloha) == "table" then
        d.hx0, d.hy0 = num(def.poloha.x, 0.5), num(def.poloha.y, seat)
    else
        d.hx0, d.hy0 = nextDock(), seat
    end
    local s = saved[def.id]
    d.x, d.y, d.z = s and s.x or d.hx0, s and s.y or d.hy0, s and s.z or 1
    d.ox = s and 0 or d.ox0
    d.moved = s ~= nil
    slots[k], byId[def.id] = d, d
    E.needGlyph(v.ikona)
    if def.kazdych and def.tik then
        d.timer = every(def.kazdych, function() def.tik(d) end)
        def.tik(d)
    end
    if def.start then def.start(d) end
    publish()
    return d
end

function E.remove(id)
    local d = byId[id]
    if not d then return end
    if d.timer then cancel(d.timer) end
    slots[d.k], byId[id] = nil, nil
    publish()
end

function E.get(id) return byId[id] end
function E.each(fn) for k = 0, N - 1 do if slots[k] then fn(slots[k]) end end end

-- ikony: mená → znaky písma Tabler (latte-goo ikony; Noctalia ho má v /usr/share/noctalia)
local wanted, glyphTimer = {}, nil
function E.needGlyph(name)
    if not isName(name) or glyphs[name] then return end
    wanted[name] = true
    if glyphTimer then return end
    glyphTimer = after(50, function()
        glyphTimer = nil
        local names = {}
        for n in pairs(wanted) do table.insert(names, n) end
        wanted = {}
        run("latte-goo", { "ikony", table.unpack(names) }, function(out)
            local ok, t = pcall(json.decode, out or "")
            if ok and type(t) == "table" then for n, g in pairs(t) do glyphs[n] = g end publish() end
        end)
    end)
end

-- ── vstupy zo scény ──────────────────────────────────────────────────────────────────────────────────────────
local function hook(d, name, ...)
    local f = d.def[name]
    if type(f) == "function" then
        local ok, res = pcall(f, d, ...)
        if not ok then log("goo: " .. d.id .. "." .. name .. ": " .. tostring(res)) return true end
        return true, res
    end
    return false
end
E.hook = hook

local function at(k) return slots[k] end

on("goo_click", function(k)
    local d = at(k) if not d then return end
    hud("klik · " .. d.id)
    hook(d, "klik")
end)
on("goo_right", function(k)
    local d = at(k) if not d then return end
    hud("pravé · " .. d.id)
    hook(d, "pravy")                                    -- bez háčika nič (pravidlo 8)
end)
on("goo_middle", function(k)
    local d = at(k) if not d then return end
    hud("stredné · " .. d.id)
    hook(d, "stredny")                                  -- bez háčika nič (pravidlo 8); domov: Nastavenia › Kvapky
end)
on("goo_hold", function(k)
    local d = at(k) if not d then return end
    hud("podržanie · " .. d.id)
    hook(d, "podrz")
end)
on("goo_scroll", function(v)
    local k, up = v // 2, v % 2 == 1
    local d = at(k) if not d then return end
    hud("koliesko " .. (up and "hore" or "dole") .. " · " .. d.id)
    -- veľkosť kolieskom iba kvapky, ktoré ju majú (zoom = true; Goobar a QueenGoo nie)
    if not hook(d, "koliesko", up and 1 or -1) and d.v.zoom then d:velkost(d.z + (up and 0.1 or -0.1)) end
end)
on("goo_enter", function(k)
    local d = at(k) if not d then return end
    hud("nad · " .. d.id)
    hook(d, "nad")
end)
on("goo_leave", function(k)
    local d = at(k) if not d then return end
    hook(d, "prec")
end)
on("goo_hover", function(k)
    local d = at(k) if not d then return end
    -- bublina: názov a popis (obsah kvapky sa hoverom nemení, §3)
    local has, res = hook(d, "popis")
    local p = has and res or d.v.popis
    local n = d.v.nazov or ""
    d:bublina((p and p ~= "" and p ~= n) and (n ~= "" and n .. " · " .. p or p) or n)
end)
on("goo_drag", function(k)
    local d = at(k) if not d then return end
    hud("ťahanie · " .. d.id)
    d.dragging = true
    publish()
    hook(d, "tahanie")
end)
on("goo_drop", function(k)
    local d = at(k) if not d then return end
    local x, y = fact.rx, fact.ry
    d.dragging = false
    local has, res = hook(d, "pustenie", x, y)
    -- lepivosť k lište: blízko nej sa prilepí; ťažká kvapka spadne na lištu (pružina `pada` s odrazom)
    if y < d.v.velkost * d.z * 1.6 or d.v.hmotnost > 0.5 then y = num(d.v.vyska, d.v.velkost * 0.8) * d.z end
    if not (has and res == false) then
        d.x, d.y = clamp(x, 0.02, 0.98), math.max(0, y)
        d.moved, d.ox = true, 0
        save()
    end
    -- vrátila sa k okraju: ponorí sa pod hladinu a vynorí (Marea), hladina sa zvlní
    if d.y < d.v.velkost * d.z * 1.6 then
        bump("dipn", k)
        after(260, function() E.vlnka(d:px(), 4 + d.v.velkost * d.z * 0.12, "kamen") end)
    end
    hud(string.format("pustenie · %s · x %.2f y %d", d.id, d.x, d.y))
    -- domov a ťahanie scény naraz (inak by kvapka na snímok skočila späť)
    fact["dx." .. k], fact["dy." .. k], fact["drg." .. k], fact["tr." .. k] = 0, 0, 0, 0
    fact.nk = -1
    publish()
end)

-- ── nečinnosť: živé bytosti (LATTEOS-GOO.md 3.1) ─────────────────────────────────────────────────────────────────
-- stupeň 1 (1 min) zaspávajú — menšie nadnesenie robí scéna; 2 (3 min) počasie — rezerva, háčik necinnost(d, 2);
-- 3 (6 min) hra hravých kvapiek: naháňačka so zámernou zrážkou a odrazom (squish), behanie po lište, skákanie.
-- Prebudenie hneď: všetky sa zachvejú a vrátia na svoje miesto (poloha z Nastavení sa nemení).
local play
local function stopPlay()
    if play then cancel(play) play = nil end
    E.each(function(d)
        if d.wander then d.x, d.y, d.wander = d.wx, d.wy, nil end
    end)
    publish()
end
local function wander(d)
    if not d.wander then d.wander, d.wx, d.wy = true, d.x, d.y end
end
local function game()
    local players = {}
    E.each(function(d) if d.v.hrava then table.insert(players, d) end end)
    if #players == 0 then return end
    local d = players[math.random(#players)]
    local r = math.random()
    if r < 0.3 then                                          -- skákanie
        d:poskoc()
    elseif r < 0.7 and #players > 1 then                     -- naháňačka: dobehne, zrazí sa, obe sa stlačia, druhá odskočí
        local other = d
        while other == d do other = players[math.random(#players)] end
        wander(d) wander(other)
        local side = d.x < other.x and -1 or 1
        d.x = clamp(other.x + side * 0.025, 0.03, 0.97)
        publish()
        after(650, function()
            if not play then return end
            d:stlac() other:stlac()
            other.x = clamp(other.x - side * 0.08, 0.03, 0.97)
            other:poskoc()
            publish()
        end)
    else                                                     -- behanie po lište
        wander(d)
        d.x = clamp(d.wx + (math.random() - 0.5) * 0.3, 0.03, 0.97)
        publish()
    end
end
on("goo_idle", function(level)
    hud("nečinnosť " .. level)
    E.each(function(d) hook(d, "necinnost", level) end)
    if level == 0 then
        local had = play ~= nil
        stopPlay()
        if had then E.each(function(d) d:stlac() end) end     -- vyrušené: zachvejú sa
        return
    end
    if level >= 3 and not play then
        game()
        play = every(2200, game)
    end
end)

-- ── štart ────────────────────────────────────────────────────────────────────────────────────────────────────
function E.start(opts)
    opts = opts or {}
    E.ladenie = opts.ladenie
    E.prva = opts.prva
    fact.ladenie = opts.ladenie and true or false
    run("latte-goo", { "stav" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then saved = t end
        local defs = {}
        for _, name in ipairs(opts.moduly or {}) do
            local ok2, def = pcall(require, "kvapky/" .. name)
            if ok2 and type(def) == "table" then table.insert(defs, def)
            else log("goo: modul kvapky/" .. name .. ": " .. tostring(def)) end
        end
        -- kvapka `pri` inej prichádza až po nej (PowerGoo po TimeGoo, tá po hlave Goobaru)
        for _ = 1, #defs do
            local rest = {}
            for _, def in ipairs(defs) do
                if def.pri and not byId[def.pri] then table.insert(rest, def) else E.define(def, "luau") end
            end
            defs = rest
            if #defs == 0 then break end
        end
        for _, def in ipairs(defs) do log("goo: " .. def.id .. ": kotva " .. tostring(def.pri) .. " nie je") E.define(def, "luau") end
        if opts.pouzivatel ~= false then require("lib/pouzivatel").start(E, opts) end
        publish()
    end)
    -- káva (pravidlo 6): pomer vody a mlieka z Baristu, ako plocha Kvapky
    local function kava()
        run("latte-goo", { "kava" }, function(out)
            local ok, k = pcall(json.decode, out or "")
            if ok and type(k) == "table" and #k == 2 then
                if fact.voda ~= k[1] then fact.voda = k[1] end
                if fact.mlieko ~= k[2] then fact.mlieko = k[2] end
            end
        end)
    end
    kava()
    every(3000, kava)
end

return E
