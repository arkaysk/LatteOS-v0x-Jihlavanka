-- What the compositor spends on looks, by the tier latte-boot chose for the hardware (LATTE_TIER).
local T = {}

-- blur, shadow and the active window's glow; `motion` is how much shorter the animations are, none without it
T.levels = {
    full     = { blur = { size = 6, passes = 2 }, shadow = 22, glow = true, motion = 1.0, orbit = true, wobble = true },
    -- The border's turning gradient paints every frame: a fifth of a core on an RX 640 at 144 Hz.
    standard = { blur = { size = 4, passes = 1 }, shadow = 14, glow = true, motion = 1.0, wobble = true },
    eco      = { motion = 1.6 },
    minimal  = {},
    software = {},                             -- no card: every movement costs the processor
}

function T.apply(name, colors)
    local t = T.levels[name] or T.levels.software
    hl.config({
        decoration = {
            blur = t.blur and { enabled = true, size = t.blur.size, passes = t.blur.passes, vibrancy = 0.17 } or { enabled = false },
            shadow = t.shadow and { enabled = true, range = t.shadow, render_power = 3, color = colors.shadow } or { enabled = false },
            glow = t.glow and { enabled = true, range = 10, render_power = 3, color = colors.glow, color_inactive = 0x00000000 } or { enabled = false },
            -- a window being moved or resized bends like jelly and settles (Hyprland 0.57)
            wobble = { enabled = t.wobble == true },
        },
        animations = { enabled = t.motion ~= nil },
    })
    if not t.motion then return end
    local s = t.motion
    hl.curve("latteOut", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
    hl.curve("latteSpring", { type = "spring", mass = 1, stiffness = 238, damping = 24 })
    hl.curve("latteLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
    hl.animation({ leaf = "global", enabled = true, speed = 6 / s, bezier = "latteOut" })
    hl.animation({ leaf = "windows", enabled = true, speed = 4.8 / s, spring = "latteSpring" })
    hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1 / s, spring = "latteSpring", style = "popin 90%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5 / s, bezier = "latteOut", style = "popin 90%" })
    hl.animation({ leaf = "fade", enabled = true, speed = 3.0 / s, bezier = "latteOut" })
    hl.animation({ leaf = "border", enabled = true, speed = 5.4 / s, bezier = "latteOut" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 2.0 / s, bezier = "latteOut", style = "slide" })
    hl.animation({ leaf = "layers", enabled = true, speed = 3.8 / s, bezier = "latteOut", style = "fade" })
    hl.animation({ leaf = "borderangle", enabled = t.orbit == true, speed = 100, bezier = "latteLinear", style = "loop" })
end

return T
