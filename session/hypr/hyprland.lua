-- LatteOS — Hyprland, relácia NORMAL (/usr/share/latteos/hypr/hyprland.lua).
-- Lua modul LatteOS (ROADMAP F2): stupeň výkonu z latte-boot, režimy okien (páska / dlaždice /
-- plávajúce), vzhľad Latte, skratky a gestá. Vlastné úpravy: ~/.config/latteos/hyprland.lua
-- (načíta sa na konci, takže môže prepísať čokoľvek).

package.path = "/usr/share/latteos/hypr/?.lua;/usr/share/latteos/hypr/?/init.lua;" .. package.path

local modemod = require("latte.mode")
local mode    = modemod.load()
local theme   = modemod.theme()
local tiers   = require("latte.tiers")
local windows = require("latte.windows")

-- ── farby Latte (session/noctalia/palettes/Latte.json) ────────────────────────
local colors = {
    active   = { colors = { "rgb(" .. (theme.border_active or "e4b283") .. ")",
                            "rgb(" .. ((theme.id == "latte") and "c98a55" or (theme.border_active or "e4b283")) .. ")" }, angle = 45 },
    inactive = "rgba(" .. (theme.border_inactive or "4a3b30") .. "aa)",
    shadow   = 0xcc0b0806,
    glow          = 0xaae4b283,
    glow_inactive = 0x00000000,
}

-- ── monitory ──────────────────────────────────────────────────────────────────
-- mierka 1: „auto“ vo VM zvolil 2 (lišta dvojnásobná). Na HW ju neskôr nastaví Device Manager.
-- s grafickou kartou najvyššia obnovovacia frekvencia (vstavaný režim Hyprlandu „highrr“; monitory
-- často ako „preferred“ hlásia 60 Hz, napr. Acer Z301C pri 144 Hz); bez GPU stojí každá snímka CPU → „preferred“
hl.monitor({ output = "", mode = (mode.renderer == "hw") and "highrr" or "preferred", position = "auto", scale = 1 })
-- obrazovky uložené v Device Manageri (latte-devices display keep) prepíšu predvolené pravidlo
do
    local f = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/latteos/monitors.lua"
    local h = io.open(f, "r")
    if h then h:close(); pcall(dofile, f) end
end


-- virtuálna obrazovka: bez fyzického monitora (napr. latte-lab ovládaný na diaľku cez Sunshine/Moonlight) si
-- Hyprland vytvorí LATTE-VIRT 1920×1080; po pripojení monitora ju zruší (setup/lab/vzdialene.sh)
hl.monitor({ output = "LATTE-VIRT", mode = "1920x1080@60", position = "auto", scale = 1 })
local function virtual_screen()
    local phys, virt = 0, false
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name == "LATTE-VIRT" then virt = true
        elseif m.name ~= "FALLBACK" and not m.name:match("^HEADLESS") then phys = phys + 1 end
    end
    if phys == 0 and not virt then hl.exec_cmd("hyprctl output create headless LATTE-VIRT")
    elseif phys > 0 and virt then hl.exec_cmd("hyprctl output remove LATTE-VIRT") end
end
hl.on("monitor.added", virtual_screen)
hl.on("monitor.removed", virtual_screen)

-- ── prostredie ────────────────────────────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "latteos")
-- veľkosť kurzora z Nastavení › Prístupnosť (~/.config/latteos/cursor-size), predvolene 24
local cfgdir = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/latteos"
local cursor_size = "24"
do
    local f = io.open(cfgdir .. "/cursor-size", "r")
    if f then cursor_size = (f:read("*l") or ""):match("^%d+$") or "24"; f:close() end
end
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("HYPRCURSOR_SIZE", cursor_size)

-- ── vzhľad (spoločný pre všetky stupne) ───────────────────────────────────────
-- plocha LatteOS Kvapky (relácia, alebo `latte-kvapky skusit` → príznak v XDG_RUNTIME_DIR): bez lišty Noctalie,
-- ktorá si pás pri okraji vyhradí sama, ho vyhradí LatteOS — rezervou monitora, aby ho rešpektovali aj
-- maximalizované okná (tie medzery gaps_out ignorujú). Obsah príznaku = okraj lišty-kvapky: dole | hore | vlavo | vpravo.
local kvapky = os.getenv("LATTE_VARIANT") == "kvapky" and "dole" or nil
do
    local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/latteos/kvapky", "r")
    if f then kvapky = (f:read("*l") or ""):match("%a+") or "dole"; f:close() end
end
latte = latte or {}
-- pás 54 px + medzera 10 = 64 px pre kvapku; každý monitor s jeho aktuálnym režimom (pravidlo z monitors.lua
-- / Device Managera by inak prázdne pravidlo prebilo). Bez okraja (nil) pás zruší. Volá aj latte-kvapky.
function latte.kvapky_reserve(side)
    local res = { top = 0, right = 0, bottom = 0, left = 0 }
    local key = ({ dole = "bottom", hore = "top", vlavo = "left", vpravo = "right" })[side or ""]
    if key then res[key] = 54 end
    for _, m in ipairs(hl.get_monitors() or {}) do
        hl.monitor({ output = m.name, mode = string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate),
                     position = string.format("%dx%d", m.x, m.y), scale = m.scale, reserved_area = res })
    end
end
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = { active_border = colors.active, inactive_border = colors.inactive },
        resize_on_border = true,
    },
    decoration = { rounding = 14, rounding_power = 2 },     -- jeden polomer pre okná aj panely (radar)
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        -- strážcom je latte-session (pád → reštart / SAFE, aquamarine #383), nie start-hyprland: ten po páde
        -- spustí Hyprland bez -c. Varovanie „launched without start-hyprland“ je preto zbytočné.
        disable_watchdog_warning = true,
    },
    ecosystem = { no_update_news = true, no_donation_nag = true },
    input = {
        kb_layout = "sk,us",
        kb_options = "grp:alt_shift_toggle",
        touchpad = { natural_scroll = true },
    },
})

-- myš a touchpad z Nastavení (Hardvér › Myš, touchpad a ovládače; latte vstup.lua)
do
    local f = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/latteos/vstup.lua"
    local h = io.open(f, "r")
    if h then h:close(); pcall(dofile, f) end
end

-- grafika vo VM: bez HW kurzora; pri vm-3d bez commit timingu (setup/f1/RESULTS.md)
if mode.renderer ~= "hw" then
    hl.config({ cursor = { no_hardware_cursors = true } })
end
if mode.renderer == "vm-3d" then
    hl.config({ render = { commit_timing_enabled = false } })
end

-- téma bez efektov (Úsporná, klasické) obmedzí aj efekty kompozitora
local tier = mode.tier
if theme.effects == "ziadne" and (tier == "plny" or tier == "standard" or tier == "usporny") then tier = "minimalny" end
-- Prístupnosť › Bez animácií (~/.config/latteos/no-animations) platí pri každom stupni aj po hernom režime
local function apply_tier(t)
    tiers.apply(t, colors)
    local f = io.open(cfgdir .. "/no-animations", "r")
    if f then f:close(); hl.config({ animations = { enabled = false } }) end
end
apply_tier(tier)
windows.setup()
if kvapky then latte.kvapky_reserve(kvapky) end      -- po reload-e (pri štarte ešte monitory nie sú: latte-kvapky start)
-- jednotné okenné tlačidlá (hyprbars): minimalizovať, zväčšiť, zavrieť
local bars = require("latte.bars")
bars.setup({ bar_bg = theme.bar_bg, bar_fg = theme.bar_fg, border_active = theme.border_active })

-- herný režim (riadiace centrum Zariadenia / Text Bar): bez efektov a animácií, po vypnutí späť na stupeň.
-- Stav ~/.local/state/latteos/game-mode (1/0). Volá sa: hyprctl eval 'latte.game(true)'
local game_file = (os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")) .. "/latteos/game-mode"
latte = latte or {}
function latte.game(on)
    apply_tier(on and "minimalny" or tier)
    hl.exec_cmd("latte-tapety hra " .. (on and "on" or "off"))       -- živá tapeta: v hre pauza (0 % CPU a GPU)
    hl.config({ decoration = { rounding = on and 0 or 14 }, general = { gaps_in = on and 0 or 5, gaps_out = on and 0 or 10 } })
    local f = io.open(game_file, "w"); if f then f:write(on and "1\n" or "0\n"); f:close() end
    hl.exec_cmd("notify-send -a LatteOS 'Herný režim' '" .. (on and "zapnutý — bez efektov" or "vypnutý") .. "'")
end
do  -- herný režim prežije reload konfigurácie
    local f = io.open(game_file, "r")
    if f then local v = f:read("*l"); f:close(); if v == "1" then latte.game(true) end end
end

-- ── skratky: profil ovládania (latte/skratky.lua) ──────────────────────────────
-- Predvolene Windows (Alt+Tab, Alt+F4, Ctrl+Alt+Del, samotný Win = Štart…), voliteľne Linux alebo macOS
-- (Nastavenia › Hardvér › Klávesnica a skratky → ~/.config/latteos/profil-ovladania). Profil nastaví aj fokus
-- (Windows: kliknutím) a vkladanie stredným tlačidlom (iba Linux).
require("latte.skratky").setup()
-- prichytenie okna ťahaním k okraju ako Windows (režim plávajúcich okien; plugin latte-okna)
require("latte.prichytenie").setup()

-- ── gestá (touchpad) ──────────────────────────────────────────────────────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- 4 prsty hore = prehľad pásky, dole = plocha (radar: „gesto 4 prsty = prehľad“)
hl.gesture({ fingers = 4, direction = "up", action = function() hl.exec_cmd("noctalia msg panel-toggle latteos/overview:panel") end })
hl.gesture({ fingers = 4, direction = "down", action = function() hl.dispatch(hl.dsp.focus({ workspace = "empty" })) end })

-- tapeta podľa plochy (Nastavenia › Prostredie › Pozadie; predvolene vypnuté — každá zmena tapety stojí CPU)
do
    local pref = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/latteos/wallpaper-per-workspace"
    hl.on("workspace.active", function(ws)
        local f = io.open(pref, "r")
        if f and ws and ws.id then f:close(); hl.exec_cmd("latte-theme workspace " .. math.floor(ws.id)) end
    end)
end

-- ── pravidlá okien ────────────────────────────────────────────────────────────
hl.window_rule({ name = "latte-bez-maximalizacie", match = { class = ".*" }, suppress_event = "maximize" })

-- OOM (F5, session/oom): okná aplikácií majú pri nedostatku pamäte prednosť pred kompozitorom a shellom
hl.on("window.open", function(w)
    if w and w.pid and w.pid > 0 then hl.exec_cmd("choom -n 300 -p " .. math.floor(w.pid)) end
end)

-- ── autoštart ─────────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
    virtual_screen()
    -- prostredie pre systemd/D-Bus, potom graphical-session.target (portály pre Flatpak)
    hl.exec_cmd("sh -c 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE "
        .. "HYPRLAND_INSTANCE_SIGNATURE LATTE_MODE LATTE_RENDERER LATTE_TIER LATTE_VARIANT; systemctl --user start latte-session.target'")
    -- relácia LatteOS Kvapky (skúšobná): bez Noctalie a klasických pomocníkov, iba živá tapeta a kvapky
    if os.getenv("LATTE_VARIANT") == "kvapky" then
        hl.exec_cmd("latte-kvapky start")
        hl.exec_cmd("latte-boot ok --after 60 --require pleamar")
        return
    end
    hl.exec_cmd("noctalia")
    -- história schránky pre Kapsu (text aj obrázky)
    hl.exec_cmd("wl-paste --type text --watch latte-kapsa-store")       -- zapnutie a veľkosť histórie: Nastavenia › Schránka
    hl.exec_cmd("wl-paste --type image --watch latte-kapsa-store")
    -- živá tapeta (Nastavenia › Animácie a efekty), ak je zapnutá
    do
        local f = io.open(cfgdir .. "/live-wallpaper", "r")
        if f then f:close(); hl.exec_cmd("latte-app zivatapeta") end
    end
    -- živá video tapeta (Tapety, podľa Aury): posledná voľba; bez GPU ju latte-tapety nespustí
    hl.exec_cmd("latte-tapety obnov")
    -- znak NET pre cudzie okná (ukáže sa, až keď aplikácia použije sieť)
    hl.exec_cmd("latte-app netznak")
    -- výrez Kapsy: prijme súbor pretiahnutý na lištu
    hl.exec_cmd("latte-app kapsavyrez")
    -- živý náhľad okna nad oválom okien
    hl.exec_cmd("latte-app nahlad")
    -- ikony na ploche s košom (vypnutie: Nastavenia › Pozadie)
    hl.exec_cmd("latte-app plocha")
    -- App Manager: rýchle spustenie čaká skryté (otvára ho dlaždica aplikácií cez latte-spustac)
    hl.exec_cmd("latte-app spustac")
    -- softvérové sklo pod panelmi: rozmazaná tapeta (raz, pri zmene tapety znova)
    hl.exec_cmd("sh -c 'sleep 6; latte-sklo'")
    -- systémové ponuky ako vo Windows (Ctrl+Alt+Del, Win+X, Vypnúť, ponuka okna) čakajú skryté
    hl.exec_cmd("latte-app ponuka")
    -- Zariadenia: rýchle nastavenia v tvare L z ostrova zariadení (latte-rychle)
    hl.exec_cmd("latte-app rychle")
    -- Digitálna pohoda: čas v aplikáciách (Monitor › Čas v aplikáciách)
    hl.exec_cmd("latte-app pohoda")
    -- maskot: výbehy z ostrova po lište a oknách (režim world/chaos v paneli maskota)
    hl.exec_cmd("latte-app maskot")
    -- Barista (sprievodca prvým spustením) raz po prvom prihlásení
    do
        local f = io.open(cfgdir .. "/barista-done", "r")
        if f then f:close() else hl.exec_cmd("sh -c 'sleep 4; latte-app barista'") end
    end
    -- relácia je zdravá, ak po 60 s beží shell → počítadlo pádov = 0
    hl.exec_cmd("latte-boot ok --after 60 --require noctalia")
end)

-- ── vlastné úpravy používateľa ────────────────────────────────────────────────
do
    local home = os.getenv("HOME") or ""
    local user = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/latteos/hyprland.lua"
    local f = io.open(user, "r")
    if f then
        f:close()
        local ok, err = pcall(dofile, user)
        if not ok then hl.exec_cmd("notify-send -u critical 'LatteOS' 'Chyba v " .. user .. ": " .. tostring(err):gsub("'", "") .. "'") end
    end
end
