-- Glass windows: with the drops made of glass (Goo's settings: "Coffee in glass") the windows are glass too.
-- They turn slightly see-through and the plugin Hyprglass bends and blurs what is behind them, with a rim of
-- light. Only on a card that has the power for blur (tiers full and standard); a window that fills the screen
-- stays solid. The Goo scene says when (`latte.glass(1)`, 2 for True Glass, goo/lib/wm.luau); the choice is kept in
-- ~/.local/state/latteos/glass: the plugin is loaded with the configuration, which is read anew at times.
-- Without the plugin nothing here happens.
local G = {}

G.plugin = (os.getenv("LATTE_PLUGINS") or "/usr/lib64/latteos") .. "/hyprglass.so"
local state = (os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")) .. "/latteos/glass"

-- 0 solid, 1 glass windows, 2 True Glass
local function wanted()
    local f = io.open(state, "r")
    if not f then return 0 end
    local v = tonumber(f:read("*l")) or 0
    f:close()
    return v
end

local function loaded() return hl.plugin ~= nil and hl.plugin.hyprglass ~= nil end
local function apply(mode)
    if not loaded() then return end
    local glass, on = hl.plugin.hyprglass, mode > 0
    if on then
        -- the presets before one is named as the default one, or it is unknown
        glass.preset("latte", { glass_opacity = 0.85, blur_strength = 2.2, refraction_strength = 0.9, chromatic_aberration = 1.2,
                                edge_thickness = 0.12, specular_strength = 0.8, fresnel_strength = 0.6 })
        -- True Glass: less blur, more bending and light on the rim, as clear glass
        glass.preset("latte-true", { glass_opacity = 0.7, blur_strength = 1.4, refraction_strength = 1.8, chromatic_aberration = 1.6,
                                     edge_thickness = 0.18, specular_strength = 1.1, fresnel_strength = 0.9 })
    end
    -- the scene is a layer and makes its own glass: layers are left alone
    glass.config({ enabled = on, default_theme = "dark", default_preset = mode == 2 and "latte-true" or (on and "latte" or nil), layers = { enabled = false } })
    -- an app paints its background solid: the glass shows only through a window that is a little see-through. With
    -- True Glass LatteOS's own apps make their ground clear themselves (Theme.trueGlass) and keep their writing whole,
    -- so no window is made see-through as a whole: other programs stay solid and readable
    local see = mode == 1
    hl.config({ decoration = { active_opacity = see and 0.86 or 1.0, inactive_opacity = see and 0.78 or 1.0, fullscreen_opacity = 1.0 } })
end

function G.setup(tier)
    local f = io.open(G.plugin, "r")
    if f then f:close() end
    local able = f ~= nil and (tier == "full" or tier == "standard")
    function latte.glass(mode)
        mode = (mode == true and 1) or (able and tonumber(mode)) or 0
        if mode == wanted() and (loaded() or mode == 0) then return end
        os.execute("mkdir -p \"$(dirname '" .. state .. "')\"")
        local file = io.open(state, "w")
        if file then file:write(mode .. "\n") file:close() end
        -- A plugin is loaded only while the configuration is read: the first time glass is wanted it is read again.
        if mode > 0 and not loaded() then hl.exec_cmd("hyprctl reload") else apply(mode) end
    end
    if not able or wanted() == 0 then return end
    pcall(hl.plugin.load, G.plugin)
    hl.on("hyprland.start", function() apply(wanted()) end)
    hl.on("config.reloaded", function() apply(wanted()) end)
end

return G
