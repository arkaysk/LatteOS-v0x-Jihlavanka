-- Glass windows: with the drops made of glass (Goo's settings: "Coffee in glass") the windows are glass too.
-- They turn slightly see-through and the plugin Hyprglass bends and blurs what is behind them, with a rim of
-- light. Only on a card that has the power for blur (tiers full and standard); a window that fills the screen
-- stays solid. The Goo scene says when (`latte.glass(true)`, goo/lib/wm.luau); the choice is kept in
-- ~/.local/state/latteos/glass: the plugin is loaded with the configuration, which is read anew at times.
-- Without the plugin nothing here happens.
local G = {}

G.plugin = (os.getenv("LATTE_PLUGINS") or "/usr/lib64/latteos") .. "/hyprglass.so"
local state = (os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")) .. "/latteos/glass"

local function wanted()
    local f = io.open(state, "r")
    if not f then return false end
    local v = f:read("*l")
    f:close()
    return v == "1"
end

local function loaded() return hl.plugin ~= nil and hl.plugin.hyprglass ~= nil end
local function apply(on)
    if not loaded() then return end
    local glass = hl.plugin.hyprglass
    if on then
        -- the preset before it is named as the default one, or it is unknown
        glass.preset("latte", { glass_opacity = 0.85, blur_strength = 2.2, refraction_strength = 0.9, chromatic_aberration = 1.2,
                                edge_thickness = 0.12, specular_strength = 0.8, fresnel_strength = 0.6 })
    end
    -- the scene is a layer and makes its own glass: layers are left alone
    glass.config({ enabled = on, default_theme = "dark", default_preset = on and "latte" or nil, layers = { enabled = false } })
    -- an app paints its background solid: the glass shows only through a window that is a little see-through
    hl.config({ decoration = { active_opacity = on and 0.86 or 1.0, inactive_opacity = on and 0.78 or 1.0, fullscreen_opacity = 1.0 } })
end

function G.setup(tier)
    local f = io.open(G.plugin, "r")
    if f then f:close() end
    local able = f ~= nil and (tier == "full" or tier == "standard")
    function latte.glass(on)
        on = on == true and able
        if on == wanted() and (loaded() or not on) then return end
        os.execute("mkdir -p \"$(dirname '" .. state .. "')\"")
        local file = io.open(state, "w")
        if file then file:write(on and "1\n" or "0\n") file:close() end
        -- A plugin is loaded only while the configuration is read: the first time glass is wanted it is read again.
        if on and not loaded() then hl.exec_cmd("hyprctl reload") else apply(on) end
    end
    if not able or not wanted() then return end
    pcall(hl.plugin.load, G.plugin)
    hl.on("hyprland.start", function() apply(true) end)
    hl.on("config.reloaded", function() apply(true) end)
end

return G
