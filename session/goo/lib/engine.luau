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
local ZOOM_MIN, ZOOM_MAX = 1, 2.2          -- veľkosť 100–220 % (Nastavenia › Kvapky; ako koliesko v ploche Kvapky)

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

-- okraj kvapky (d.edge): 0 dole, 1 vľavo, 2 hore, 3 vpravo. d.x je zlomok DĹŽKY okraja, d.y vzdialenosť od neho (px)
local function side(d) return (d.edge or 0) % 2 == 1 end
local function elen(d)
    local l = num(side(d) and fact.sh or fact.sw, 0)
    return l > 0 and l or (side(d) and 1080 or 1920)
end
local function along(d) return d.x * elen(d) + (d.ox or 0) end
E.len, E.along = elen, along

-- rohová lišta Noctalie (latte-goo okna › roh, vpravo dole) je pre Goo ZAKÁZANÁ ZÓNA (používateľ 5. 10.): má
-- premenlivú šírku — pribúdajú do nej widgety a doplnky Noctalie — preto sa číta priebežne a kvapky jej ustúpia.
-- „Lišta sa zmestí po kraj obrazovky a zastaví pred rohovými prvkami“ (Nová architektúra, GooBar)
local roh = nil
local function hiAlong(d)                                -- najďalej pozdĺž okraja, kam smie stred kvapky (px)
    local l = elen(d)
    local hi, r = 0.98 * l, d.v.velkost * d.z
    if roh and (roh.w or 0) > 0 then
        if (d.edge or 0) == 0 and roh.x > l * 0.5 then hi = math.min(hi, roh.x - 8 - r) end
        if (d.edge or 0) == 3 and roh.y > l * 0.5 then hi = math.min(hi, roh.y - 8 - r) end
    end
    return hi
end
E.hiAlong = hiAlong

-- ── záznam pre scénu ─────────────────────────────────────────────────────────────────────────────────────────
local function record(d)
    local v = d.v
    local ik = v.ikona or ""
    -- meno ikony → znak (kým nepríde, bez ikony); druh 2 (hodiny) má v poli ikony veľký text, nie ikonu
    if isName(ik) and v.druh ~= 2 then ik = glyphs[ik] or "" end
    return {
        on = not d.hidden, hx = d.x, ox = d.ox or 0, hy = d.y, r = v.velkost, z = d.z, rast = v.rast,
        grav = clamp(num(v.gravitacia, 0), 0, 1), dosah = v.dosah, vz = clamp(num(v.vznos, 1), 0, 2),
        lep = v.lepivost, trh = v.trhanie, svetlo = v.svetlo, tahat = v.tahat,
        fx = EFEKTY[v.efekt] or num(v.efekt, 0), fa = v.sila,
        e1 = d.e[1], e2 = d.e[2], e3 = d.e[3], e4 = d.e[4],
        druh = DRUHY[v.druh] or num(v.druh, 0), hodnota = num(v.hodnota, 0),
        ikona = ik, text = v.text or "",
        jadro = d.jadroS or 0, jf = d.jadroF or 0, jp = d.jadroP or false,
        obr = v.obr or "", img = (v.obr or "") ~= "", tlm = d.tlm or 0,
        gn = d.gn or 0, gf = d.gf or 0, gt = d.gt or "", sk = num(v.sk, 0), zl = num(v.zliatie, 1), ml = num(v.mlaka, 1),
        ed = d.edge or 0, nad = v.koruna and (glyphs[v.koruna] or "") or "",
    }
end

-- susedia na lište: kvapky, ktoré na nej sedia, zoradené zľava; susedné do vzdialenosti ~2,6 súčtu polomerov sa
-- navzájom nadnášajú, nakláňajú a spája ich goo vlákno (ako vypínač ↔ Hodiny ↔ hlava v Kvapkách). Logika nepozná
-- šírku obrazovky: poradie a medzera sa rátajú pri bežnej šírke 1920 px, scéna polohu prepočíta presne.
local NOMINAL_W = 1920
-- najväčšia vzdialenosť stredov, na ktorú sa susedia ešte spoja vláknom (v súčtoch polomerov); ďalej sa pretrhne.
-- Používateľ 5. 10.: vzdialenosť krajných kvapiek na jeho snímke (~2,3) „nech je maximum“ (bolo 2,6)
local THREAD_MAX = 2.3
local function neighbours(list)
    local docked = {}
    for _, d in ipairs(list) do
        d.nl, d.nr = nil, nil
        -- ťahaná nie je susedom (inak by k jej starému miestu viselo dlhé vlákno)
        if d.y < d.v.velkost * 1.6 and not d.dragging and not d.hidden then table.insert(docked, d) end
    end
    table.sort(docked, function(a, b)
        if (a.edge or 0) ~= (b.edge or 0) then return (a.edge or 0) < (b.edge or 0) end
        return along(a) < along(b)
    end)
    -- susedia iba v rámci jedného goo tela: ikry Goobaru (sk 1) s hlavou (sk 2) a navzájom, ostatné (sk 0) s hlavou
    local function same_body(a, b)
        local x, y = num(a.v.sk, 0), num(b.v.sk, 0)
        return x == y or x == 2 or y == 2
    end
    for i = 1, #docked - 1 do
        local a, b = docked[i], docked[i + 1]
        local gap = along(b) - along(a)
        if (a.edge or 0) == (b.edge or 0) and same_body(a, b) and gap < THREAD_MAX * (a.v.velkost * a.z + b.v.velkost * b.z) then a.nr, b.nl = b, a end
    end
end

-- ── kvapky sa nikdy úplne neprekryjú (pravidlo 22) ───────────────────────────────────────────────────────────
-- Dve kvapky smú byť pri sebe a zlievať sa, ale stredy musia ostať aspoň 0,72 súčtu polomerov od seba. Ak nie (napr.
-- jedna pustená na druhú), jedna sa plynule odsunie: kvapka na lište pozdĺž lišty, voľná smerom od druhej. Ustúpi
-- tá, ktorú možno posunúť — nie okná Goobaru (rozloženie) ani kvapky pripnuté k inej (TimeGoo, PowerGoo); z dvoch
-- posunuteľných ustúpi tá, na ktorú niečo pustili. Odsunutie sa reťazí (najviac 10 kôl) a uloží.
local save                 -- nižšie (uloženie polôh)
-- mená kvapiek pred „Novou architektúrou“ (5. 10.): uložená poloha a veľkosť prejdú na novú kvapku
local STARE = { lensgoo = "timegoo", clockgoo = "danogoo", goopower = "powergoo" }
local MIN_GAP = 0.95        -- stredy aspoň 0,95 súčtu polomerov: dotýkajú sa a zlievajú, neprekrývajú (pri 0,72 veľká
                            -- kvapka malú skoro celú zakryla: TimeGoo pod hlavou Goobaru, latte-lab 5. 10.)
local GAP_IKRY = 1.2        -- cudzia kvapka pri ikrách okien: mimo dosahu zliatia (ikry sa lepia iba ku Goobaru)
local sepDirty, sepPrefer = false, nil
local function movable(d) return not d.def.pri and d.zdroj ~= "dyn" and not d.dragging end
local function separate()
    local sw = num(fact.sw, 0)
    if sw <= 0 then sw = 1920 end
    local list = {}
    for k = 0, N - 1 do if slots[k] and not slots[k].hidden then table.insert(list, slots[k]) end end
    local moved = {}
    -- pred rohovou lištou sa kvapka zastaví (nie ikry — tie rozkladá Goobar po voľnú dĺžku)
    for _, d in ipairs(list) do
        if d.zdroj ~= "dyn" and not d.dragging and d.y < d.v.velkost * d.z * 1.6 and along(d) > hiAlong(d) + 0.5 then
            d.x = (hiAlong(d) - (d.ox or 0)) / elen(d)
            moved[d] = true
        end
    end
    for _ = 1, 10 do
        local any = false
        for i = 1, #list do
            for j = i + 1, #list do
                local a, b = list[i], list[j]
                -- všetky kvapky sú v jednom goo tele. Ikry okien (sk 1) rozkladá Goobar: medzi sebou a s jeho
                -- hlavou (sk 2) sa neodsúvajú; cudzia kvapka od nich ustúpi ďalej, aby sa s nimi nezliala
                local sa, sb = num(a.v.sk, 0), num(b.v.sk, 0)
                local ikra = sa == 1 or sb == 1
                if (a.edge or 0) == (b.edge or 0) and not (ikra and (sa == sb or sa == 2 or sb == 2)) then
                    local sw = elen(a)
                    local ax, ay = along(a), a.y
                    local bx, by = along(b), b.y
                    local need = (ikra and GAP_IKRY or MIN_GAP) * (a.v.velkost * a.z + b.v.velkost * b.z)
                    local dx, dy = bx - ax, by - ay
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < need - 0.5 then
                        -- kto ustúpi: posunuteľná; z dvoch tá, na ktorú pustili (sepPrefer = pustená ostáva)
                        local mv, other
                        if movable(b) and (b ~= sepPrefer or not movable(a)) then mv, other = b, a
                        elseif movable(a) then mv, other = a, b end
                        if mv then
                            local ox, oy = along(mv), mv.y
                            local px, py = along(other), other.y
                            local vx, vy = ox - px, oy - py
                            local docked = oy < mv.v.velkost * mv.z * 1.6
                            if docked then vy = 0 end
                            local len = math.sqrt(vx * vx + vy * vy)
                            if len < 0.5 then vx, vy, len = 1, 0, 1 end      -- presne na sebe: doprava
                            local push = need - dist + 2
                            mv.x = clamp((ox + vx / len * push - (mv.ox or 0)) / sw, 0.02, hiAlong(mv) / sw)
                            mv.y = math.max(0, oy + vy / len * push)
                            -- pri okraji obrazovky nemá kam: odsunie sa na druhú stranu
                            if (mv.x <= 0.02 or mv.x >= hiAlong(mv) / sw - 0.0005) and docked then
                                mv.x = clamp((px - vx / len * need - (mv.ox or 0)) / sw, 0.02, 0.98)
                            end
                            mv.moved = true
                            moved[mv] = true
                            any = true
                        end
                    end
                end
            end
        end
        if not any then break end
    end
    for d in pairs(moved) do bump("sqn", d.k) end          -- odsunutá sa zachveje
    if next(moved) then save() end
    sepPrefer = nil
end
function E.setCorner(r)
    local a, b = roh or {}, r or {}
    if a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h then return end
    roh = r
    E.separate() E.publish()
end
function E.separate(prefer) sepDirty, sepPrefer = true, prefer or sepPrefer end

-- kotva (pri): kým kvapku nikto sám nepresunul, drží sa AKTUÁLNEJ polohy svojej kotvy — aj keď kotvu potiahnu
-- alebo ju odsunie pravidlo 22 (ikry okien pri hlave Goobaru, PowerGoo pri TimeGoo)
local postPublish = {}
local function anchor(d, depth)
    local a = d.def.pri and byId[d.def.pri]
    if not a or d.moved or d.dragging or d.wander or depth > 4 then return end
    anchor(a, depth + 1)
    d.x, d.ox, d.edge = a.x, (a.ox or 0) + num(d.def.odstup, 0), a.edge or 0
end

local function publish()
    if publishing then dirty = true return end
    publishing = true
    after(16, function()                                 -- viac zmien v jednom kroku = jeden zápis
        for k = 0, N - 1 do if slots[k] then anchor(slots[k], 0) end end
        if sepDirty then
            sepDirty = false
            separate()
            for k = 0, N - 1 do if slots[k] then anchor(slots[k], 0) end end
        end
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
        -- čo musí prísť do scény v tom istom kroku ako nový domov (inak by kvapka na snímku skočila)
        local q = postPublish
        postPublish = {}
        for _, f in ipairs(q) do f() end
        publishing = false
        if dirty then dirty = false publish() end
    end)
end
E.publish = publish

-- ── uloženie polôh a veľkostí (latte-goo stav / uloz-stav) ─────────────────────────────────────────────────────
local saveTimer
save = function()
    if saveTimer then cancel(saveTimer) end
    saveTimer = after(1200, function()
        saveTimer = nil
        local out = {}
        for id, d in pairs(byId) do
            if d.moved or d.z ~= 1 then out[id] = { x = d.x, y = d.y, z = d.z, e = d.edge or 0 } end
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
function Kvapka:velkost(z) self.z = clamp(z, ZOOM_MIN, ZOOM_MAX) E.separate(self) publish() save() end
function Kvapka:presun(x, y) self.x, self.y, self.ox = clamp(x, 0.02, 0.98), math.max(0, y), 0 self.moved = true publish() save() end
function Kvapka:domov() self.x, self.y, self.ox, self.z, self.moved, self.edge = self.hx0, self.hy0, self.ox0, 1, false, self.edge0 or 0 publish() save() end
function Kvapka:poskoc() bump("hopn", self.k) end
function Kvapka:stlac() bump("sqn", self.k) end
function Kvapka:bublina(s) text.tip = s or "" end
-- guľky pri kvapke (pravidlo 15): počet 0…5+, farba ("hardver" červená, "siet" zelená, "softver" modrá, "zlta",
-- "system" červeno-kávová, "svetlo"); nad 4 sa ukáže počet v poslednej
local GULKY = { hardver = 0, siet = 1, softver = 2, zlta = 3, system = 4, svetlo = 5 }
-- farba: jedna pre všetky, alebo zoznam po guľkách { "hardver", "siet", "softver" } (QueenGoo)
function Kvapka:gulky(n, farba)
    n = math.max(0, math.floor(n or 0))
    local code = 0
    for j = 0, 3 do
        local f = type(farba) == "table" and (farba[j + 1] or farba[#farba]) or farba
        code = code + (GULKY[f] or num(f, 3)) * 8 ^ j
    end
    self.gn, self.gf, self.gt = math.min(n, 5), code, n > 4 and tostring(n) or ""
    publish()
end
function Kvapka:obrazok(meno) self.v.obr = meno or "" publish() end
function Kvapka:stlm(x) self.tlm = x or 0 publish() end
function Kvapka:jadro(farba, sila, pulz)
    if farba == nil then self.jadroS = 0
    else self.jadroS, self.jadroF, self.jadroP = sila or 1, JADRO[farba] or num(farba, 5), pulz ~= false end
    publish()
end
-- poloha kvapky v px (vlnky): šírku obrazovky povie scéna (fact sw)
function Kvapka:px() return along(self) end      -- poloha pozdĺž jej okraja (px); dole = x na obrazovke
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
    local x = 0.03
    if E.prva then x = E.prva end                       -- test: ďalšie kvapky od tohto miesta (trojica ostane sama)
    for k = 0, N - 1 do
        local d = slots[k]
        if d and d.hy0 < d.v.velkost * 1.6 and not d.def.pri and d.zdroj ~= "dyn" and d.hx0 < (E.prvaKoniec or 1) then x = math.max(x, d.hx0 + 0.03) end
    end
    return x
end

function E.define(def, zdroj)
    assert(type(def) == "table" and type(def.id) == "string", "kvapka potrebuje id")
    local prev = byId[def.id]                            -- znova (zmenený JSON): ostane, kde ju používateľ nechal
    if prev then
        saved[def.id] = { x = prev.x, y = prev.y, z = prev.z, e = prev.edge }
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
    local s = saved[def.id] or saved[STARE[def.id] or ""]     -- poloha spred premenovania kvapiek
    d.x, d.y, d.z = s and s.x or d.hx0, s and s.y or d.hy0, clamp(num(s and s.z, 1), ZOOM_MIN, ZOOM_MAX)
    d.ox = s and 0 or d.ox0
    d.moved = s ~= nil
    d.edge0 = anchor and (anchor.edge0 or 0) or clamp(math.floor(num(def.okraj, 0)), 0, 3)
    d.edge = clamp(math.floor(num(s and s.e, d.edge0)), 0, 3)
    -- gravitácia: nič nevisí vo vzduchu — kvapka uložená alebo zadaná mimo okraja si naň sadne
    if d.y >= v.velkost * d.z * 1.6 then d.y = seat end
    if d.hy0 >= v.velkost * 1.6 then d.hy0 = seat end
    slots[k], byId[def.id] = d, d
    E.separate()
    E.needGlyph(v.ikona)
    E.needGlyph(v.koruna)
    -- chyba jednej kvapky nezhodí ostatné (zapíše sa do logu)
    local function safe(name, f) local ok, err = pcall(f, d) if not ok then log("goo: " .. d.id .. "." .. name .. ": " .. tostring(err)) end end
    if def.kazdych and def.tik then
        d.timer = every(def.kazdych, function() safe("tik", def.tik) end)
        safe("tik", def.tik)
    end
    if def.start then safe("start", def.start) end
    publish()
    return d
end

-- pridá kvapku, alebo zmení existujúcu bez preskočenia (miesto, poloha a animácia ostanú): pre kvapky, ktoré
-- vznikajú za behu (okná v Goobari, upozornenia). Nová poloha domova platí, ak ju používateľ nepresunul.
function E.upsert(def)
    local d = byId[def.id]
    if not d then return E.define(def, "dyn") end
    d.def = def
    for key, val in pairs(def) do d.v[key] = val end
    local anchor = def.pri and byId[def.pri]
    local seat = num(def.vyska, d.v.velkost * 0.8)
    if anchor then
        d.hx0, d.ox0, d.hy0 = anchor.hx0, (anchor.ox0 or 0) + num(def.odstup, 0), seat
    elseif type(def.poloha) == "table" then
        d.hx0, d.hy0 = num(def.poloha.x, d.hx0), num(def.poloha.y, seat)
    end
    if not d.moved then d.x, d.y, d.ox = d.hx0, d.hy0, d.ox0 end
    E.separate()
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
local ctx_items, ctx_width = nil, nil       -- práve otvorená ponuka Goo (E.menu)
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
            if not (ok and type(t) == "table") then return end
            for n, g in pairs(t) do glyphs[n] = g end
            for _, n in ipairs(names) do glyphs[n] = glyphs[n] or "" end   -- neznáme meno: už sa nepýtať
            publish()
            -- ponuka otvorená skôr, než prišli znaky: nakresliť ju znova s ikonami (prvé otvorenie po štarte)
            if fact.ctx_open and ctx_items then E.menu(ctx_items, ctx_width) end
        end)
    end)
end

-- ── ponuka Goo (pravidlá 9–11): karta pri mieste kliku; položky { label, glyph (meno Tabler), hint, on, off, danger,
-- sep, sub = { … } (podponuka so „Späť“), run = funkcia }. Miesto si scéna zapamätá pri stlačení kvapky.
local ctx_actions = {}
local CTX_MAX = 14
function E.menu(items, width)
    ctx_actions = {}
    ctx_items, ctx_width = items, width
    local out, y = {}, 6
    for _, it in ipairs(items) do
        if #out >= CTX_MAX then break end
        if it.sep and #out > 0 then y = y + 12 end
        E.needGlyph(it.glyph)
        out[#out + 1] = { label = it.label or "", on = it.on and 1 or 0, off = it.off == true,
                          glyph = (it.glyph and (glyphs[it.glyph] or (isName(it.glyph) and "" or it.glyph))) or "",
                          hint = it.hint or "", danger = it.danger == true, sub = it.sub ~= nil or it.back ~= nil,
                          back = it.back ~= nil, sep = it.sep == true and #out > 0, y = y }
        y = y + 36
        if it.sub then
            local parent = items
            ctx_actions[#out] = function()
                local kids = { { label = tr("Back"), glyph = "chevron-left", back = parent } }
                for j, c in ipairs(it.sub) do
                    local c2 = {} for kk, vv in pairs(c) do c2[kk] = vv end
                    if j == 1 then c2.sep = true end
                    kids[#kids + 1] = c2
                end
                E.menu(kids, width)
            end
        elseif it.back then
            ctx_actions[#out] = function() E.menu(it.back, width) end
        else
            ctx_actions[#out] = function() fact.ctx_open = false if it.run then it.run() end end
        end
    end
    model.ctx = out
    fact.ctx_w = width or 248
    fact.ctx_h = y + 6
    fact.ctx_hot = -1
    fact.ctx_open = #out > 0
end
on("ctx_pick", function(k) local f = ctx_actions[(k or 0) + 1] if f then f() end end)
on("ctx_close", function() ctx_actions = {} ctx_items = nil end)

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

-- klik = pustenie ľavého bez ťahania a bez podržania. Scéna posiela iba stlačenie a pustenie; poradie drží logika
-- (pravé, stredné, podržanie a ťahanie rozrobený klik rušia)
local down = nil                                        -- miesto, na ktorom je stlačené ľavé
on("goo_down", function(k) down = k end)
on("goo_up", function(k)
    local was = down
    down = nil
    local d = at(k) if not d or was ~= k then return end
    hud("klik · " .. d.id)
    hook(d, "klik")
end)
on("goo_right", function(k)
    down = nil
    local d = at(k) if not d then return end
    hud("pravé · " .. d.id)
    hook(d, "pravy")                                    -- bez háčika nič (pravidlo 8)
end)
on("goo_middle", function(k)
    down = nil
    local d = at(k) if not d then return end
    hud("stredné · " .. d.id)
    hook(d, "stredny")                                  -- bez háčika nič (pravidlo 8); domov: Nastavenia › Kvapky
end)
on("goo_hold", function(k)
    if down ~= k then return end                        -- podržanie iba ľavým
    down = nil
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
    down = nil
    fact["fh." .. k] = 0                                -- chytená počas pádu: pád končí
    local d = at(k) if not d then return end
    hud("ťahanie · " .. d.id)
    d.dragging = true
    publish()
    hook(d, "tahanie")
end)
-- Pustenie po ťahaní (pravidlá 16, 20 a §3): kvapka nikdy neostane visieť vo vzduchu.
--   · pri ľavom, pravom alebo hornom okraji (do STICK px) sa k nemu PRILEPÍ — kvapky sa lepia ku každému okraju;
--   · inak na ňu platí GRAVITÁCIA: spadne rovno dole na hladinu, s prestrelením a odrazom (pružina `pada`),
--     ponorí sa, vynorí a hladina sa zvlní;
--   · kvapka s `vratit` (GooBar: lišta sa dá preniesť k inému okraju) sa pri pustení uprostred vráti, kde bola.
local STICK = 130
local GRAV = 800            -- px/s², rovnaké ako `let GRAV` v scéne: logika z neho počíta čas dopadu
on("goo_drop", function(k)
    local d = at(k) if not d then return end
    local X, Y = num(fact.rx, 0), num(fact.ry, 0)
    local W, H = num(fact.sw, 0), num(fact.sh, 0)
    if W <= 0 then W = 1920 end
    if H <= 0 then H = 1080 end
    d.dragging = false
    local r = d.v.velkost * d.z
    -- najbližší okraj v dosahu prilepenia; dole je vždy (gravitácia)
    local edge, best = 0, math.huge
    for e, dist in ipairs({ H - Y, X, Y, W - X }) do                 -- dole, vľavo, hore, vpravo
        if dist < STICK and dist < best then edge, best = e - 1, dist end
    end
    local stuck = best < math.huge
    local fell = not stuck                                            -- nebola pri žiadnom okraji: padá
    local has, res = hook(d, "pustenie", X, Y, edge)
    local fh = 0                                                      -- výška pádu nad novým domovom (px)
    if has and res == false or (fell and d.v.vratit) then
        hud("pustenie · " .. d.id .. " · späť")
    else
        d.edge = edge
        d.x = clamp(((edge % 2 == 1) and Y / H or X / W), 0.02, 0.98)
        d.x = math.min(d.x, hiAlong(d) / elen(d))                     -- nie pod rohovú lištu
        d.y = num(d.v.vyska, d.v.velkost * 0.8) * d.z
        d.moved, d.ox = true, 0
        if fell then fh = math.max(0, (H - 6 - d.y) - Y) end
        save()
        hud(string.format("pustenie · %s · okraj %d · %.2f%s", d.id, edge, d.x, fell and " · padá" or ""))
    end
    -- návrat k okraju: ponorí sa pod hladinu a vynorí (Marea); po páde až pri dopade, hladina sa zvlní (iba dole)
    -- pád trvá √(2·výška/g): až pri dopade sa sploští a zvlní hladinu; ponor urobí sama pružina (prestrelí pod
    -- hladinu a vráti sa). Kvapka prilepená k okraju sa ponorí a vynorí hneď.
    local wait = fh > 0 and math.sqrt(2 * fh / GRAV) * 1000 or 0
    after(wait, function()
        if byId[d.id] ~= d or d.dragging then return end
        if fh > 0 then bump("sqn", k) else bump("dipn", k) end
        if (d.edge or 0) == 0 then
            after(fh > 0 and 60 or 200, function() E.vlnka(along(d), (fh > 0 and 3 + math.min(fh, 900) * 0.008 or 4) + r * 0.12, "kamen") end)
        end
    end)
    -- pustená na inú: jedna sa odsunie (pravidlo 22); pustená ostane, kde ju pustili
    E.separate(d)
    -- nový domov, koniec ťahania a výška pádu prídu do scény v jednom kroku (inak by kvapka na snímok skočila)
    table.insert(postPublish, function()
        fact["dx." .. k], fact["dy." .. k], fact["drg." .. k], fact["tr." .. k] = 0, 0, 0, 0
        fact.nk = -1
        fact["fh." .. k] = fh
        if fh > 0 then bump("falln", k) end
    end)
    publish()
end)

-- ── nečinnosť: živé bytosti (LATTEOS-GOO.md 3.1) ─────────────────────────────────────────────────────────────────
-- stupeň 1 (1 min) zaspávajú — menšie nadnesenie robí scéna; 2 (3 min) počasie — rezerva, háčik necinnost(d, 2);
-- 3 (6 min) hra hravých kvapiek: naháňačka so zámernou zrážkou a odrazom (squish), behanie po lište, skákanie.
-- Prebudenie hneď: všetky sa zachvejú a vrátia na svoje miesto (poloha z Nastavení sa nemení).
local play
local busy = false          -- beží jeden beh alebo naháňačka (ďalší počká)
local function stopPlay()
    if play then cancel(play) play = nil end
    busy = false
    E.each(function(d)
        if d.wander then d.x, d.y, d.wander = d.wx, d.wy, nil end
    end)
    publish()
end
local function wander(d)
    if not d.wander then d.wander, d.wx, d.wy = true, d.x, d.y end
end
-- pravidlo 22 platí aj pri hre: bežiaca kvapka nikoho neprekryje — ostatné na lište jej UHNÚ (reťazovo, od nej
-- preč) a po hre sa všetko vráti na svoje miesto. Ikry okien a hlava Goobaru neuhýbajú (k nim sa nebeží).
local function px(d) local sw = num(fact.sw, 0) return d.x * (sw > 0 and sw or 1920) + (d.ox or 0) end
local function rad(d) return d.v.velkost * d.z end
local function docked(d) return d.y < rad(d) * 1.6 and not d.hidden and (d.edge or 0) == 0 end
local function toFrac(d, x) local sw = num(fact.sw, 0) return (x - (d.ox or 0)) / (sw > 0 and sw or 1920) end
-- miesto pre d na x: komu treba uhnúť a kam ({ kvapka = x }); nil = nezmestí sa (okraj obrazovky, Goobar)
local function shove(d, x)
    local sw = num(fact.sw, 0) if sw <= 0 then sw = 1920 end
    if x < 0.03 * sw or x > math.min(0.97 * sw, hiAlong(d)) then return nil end
    local others, fixed = {}, {}
    E.each(function(o)
        if o ~= d and docked(o) and not o.dragging then
            table.insert(num(o.v.sk, 0) >= 1 and fixed or others, o)
        end
    end)
    for _, q in ipairs(fixed) do
        if math.abs(px(q) - x) < (rad(d) + rad(q)) * GAP_IKRY then return nil end
    end
    table.sort(others, function(a, b) return math.abs(px(a) - x) < math.abs(px(b) - x) end)
    local placed, moves = { { x = x, r = rad(d) } }, {}
    for _, o in ipairs(others) do
        local ox = px(o)
        local side = ox >= x and 1 or -1
        for _, p in ipairs(placed) do
            local need = (p.r + rad(o)) * MIN_GAP
            if math.abs(ox - p.x) < need then ox = p.x + side * need end
        end
        if ox ~= px(o) then
            if ox < 0.02 * sw or ox > hiAlong(o) then return nil end
            for _, q in ipairs(fixed) do
                if math.abs(px(q) - ox) < (rad(o) + rad(q)) * MIN_GAP then return nil end
            end
            moves[o] = ox
        end
        table.insert(placed, { x = ox, r = rad(o) })
    end
    return moves
end
local function land(d)                                       -- dopad: sploští sa a hladina sa zvlní
    after(520, function() if play then d:stlac() E.vlnka(px(d), 3, "kamen") end end)
end
-- d odbehne na x (ostatné uhnú), po `ms` sa všetci vrátia; počas behu sa nezačne iný
local function run_to(d, x, moves, ms, meet)
    busy = true
    wander(d)
    d.x = toFrac(d, x)
    for o, ox in pairs(moves) do wander(o) o.x = toFrac(o, ox) end
    d:poskoc() land(d) publish()
    if meet then after(700, function() if play then meet() end end) end
    after(ms, function()
        busy = false
        if not play then return end
        d.x, d.y, d.wander = d.wx, d.wy, nil
        for o in pairs(moves) do if o.wander then o.x, o.y, o.wander = o.wx, o.wy, nil end end
        d:poskoc() land(d) publish()
    end)
end
local function game()
    local players = {}
    E.each(function(d) if d.v.hrava and not d.wander and not d.dragging and docked(d) then table.insert(players, d) end end)
    if #players == 0 then return end
    local d = players[math.random(#players)]
    local sw = num(fact.sw, 0) if sw <= 0 then sw = 1920 end
    local r = math.random()
    if not busy and r >= 0.3 and r < 0.65 then               -- naháňačka: dobehne inú, pritisne sa, obe sa stlačia, odrazí sa späť
        local all = {}
        E.each(function(o) if o ~= d and docked(o) and num(o.v.sk, 0) == 0 and not o.wander then table.insert(all, o) end end)
        local other = #all > 0 and all[math.random(#all)]
        if other then
            local side = px(d) < px(other) and -1 or 1
            local x = px(other) + side * (rad(d) + rad(other)) * MIN_GAP
            local moves = shove(d, x)
            if moves and not moves[other] and math.abs(x - px(d)) > rad(d) then
                run_to(d, x, moves, 1700, function() d:stlac() other:stlac() other:poskoc() land(other) end)
                return
            end
        end
    elseif not busy and r >= 0.65 then                       -- behanie po lište: ostatné uhnú, potom späť
        local x = clamp(px(d) + (math.random() < 0.5 and -1 or 1) * (0.06 + 0.16 * math.random()) * sw, 0.03 * sw, 0.97 * sw)
        local moves = shove(d, x)
        if moves and math.abs(x - px(d)) > rad(d) then
            run_to(d, x, moves, 2600)
            return
        end
    end
    d:poskoc() land(d)                                       -- skákanie na mieste (aj keď nie je kam bežať)
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

-- ── Nastavenia › Kvapky (~/.config/latteos/kvapky.json, ten istý súbor ako plocha Kvapky): voliteľné kvapky sa dajú
-- skryť, základné (zaklad = true: GooBar, GooPower, LensGoo) nie; veľkosť 100–220 %; vrátenie na miesto ──────────
local lastReset = nil
local function settings()
    run("latte-goo", { "nastavenia" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if not ok or type(t) ~= "table" then return end
        local hide, changed = {}, false
        for _, id in ipairs(type(t.skryte) == "table" and t.skryte or {}) do hide[id] = true end
        for id, d in pairs(byId) do
            local h = hide[id] == true and not d.def.zaklad and d.zdroj ~= "dyn"
            if h ~= (d.hidden == true) then d.hidden = h changed = true end
            local z = type(t.zoom) == "table" and tonumber(t.zoom[id])
            if z and math.abs(clamp(z, ZOOM_MIN, ZOOM_MAX) - (d.zset or 0)) > 0.001 then
                d.zset = clamp(z, ZOOM_MIN, ZOOM_MAX)             -- iba keď sa zmenilo v Nastaveniach (koliesko ostáva)
                d:velkost(d.zset)
            end
        end
        local r = type(t.reset) == "table" and t.reset
        if r and r.t ~= lastReset then
            if lastReset ~= nil and byId[r.k] then byId[r.k]:domov() end
            lastReset = r.t
        elseif not r and lastReset == nil then
            lastReset = 0
        end
        if changed then E.separate() publish() end
    end)
end

-- ── štart ────────────────────────────────────────────────────────────────────────────────────────────────────
function E.start(opts)
    opts = opts or {}
    E.ladenie = opts.ladenie
    E.prva = opts.prva
    E.prvaKoniec = opts.prva_koniec
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
        settings()
        every(2000, settings)
        -- rozmer obrazovky príde zo scény až po štarte (a zmení sa s rozlíšením): polohy a zakázanú zónu prepočítať
        local lw, lh = 0, 0
        every(1000, function()
            local w, h = num(fact.sw, 0), num(fact.sh, 0)
            if w ~= lw or h ~= lh then lw, lh = w, h E.separate() publish() end
        end)
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
