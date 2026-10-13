-- Keyboard shortcuts, as someone coming from Windows expects them. The mouse comes first in LatteOS: every one
-- of these is also a drop or a row of a card, and the Windows key is never the only way (many keyboards
-- made for games have none).
local K = {}

-- `what`: what it does, for someone reading the list in Settings › Keyboard (it lists the binds that say so)
local function bind(keys, action, opts, what)
    if what then opts = opts or {} opts.description = what end
    hl.bind(keys, action, opts)
end
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
    bind("SUPER + SUPER_L", goo("lens_toggle"), { release = true }, "The launcher")
    bind("SUPER + SUPER_R", goo("lens_toggle"), { release = true })
    bind("CTRL + Escape", goo("lens_toggle"), nil, "The launcher, without a Windows key")
    bind("CTRL + SHIFT + Escape", run("latte-app monitor"), nil, "Monitor")       -- the Task Manager's key
    bind("SUPER + I", run("latte-app settings"), nil, "Settings")                  -- and Settings', as on Windows
    bind("SUPER + S", goo("lens_mode 0"), nil, "Search apps and settings")
    bind("SUPER + Q", goo("lens_mode 0"))
    bind("SUPER + R", goo("lens_mode 3"), nil, "Run a command")
    bind("SUPER + C", goo("lens_mode 4"), nil, "Ask the AI")      -- the assistant, as Win+C is on Windows

    bind("SUPER + A", goo("quick_toggle"), nil, "The shore: sound, network, clipboard")
    bind("SUPER + N", goo("clock_notes"), nil, "Notes")
    bind("SUPER + ALT + D", goo("clock_time"), nil, "Clock and calendar")
    bind("SUPER + L", goo("lock_now"), nil, "Lock the session")
    bind("SUPER + T", goo("kb_toggle"), nil, "The drops from the keyboard")        -- Goo from the keyboard, as Win+T goes to the taskbar on Windows

    -- windows
    bind("ALT + F4", hl.dsp.window.close(), nil, "Close the window")
    bind("ALT + Tab", function() latte.win.cycle(1) end, nil, "The next window")
    bind("ALT + SHIFT + Tab", function() latte.win.cycle(-1) end)
    bind("SUPER + D", function() latte.desk.show() end, nil, "Show the desktop")
    bind("SUPER + M", function() latte.win.minimize_all(false) end, nil, "Put all windows away")
    bind("SUPER + SHIFT + M", function() latte.win.restore_all() end, nil, "Bring the windows back")
    bind("SUPER + Home", function() latte.win.minimize_all(true) end, nil, "Put away all windows but this one")
    for _, a in ipairs({ { "up", "Fill the screen with the window" }, { "down", "Make the window smaller, then put it away" },
                         { "left", "The window to the left half" }, { "right", "The window to the right half" } }) do
        bind("SUPER + " .. a[1], function() latte.win.arrow(a[1]) end, nil, a[2])
    end
    for i = 1, 9 do bind("SUPER + " .. i, function() latte.win.nth(i) end, nil, i == 1 and "The first window of the bar; 2 to 9 the next ones" or nil) end
    bind("SUPER + SHIFT + left", hl.dsp.window.move({ monitor = "l" }), nil, "The window to the screen on the left")
    bind("SUPER + SHIFT + right", hl.dsp.window.move({ monitor = "r" }), nil, "The window to the screen on the right")
    bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }, "Move a window, held anywhere")
    bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true }, "Resize a window, held anywhere")

    -- desktops
    bind("SUPER + CTRL + D", function() latte.desk.new() end, nil, "A new desktop")
    bind("SUPER + CTRL + left", function() latte.desk.step(-1) end, nil, "The desktop before")
    bind("SUPER + CTRL + right", function() latte.desk.step(1) end, nil, "The desktop after")
    bind("SUPER + CTRL + F4", function() latte.desk.close() end, nil, "Close the desktop")
    bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

    -- the keyboard's language, the magnifier
    bind("SUPER + Space", run("hyprctl switchxkblayout all next"), nil, "The next keyboard layout")
    bind("SUPER + equal", function() magnify(1) end, nil, "Magnify around the pointer")
    bind("SUPER + KP_Add", function() magnify(1) end)
    bind("SUPER + minus", function() magnify(-1) end, nil, "Magnify less")
    bind("SUPER + KP_Subtract", function() magnify(-1) end)
    bind("SUPER + Escape", function() magnify(0) end, nil, "The magnifier off")

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
