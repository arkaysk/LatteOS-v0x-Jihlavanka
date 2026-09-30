-- Sklo okien aplikácií (1. 10. 2026): plugin Hyprglass (github.com/hyprnux/hyprglass, BSD-3, stavaný na Hyprland
-- 0.56.2) — lom svetla na okrajoch, dúhová chromatická aberácia (perleťové okraje, ako v ricu „Caelestia +
-- Hyprglass“ od používateľa), matné rozmazanie, odlesk. Iba plocha LatteOS Goo (Kvapky) a iba sklenené materiály
-- tém (sklo, fazety, mráz, jantár); kovové témy majú textúru v oknách Goo, nie sklo. Sklo platí pre trochu priehľadné
-- okná: aktívne 93 %, neaktívne 87 %; celá obrazovka (hry, video) zostáva plná a bez skla.
-- Vrstvy (lišty, scéna Kvapiek) nechá tak: pleamar si sklo kreslí sám.
-- Vypnutie: ~/.config/latteos/bez-skla
local S = {}
S.plugin = "/usr/lib64/latteos/hyprglass.so"
local GLASS = { sklo = true, fazety = true, mraz = true, jantar = true }

local function file_exists(p)
    local f = io.open(p, "r")
    if f then f:close() return true end
    return false
end

function S.setup(theme, goo)
    if not goo or not GLASS[theme.material or ""] then return false end
    local cfg = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
    if file_exists(cfg .. "/latteos/bez-skla") or not file_exists(S.plugin) then return false end
    local ok = pcall(hl.plugin.load, S.plugin)
    if not ok or not (hl.plugin and hl.plugin.hyprglass) then return false end
    local hg = hl.plugin.hyprglass
    hg.config({
        default_theme = theme.effective_mode == "light" and "light" or "dark",
        default_preset = "latte",
        layers = { enabled = false },
    })
    -- perleť: silnejšia dúha na okrajoch a lom, jemné rozmazanie, aby text v okne ostal čitateľný
    hg.preset("latte", {
        glass_opacity = 0.92,
        blur_strength = 2.2,
        refraction_strength = 0.7,
        chromatic_aberration = 0.9,
        edge_thickness = 0.07,
        specular_strength = 0.8,
        fresnel_strength = 0.6,
    })
    hl.config({ decoration = { active_opacity = 0.93, inactive_opacity = 0.87, fullscreen_opacity = 1.0 } })
    return true
end

return S
