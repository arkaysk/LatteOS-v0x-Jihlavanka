-- engine Goo — kvapky používateľa: JSON v ~/.config/latteos/goo/kvapky/*.json (latte-goo zoznam ich overí a vráti
-- naraz). Pridať, zmeniť alebo zmazať sa dajú kedykoľvek: zmena súborov sa prejaví do pár sekúnd, bez reštartu.
-- Akcie (príkazy, aplikácie, odkazy) vykoná latte-goo podľa id a mena akcie — logika nikdy neposiela príkaz sama.
--
-- {
--   "id": "kalkulacka", "nazov": "Kalkulačka", "ikona": "calculator", "povaha": "zvedava",
--   "popis": "Klik otvorí kalkulačku", "velkost": 26, "poloha": { "x": 0.3, "y": 0 },
--   "text": { "prikaz": "date +%H:%M", "kazdych": 30 },
--   "akcie": { "klik": { "aplikacia": "org.gnome.Calculator" }, "pravy": { "vystup": "uptime -p" },
--              "stredny": "domov", "podrz": { "otvor": "https://latteos.sk" }, "koliesko": "velkost" }
-- }
-- Akcia: { "spusti": "príkaz" } · { "aplikacia": "id.desktop" } · { "otvor": "súbor alebo adresa" }
--        · { "vystup": "príkaz" } (výstup v bubline) · "domov" · "velkost" · "poskoc" · "vlnka" · "vibracia" · "nic"
-- Jadro: "jadro": "siet" (stále) alebo "upozornenie": { "prikaz": "…", "kazdych": s } — výstup príkazu je farba
--   (hardver, siet, softver, vystraha, svetlo, ine), prázdny = zhasne; nové upozornenie zvlní hladinu
-- Tvorca Goo (Nastavenia › Kvapky, 7. 10.) skladá goo z hotových dielov:
--   "aplikacia": "id"        kvapka aplikácie: jej pôvodná ikona, klik ju spustí (ak klik nie je nastavený inak)
--   "skupina": ["id", …]     rýchle spúšťanie: klik (vstavaná akcia "skupina") otvorí kartu s dlaždicami aplikácií
--   "udaj": "procesor"       goo ukazuje údaj (procesor, teplota, pamat, disk, bateria, pocasie) každých "kazdych" s;
--                            bublina pri prechode myšou povie podrobnosti, prstenec (druh ukazovatel) ukáže hodnotu
--   vstavaná akcia "upravit" (predvolená na pravý klik) = ponuka kvapky: upraviť v Tvorcovi, vrátiť na miesto, odstrániť
local M = {}
local known = {}          -- id → podpis definície (zmena = nová registrácia)
local goobar = require("lib/goobar")
local E_ref                -- engine (z load), pre karty kvapky

local function app_of(id) return goobar.app_by_id and goobar.app_by_id(id) or nil end
local function launch(id)
    local a = app_of(id)
    if a and a.exec then pcall(sys.call, "apps.launch", a.exec) end
end
local function gb(b) return (string.format("%.1f", (b or 0) / 2 ^ 30):gsub("%.", ",")) .. " GB" end
-- počasie: znak podľa kódu WMO (ako ClockGoo)
local function wx_icon(c)
    c = tonumber(c) or 3
    if c == 0 then return "sun" end
    if c == 1 or c == 2 then return "sun-low" end
    if c == 45 or c == 48 then return "cloud-fog" end
    if c >= 95 then return "cloud-storm" end
    if (c >= 71 and c <= 77) or c == 85 or c == 86 then return "cloud-snow" end
    if (c >= 51 and c <= 67) or (c >= 80 and c <= 82) then return "cloud-rain" end
    return "cloud"
end
-- bublina goo s údajom (vety tu, pomocník dáva iba čísla); názov kvapky ukáže bublina sama, tu iba hodnoty
local function data_tip(r)
    local u = r.udaj
    if u == "procesor" then
        return (r.cpu or 0) .. " %" .. ((r.cores or 0) > 0 and ("  ·  " .. r.cores .. " " .. tr("cores")) or "")
            .. ((r.cpuT and ("  ·  " .. r.cpuT .. " °C")) or "")
    elseif u == "teplota" then
        return r.cpuT and (r.cpuT .. " °C  ·  " .. tr("load") .. " " .. (r.cpu or 0) .. " %") or tr("No temperature sensor")
    elseif u == "pamat" then
        return gb(r.used) .. " / " .. gb(r.total)
    elseif u == "disk" then
        return gb(r.used) .. " / " .. gb(r.total) .. "  ·  " .. tr("free") .. " " .. gb((r.total or 0) - (r.used or 0))
    elseif u == "bateria" then
        if r.ziadna then return tr("This computer has no battery") end
        return (r.pct or 0) .. " %  ·  " .. (r.stav == "charging" and tr("charging") or (r.stav == "full" and tr("full") or tr("on battery")))
    elseif u == "pocasie" then
        if not r.t then return tr("No forecast yet") end
        return ((r.miesto or "") ~= "" and (r.miesto .. "  ·  ") or "") .. r.t .. " °C" .. (r.max and ("  ·  " .. tr("Today") .. " " .. r.max .. "° / " .. r.min .. "°") or "")
    end
    return ""
end

-- rýchle spúšťanie: karta s dlaždicami aplikácií skupiny (klik spustí, karta sa zavrie)
local function group_card(d)
    local tiles = {}
    for _, id in ipairs(d.def.skupina or {}) do
        local a = app_of(id)
        if a then tiles[#tiles + 1] = { img = a.icon, glyph = "apps", label = a.name or id, run = function() launch(id) end } end
    end
    local items = { { hd = true, label = d.v.nazov or "" } }
    if #tiles == 0 then items[#items + 1] = { info = true, glyph = "apps", label = tr("No apps in this group") }
    else items[#items + 1] = { tiles = tiles, per = math.min(4, #tiles) } end
    items[#items + 1] = { pills = { { glyph = "pencil", label = tr("Edit the group"),
                                      run = function() run("latte-app", { "nastavenia", "kvapky", d.id }, nil, { output = false }) end } } }
    E_ref.menu(items, math.max(220, math.min(4, math.max(1, #tiles)) * 74), { id = "goo:" .. d.id, owner = d })
end
-- ponuka vlastnej kvapky (pravý klik): upraviť v Tvorcovi Goo, vrátiť na miesto, odstrániť
local function edit_card(d)
    E_ref.menu({
        { hd = true, label = d.v.nazov or "" },
        { glyph = "pencil", label = tr("Edit in Goo Creator"), run = function() run("latte-app", { "nastavenia", "kvapky", d.id }, nil, { output = false }) end },
        { glyph = "arrow-back-up", label = tr("Back to its place"), run = function() d:domov() end },
        { glyph = "trash", label = tr("Remove the goo"), danger = true, sep = true,
          run = function() run("latte-goo", { "zmaz", d.id }, function() if M.reload then M.reload() end end, { output = false }) end },
    }, 240, { id = "goo:" .. d.id, owner = d })
end

local ACTIONS = { klik = "klik", pravy = "pravy", stredny = "stredny", podrz = "podrz" }

local function action(E, d, key)
    local a = d.def.akcie and d.def.akcie[key]
    if a == nil then return false end
    if a == "domov" then d:domov() return true end
    if a == "velkost" then return false end              -- koliesko: predvolené správanie enginu
    if a == "poskoc" then d:poskoc() return true end
    if a == "vlnka" then d:vlnka() return true end
    if a == "vibracia" then d:vibruj() return true end
    if a == "nic" then return true end
    if a == "skupina" then group_card(d) return true end
    if a == "upravit" then edit_card(d) return true end
    if type(a) == "table" and a.aplikacia and app_of(a.aplikacia) then launch(a.aplikacia) return true end
    run("latte-goo", { "akcia", d.id, key }, function(out, code)
        if out and out ~= "" then d:bublina(out:gsub("%s+$", "")) end
        if code ~= 0 then log("goo: akcia " .. d.id .. "." .. key .. " skončila s " .. tostring(code)) end
    end)
    return true
end

local function refreshText(d)
    run("latte-goo", { "text", d.id }, function(out)
        local ok, r = pcall(json.decode, out or "")
        if not ok or type(r) ~= "table" then return end
        d:text(r.text or "")
        if type(r.hodnota) == "number" then d:hodnota(math.max(0, math.min(1, r.hodnota))) end
        -- bublina: vlastný popis z Tvorcu má prednosť, inak podrobnosti údaja alebo ďalšie riadky príkazu
        if (d.def.popis or "") == "" then
            local tip = r.udaj and data_tip(r) or (r.popis or "")
            if tip ~= d.v.popis then d:nastav({ popis = tip }) end
        end
        if r.udaj == "pocasie" and r.kod ~= nil and (d.def.ikona or "") == "" then d:ikona(wx_icon(r.kod)) end
    end)
end
-- kvapka aplikácie nesie jej pôvodnú ikonu; zoznam aplikácií môže prísť až po kvapke — skúša sa, kým sa nenájde
local function app_icon(d)
    local a = app_of(d.def.aplikacia)
    if a and a.icon and a.icon ~= "" then
        if d.shownIcon ~= a.icon then d.shownIcon = a.icon d:obrazok(a.icon) end
        return true
    end
    return false
end

local function checkNotice(d)
    run("latte-goo", { "upozornenie", d.id }, function(out)
        local f = (out or ""):match("[%w]+")
        if f and not d.notice then d:vlnka(5) end
        d.notice = f
        if f then d:jadro(f, 1, true) else d:jadro(d.def.jadro) end
    end)
end

local function build(E, j)
    local def = {}
    for k, v in pairs(j) do def[k] = v end
    def.text = type(j.text) == "string" and j.text or ""
    -- predvolené akcie dielov Tvorcu: aplikácia → klik ju spustí, skupina → klik otvorí kartu, pravý klik = ponuka kvapky
    local akcie = {}
    for k, v in pairs(j.akcie or {}) do akcie[k] = v end
    if akcie.klik == nil and j.aplikacia then akcie.klik = { aplikacia = j.aplikacia } end
    if akcie.klik == nil and j.skupina then akcie.klik = "skupina" end
    if akcie.pravy == nil then akcie.pravy = "upravit" end
    j = setmetatable({ akcie = akcie }, { __index = j })
    def.akcie = akcie
    if (def.ikona or "") == "" then def.ikona = j.skupina and "layout-grid" or (j.udaj and "chart-donut" or "droplet") end
    for key in pairs(ACTIONS) do
        if j.akcie and j.akcie[key] ~= nil then def[key] = function(d) action(E, d, key) end end
    end
    local wheel = j.akcie and j.akcie.koliesko
    def.zoom = wheel == "velkost"                         -- veľkosť kolieskom iba keď ju kvapka chce (pravidlo 8)
    if type(wheel) == "table" then
        def.koliesko = function(d, dir) action(E, d, dir > 0 and "hore" or "dole") end
    end
    if type(j.text) == "table" and j.text.prikaz then
        def.kazdych = math.max(2, tonumber(j.text.kazdych) or 60) * 1000
        def.tik = refreshText
    elseif j.udaj then
        def.kazdych = math.max(2, tonumber(j.kazdych) or (j.udaj == "pocasie" and 600 or 5)) * 1000
        def.tik = refreshText
    end
    if j.aplikacia then
        local base = def.start
        def.start = function(d)
            if base then base(d) end
            if not app_icon(d) then
                local tries = 0
                d.iconTimer = every(3000, function()
                    tries = tries + 1
                    if app_icon(d) or tries > 40 then cancel(d.iconTimer) end
                end)
            end
        end
    end
    if type(j.jadro) == "string" then def.start = function(d) d:jadro(j.jadro, 0.8, false) end end
    if type(j.upozornenie) == "table" and j.upozornenie.prikaz then
        local textTik = def.tik
        local every_ = math.max(2, tonumber(j.upozornenie.kazdych) or 30) * 1000
        local base = def.start
        def.start = function(d)
            if base then base(d) end
            checkNotice(d)
            d.noticeTimer = every(every_, function() checkNotice(d) end)
        end
        def.tik = textTik
    end
    return def
end

local function load(E, opts)
    E_ref = E
    local args = { "zoznam" }
    if opts.priklady then table.insert(args, "--priklady") end
    run("latte-goo", args, function(out)
        local ok, list = pcall(json.decode, out or "")
        if not ok or type(list) ~= "table" then return end
        local seen = {}
        for _, j in ipairs(list) do
            if type(j) == "table" and type(j.id) == "string" then
                if j.chyba then
                    log("goo: " .. tostring(j.zdroj) .. ": " .. j.chyba)
                else
                    seen[j.id] = true
                    local sig = json.encode(j)
                    if known[j.id] ~= sig then
                        known[j.id] = sig
                        local d = E.define(build(E, j), "json")
                        -- bez polohy: miesto, ktoré jej engine našiel, sa zapíše ako jej domov (po reštarte ostane)
                        if d and type(j.poloha) ~= "table" then
                            run("latte-goo", { "poloha", j.id, string.format("%.4f", d.hx0), string.format("%.1f", d.hy0) }, nil, { output = false })
                        end
                    end
                end
            end
        end
        for id in pairs(known) do
            if not seen[id] then known[id] = nil E.remove(id) end
        end
    end)
end

function M.start(E, opts)
    M.reload = function() load(E, opts) end
    -- pri štarte až po rozvinutí pásu výkonu GooPower (prvý údaj príde do 1–2 s): nová kvapka si inak nájde miesto,
    -- ktoré pás o chvíľu zaberie
    after(3000, function() load(E, opts) end)
    every(4000, function() load(E, opts) end)
end

return M
