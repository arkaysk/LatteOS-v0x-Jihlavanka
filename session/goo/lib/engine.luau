-- engine Goo — logika: register kvapiek. Jedny pravidlá pre všetky kvapky; kvapka je iba DEFINÍCIA (tabuľka)
-- s číslami (povaha) a voliteľnými háčikmi (správanie). Scéna (goo.plm) robí fyziku a vstupy myši, táto vrstva
-- rozhoduje, čo sa stane: klik, pravé a stredné tlačidlo, podržanie, koliesko, prechod, ťahanie a pustenie,
-- nečinnosť. Čo kvapka nemá, robí engine za ňu (predvolené správanie), takže najmenšia kvapka je jeden riadok.
--
-- Zdroje kvapiek (README.md):
--   programátor  modul Luau v kvapky/<meno>.luau, vracia definíciu (aj s háčikmi); zoznam.luau = gen.py
--   používateľ   JSON v ~/.config/latteos/goo/kvapky/*.json (latte-goo zoznam); kedykoľvek, bez reštartu
--
-- Definícia (všetko voliteľné okrem id):
--   id, nazov, ikona (meno Tabler alebo znak), text, popis (bublina pri prechode myšou)
--   povaha     "pokojna" | "zvedava" | "placha" | "lepkava" | "tazka" | "hrava" — balík čísel nižšie
--   velkost    polomer (px)       farba  "kava" "karamel" "smotana" "cokolada" "visna" "mata" "levandula" "med"
--   gravitacia −1…1 (kurzor priťahuje / odpudzuje)   dosah px   lepivost 0…1   trhanie px   svetlo 0…1
--   rast       zväčšenie pri prechode myšou          tahat (bool)   hmotnost 0…1 (po pustení padne na lištu)
--   efekt      "dych" "kmit" "tras" "obeh" "tlkot" (+ sila 0…2); rezerva: čísla 6–9 a kanály e1…e4
--   druh       "ikona" | "ukazovatel" (prstenec podľa hodnota 0…1)
--   poloha     { x = 0…1 šírky, y = px nad lištou }   (inak sa kvapky radia zľava po lište)
-- Háčiky (funkcie, dostanú kvapku `d`, na ktorej sú metódy nižšie):
--   start(d) · klik(d) · pravy(d) · stredny(d) · podrz(d) · koliesko(d, smer ±1) · nad(d) · prec(d)
--   popis(d) → text bubliny · tahanie(d) · pustenie(d, x, y) → false = nepresúvať · necinnost(d, uroven 0/1/2)
--   tik(d) každých `kazdych` ms
-- Metódy kvapky: d:text(s) d:ikona(meno) d:hodnota(v) d:nazov(s) d:efekt(meno, sila) d:rezerva(i, v)
--   d:velkost(z) d:presun(x, y) d:domov() d:poskoc() d:bublina(text) d:nastav{…pole = hodnota…}

local E = {}
local N = 16
E.N = N

-- farby: rovnaké poradie ako gen.py (FARBY) a goo.plm
local FARBY = { kava = 0, karamel = 1, smotana = 2, cokolada = 3, visna = 4, mata = 5, levandula = 6, med = 7 }
-- efekty scény (čísla v goo.plm); 6–9 rezerva pre efekty, ktoré ešte nie sú
local EFEKTY = { nic = 0, dych = 1, kmit = 2, tras = 3, obeh = 4, tlkot = 5 }
local DRUHY = { ikona = 0, ukazovatel = 1 }
-- povahy: balíky čísel (dajú sa prepísať jednotlivo v definícii)
E.POVAHY = {
    pokojna = { gravitacia = 0.12, lepivost = 0.2, efekt = "dych", sila = 0.6 },
    zvedava = { gravitacia = 0.6, dosah = 280, efekt = "dych", rast = 0.2 },
    placha  = { gravitacia = -0.8, dosah = 200, efekt = "kmit", sila = 0.6, lepivost = 0 },
    lepkava = { gravitacia = 0.25, lepivost = 0.9, trhanie = 120, efekt = "kmit", sila = 0.4 },
    tazka   = { gravitacia = 0.05, hmotnost = 1, lepivost = 0.35, velkost = 30 },
    hrava   = { gravitacia = 0.4, dosah = 240, efekt = "kmit", sila = 0.8, hrava = true },
}
local PREDVOLENE = { velkost = 26, gravitacia = 0, dosah = 220, lepivost = 0, trhanie = 90, svetlo = 0.5, rast = 0.12,
                     tahat = true, hmotnost = 0, farba = "kava", efekt = "nic", sila = 1, druh = "ikona" }
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

local function hud(s)
    if E.ladenie then text.hud = s end
end

-- ── záznam pre scénu ─────────────────────────────────────────────────────────────────────────────────────────
local function record(d)
    local v = d.v
    local ik = v.ikona or ""
    if isName(ik) then ik = glyphs[ik] or "" end        -- meno ikony → znak (kým nepríde, bez ikony)
    return {
        on = true, hx = d.x, hy = d.y, r = v.velkost, z = d.z, rast = v.rast,
        grav = v.gravitacia, dosah = v.dosah, lep = v.lepivost, trh = v.trhanie, svetlo = v.svetlo, tahat = v.tahat,
        farba = FARBY[v.farba] or num(v.farba, 0), fx = EFEKTY[v.efekt] or num(v.efekt, 0), fa = v.sila,
        e1 = d.e[1], e2 = d.e[2], e3 = d.e[3], e4 = d.e[4],
        druh = DRUHY[v.druh] or num(v.druh, 0), hodnota = num(v.hodnota, 0),
        ikona = ik, nazov = v.nazov or "", text = v.text or "",
    }
end

local function publish()
    if publishing then dirty = true return end
    publishing = true
    after(16, function()                                 -- viac zmien v jednom kroku = jeden zápis
        local list = {}
        for k = 0, N - 1 do list[k + 1] = slots[k] and record(slots[k]) or { on = false } end
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
function Kvapka:ikona(s) self.v.ikona = s E.needGlyph(s) publish() end
function Kvapka:hodnota(x) self.v.hodnota = x publish() end
function Kvapka:efekt(meno, sila) self.v.efekt = meno self.v.sila = sila or self.v.sila publish() end
function Kvapka:rezerva(i, x) self.e[i] = x publish() end
function Kvapka:velkost(z) self.z = clamp(z, ZOOM_MIN, ZOOM_MAX) publish() save() end
function Kvapka:presun(x, y) self.x, self.y = clamp(x, 0.02, 0.98), math.max(0, y) self.moved = true publish() save() end
function Kvapka:domov() self.x, self.y, self.z, self.moved = self.hx0, self.hy0, 1, false publish() save() end
function Kvapka:poskoc() emit("goo_hop", self.k) end
function Kvapka:bublina(s) text.tip = s or "" end

-- ── registrácia ──────────────────────────────────────────────────────────────────────────────────────────────
local function freeSlot()
    for k = 0, N - 1 do if not slots[k] then return k end end
end

-- miesto na lište pre kvapku bez polohy: zľava doprava, rozostupy podľa veľkosti
local function nextDock()
    local x = 0.06
    for k = 0, N - 1 do
        local d = slots[k]
        if d and d.docked then x = math.max(x, d.hx0 + 0.055) end
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
    if type(def.poloha) == "table" then
        d.hx0, d.hy0, d.docked = num(def.poloha.x, 0.5), num(def.poloha.y, 0), num(def.poloha.y, 0) < 40
    else
        d.hx0, d.hy0, d.docked = nextDock(), v.velkost * 0.8, true
    end
    local s = saved[def.id]
    d.x, d.y, d.z = s and s.x or d.hx0, s and s.y or d.hy0, s and s.z or 1
    d.moved = s ~= nil and (s.x ~= d.hx0 or s.y ~= d.hy0)
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
    if not hook(d, "pravy") then d:bublina(d.v.nazov ~= "" and d.v.nazov or d.id) end
end)
on("goo_middle", function(k)
    local d = at(k) if not d then return end
    hud("stredné · " .. d.id)
    if not hook(d, "stredny") then d:domov() end        -- predvolené: vrátiť na miesto a pôvodnú veľkosť
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
    if not hook(d, "koliesko", up and 1 or -1) then d:velkost(d.z + (up and 0.1 or -0.1)) end   -- predvolené: veľkosť
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
    local has, res = hook(d, "popis")
    d:bublina(has and res or d.v.popis or d.v.nazov or "")
end)
on("goo_drag", function(k)
    local d = at(k) if not d then return end
    hud("ťahanie · " .. d.id)
    hook(d, "tahanie")
end)
on("goo_drop", function(k)
    local d = at(k) if not d then return end
    local x, y = fact.rx, fact.ry
    local has, res = hook(d, "pustenie", x, y)
    -- lepivosť k lište: blízko nej sa prilepí; ťažká kvapka spadne na lištu (pružina `pada` s odrazom)
    if y < d.v.velkost * d.z * 1.6 or d.v.hmotnost > 0.5 then y = d.v.velkost * d.z * 0.8 end
    if not (has and res == false) then
        d.x, d.y = clamp(x, 0.02, 0.98), math.max(0, y)
        d.moved, d.docked = true, y < d.v.velkost * d.z * 1.6
        save()
    end
    hud(string.format("pustenie · %s · x %.2f y %d", d.id, d.x, d.y))
    -- domov a ťahanie scény naraz (inak by kvapka na snímok skočila späť)
    fact["dx." .. k], fact["dy." .. k], fact["drg." .. k], fact["tr." .. k] = 0, 0, 0, 0
    publish()
end)

-- ── nečinnosť: živé bytosti (LATTEOS-GOO.md 3.1) — hravé kvapky skáču, túlajú sa a naháňajú ─────────────────────
local play
local function stopPlay()
    if play then cancel(play) play = nil end
    E.each(function(d)
        if d.wander then d.x, d.y, d.wander = d.wx, d.wy, nil end
    end)
    publish()
end
on("goo_idle", function(level)
    hud("nečinnosť " .. level)
    E.each(function(d) hook(d, "necinnost", level) end)
    if level == 0 then stopPlay() return end
    if play then return end
    play = every(level == 2 and 1600 or 2600, function()
        local players = {}
        E.each(function(d) if d.v.hrava then table.insert(players, d) end end)
        if #players == 0 then return end
        local d = players[math.random(#players)]
        local r = math.random()
        if r < 0.45 then
            d:poskoc()
        else
            if not d.wander then d.wander, d.wx, d.wy = true, d.x, d.y end
            local other = players[math.random(#players)]
            if other ~= d and r < 0.75 then                        -- naháňačka: dobehne k druhej, tá odskočí
                d.x = clamp(other.x + (math.random() < 0.5 and -0.03 or 0.03), 0.03, 0.97)
                after(700, function() other:poskoc() end)
            else                                                   -- túlanie po lište
                d.x = clamp(d.wx + (math.random() - 0.5) * 0.2, 0.03, 0.97)
            end
            publish()
        end
    end)
end)

-- ── štart ────────────────────────────────────────────────────────────────────────────────────────────────────
function E.start(opts)
    opts = opts or {}
    E.ladenie = opts.ladenie
    fact.ladenie = opts.ladenie and true or false
    run("latte-goo", { "stav" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then saved = t end
        for _, name in ipairs(opts.moduly or {}) do
            local ok2, def = pcall(require, "kvapky/" .. name)
            if ok2 and type(def) == "table" then E.define(def, "luau")
            else log("goo: modul kvapky/" .. name .. ": " .. tostring(def)) end
        end
        if opts.pouzivatel ~= false then require("lib/pouzivatel").start(E, opts) end
        publish()
    end)
end

return E
