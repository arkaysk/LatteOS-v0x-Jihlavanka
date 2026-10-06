-- LatteOS GOO — logika prihlásenia (login.plm, LATTEOS-GOO.md §6.2). Riadi časovú os úvodu, plní údaje
-- (latte-goo prihlasenie: meno, káva, posledný pád alebo novinky, informačné goo, znaky ikon) a overuje heslo.
-- Režim podľa premennej LATTE_LOGIN:
--   skuska (predvolené)  nič v systéme nemení: heslo „latte“ sedí, iné nie; po prihlásení sa úvod zopakuje;
--                        ponuka napájania iba zapíše do logu
--   zamok                heslo overí systém (PAM, `auth.check`) — pre zámok relácie
-- Zapojenie do skutočného prihlasovania príde až po rozhodnutí o spôsobe (README › Prihlásenie).
local ok_env, env = pcall(sys.ask, "env", "LATTE_LOGIN")
local REZIM = (ok_env and type(env) == "string" and env ~= "") and env or "skuska"

local function safe(what, f, ...)
    local ok, err = pcall(f, ...)
    if not ok then print("login · " .. what .. ": " .. tostring(err)) end
end

-- ── údaje ────────────────────────────────────────────────────────────────────────────────────────────────────
local function data()
    run("latte-goo", { "prihlasenie" }, function(out)
        local ok, d = pcall(json.decode, out or "")
        if not ok or type(d) ~= "table" then print("login · latte-goo prihlasenie nič nevrátil") return end
        text.meno = d.meno or ""
        if type(d.kava) == "table" then fact.voda, fact.mlieko = tonumber(d.kava[1]) or 0.55, tonumber(d.kava[2]) or 0 end
        local g = d.ikony or {}
        text.g_power, text.g_sip, text.g_spat, text.g_znova = g.power or "", g["arrow-right"] or "", g.moon or "", g.refresh or ""
        local rows = {}
        for _, t in ipairs(d.riadky or {}) do rows[#rows + 1] = { t = t } end
        model.riadky = rows
        fact.panel = (d.panel == "pad" and 1) or (d.panel == "novinky" and 2) or 0
        local inf = {}
        for _, i in ipairs(d.info or {}) do inf[#inf + 1] = { g = g[i.ikona] or "", v = tostring(i.text or ""), on = true } end
        -- skúška na počítači bez batérie a bez úloh: vzorové goo, aby bolo vidno, ako sa vynoria
        if REZIM == "skuska" and #inf == 0 then
            inf = { { g = g["battery-3"] or "", v = "82 %", on = true }, { g = g.bell or "", v = "3", on = true }, { g = g["calendar-event"] or "", v = "2", on = true } }
        end
        model.inf = inf
        if tonumber(d.goopower) then fact.tox = tonumber(d.goopower) end
    end)
end

local function clock()
    run("date", { "+%H:%M|%A %-d. %B" }, function(out)
        local c, d = (out or ""):match("^(%d+:%d+)|(.-)%s*$")
        if c then text.cas, text.datum = c, d or "" end
    end)
end

-- ── časová os úvodu ──────────────────────────────────────────────────────────────────────────────────────────
local function uvod()
    after(700, function() emit("e_skok") end)        -- šálka chvíľu stojí (nadväzuje na úvodnú obrazovku)
    after(1900, function() emit("e_val") end)
    after(2900, function() emit("e_riadok") end)
    after(3500, function() emit("e_hladina") end)
end

-- ── heslo ────────────────────────────────────────────────────────────────────────────────────────────────────
local function over(pw)
    if REZIM == "zamok" then
        local ok, valid = pcall(sys.ask, "auth.check", pw)
        return ok and valid == true
    end
    return pw == "latte"
end

on("e_odosli", function()
    safe("heslo", function()
        local pw = text.heslo or ""
        if pw == "" or fact.caka then return end
        fact.caka = true
        after(REZIM == "skuska" and 500 or 16, function()
            local dobre = over(pw)
            text.heslo = ""
            fact.caka = false
            if dobre then
                emit("e_ok")
                if REZIM == "skuska" then
                    after(4200, function() emit("e_znova") uvod() end)
                end
            else
                emit("e_zle")
            end
        end)
    end)
end)

on("text:heslo", function() emit("e_zobud") end)     -- písanie vráti informačné goo pod hladinu

local MOC = { "suspend", "reboot", "poweroff" }
on("e_moc", function(k)
    local co = MOC[(k or 0) + 1]
    if not co then return end
    if REZIM == "skuska" then print("login · napájanie (skúška, nič sa nevykoná): " .. co) return end
    run("systemctl", { co }, nil, { output = false })
end)

data()
clock()
every(5000, clock)
every(60000, data)                                   -- novinky a batéria sa občas obnovia
uvod()
print("login · režim " .. REZIM)
