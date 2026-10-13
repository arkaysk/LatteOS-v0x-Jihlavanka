-- Keyboard shortcuts, as someone coming from Windows expects them. The mouse comes first in LatteOS: every one
-- of these is also a drop or a row of a card, and the Windows key is never the only way (many keyboards
-- made for games have none).
local K = {}

local function bind(keys, action, opts) hl.bind(keys, action, opts) end
local function run(cmd) return hl.dsp.exec_cmd(cmd) end
local function goo(event) return run('pleamar --say goo "emit ' .. event .. '"') end

-- a magnifier around the pointer
local zoom = 1
local function magnify(step)
    zoom = step == 0 and 1 or math.max(1, math.min(8, zoom * (step > 0 and 1.25 or 0.8)))
    if zoom < 1.05 then zoom = 1 end
    hl.config({ cursor = { zoom_factor = zoom } })
end

-- A desktop computer starts with Num Lock on; a laptop does not, where it may turn letters into digits.
local function numlock()
    local f = io.open("/sys/class/dmi/id/chassis_type", "r")
    if not f then return false end
    local t = tonumber(f:read("*l") or "") or 0
    f:close()
    -- SMBIOS chassis types that stand on a desk; a virtual machine says 1 (other)
    local desk = { [1] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [13] = true, [15] = true,
                   [16] = true, [17] = true, [23] = true, [24] = true, [35] = true }
    return desk[t] == true
end

function K.setup()
    -- the launcher: the Windows key alone (on release, or it would fire with every Win+key), and Ctrl+Esc without one
    bind("SUPER + SUPER_L", goo("lens_toggle"), { release = true })
    bind("SUPER + SUPER_R", goo("lens_toggle"), { release = true })
    bind("CTRL + Escape", goo("lens_toggle"))
    bind("CTRL + SHIFT + Escape", run("latte-app monitor"))       -- the Task Manager's key
    bind("SUPER + S", goo("lens_mode 0"))
    bind("SUPER + Q", goo("lens_mode 0"))
    bind("SUPER + R", goo("lens_mode 3"))
    bind("SUPER + C", goo("lens_mode 4"))      -- the assistant, as Win+C is on Windows

    bind("SUPER + A", goo("quick_toggle"))
    bind("SUPER + N", goo("clock_notes"))
    bind("SUPER + ALT + D", goo("clock_time"))
    bind("SUPER + L", goo("lock_now"))
    bind("SUPER + T", goo("kb_toggle"))        -- Goo from the keyboard, as Win+T goes to the taskbar on Windows

    -- windows
    bind("ALT + F4", hl.dsp.window.close())
    bind("ALT + Tab", function() latte.win.cycle(1) end)
    bind("ALT + SHIFT + Tab", function() latte.win.cycle(-1) end)
    bind("SUPER + D", function() latte.desk.show() end)
    bind("SUPER + M", function() latte.win.minimize_all(false) end)
    bind("SUPER + SHIFT + M", function() latte.win.restore_all() end)
    bind("SUPER + Home", function() latte.win.minimize_all(true) end)
    for _, dir in ipairs({ "up", "down", "left", "right" }) do
        bind("SUPER + " .. dir, function() latte.win.arrow(dir) end)
    end
    for i = 1, 9 do bind("SUPER + " .. i, function() latte.win.nth(i) end) end
    bind("SUPER + SHIFT + left", hl.dsp.window.move({ monitor = "l" }))
    bind("SUPER + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))
    bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- desktops
    bind("SUPER + CTRL + D", function() latte.desk.new() end)
    bind("SUPER + CTRL + left", function() latte.desk.step(-1) end)
    bind("SUPER + CTRL + right", function() latte.desk.step(1) end)
    bind("SUPER + CTRL + F4", function() latte.desk.close() end)
    bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

    -- the keyboard's language, the magnifier
    bind("SUPER + Space", run("hyprctl switchxkblayout all next"))
    bind("SUPER + equal", function() magnify(1) end)
    bind("SUPER + KP_Add", function() magnify(1) end)
    bind("SUPER + minus", function() magnify(-1) end)
    bind("SUPER + KP_Subtract", function() magnify(-1) end)
    bind("SUPER + Escape", function() magnify(0) end)

    -- the keys a keyboard has for sound and brightness
    bind("XF86AudioRaiseVolume", run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    bind("XF86AudioLowerVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
    bind("XF86AudioMute", run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
    bind("XF86AudioMicMute", run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
    bind("XF86MonBrightnessUp", run("brightnessctl set 5%+"), { locked = true, repeating = true })
    bind("XF86MonBrightnessDown", run("brightnessctl set 5%-"), { locked = true, repeating = true })

    hl.config({ input = { numlock_by_default = numlock() } })
end

return K
