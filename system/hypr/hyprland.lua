-- LatteOS GOO: Hyprland for the full desktop (bin/latte-session starts it with this file).
--
-- Hyprland keeps the windows; everything one sees and presses around them is the Goo scene (goo/goo.plm),
-- started here as the systemd unit latte-goo.service. The scene asks for what only the compositor can do
-- through `hyprctl eval` and the functions in latte/windows.lua.
-- The user's own changes go in ~/.config/latteos/hyprland.lua, read last, so they can override anything.
local share = os.getenv("LATTE_SHARE") or "/usr/share/latteos"
package.path = share .. "/hypr/?.lua;" .. package.path
latte = {}

local tier = os.getenv("LATTE_TIER") or "software"
local hardware = os.getenv("LATTE_RENDERER") == "hw"
local config = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/latteos"

-- ── monitors ──────────────────────────────────────────────────────────────────────────────────────────────
-- With a card the highest refresh rate: monitors often call 60 Hz their preferred mode. Without one every
-- frame costs the processor. A band along one edge belongs to the drops: windows stay out of it, maximised
-- ones too. It is the bottom edge until the scene says where the window bar is (goo/lib/bar.luau).
local BAND = 54
local function band(edge)
    local area = { top = 0, right = 0, bottom = 0, left = 0 }
    if area[edge] then area[edge] = BAND end
    return area
end
hl.monitor({ output = "", mode = hardware and "highrr" or "preferred", position = "auto", scale = 1, reserved_area = band("bottom") })
local edges = {}                           -- where each monitor's window bar is; "" is every monitor not named
local function screen(name, mode, position, scale, turn)
    hl.monitor({ output = name, mode = mode, position = position, scale = scale, transform = turn, reserved_area = band(edges[name] or edges[""] or "bottom") })
end
-- the band is where that monitor's window bar is; with no monitor named, on all of them
function latte.band(edge, name)
    if (name or "") == "" then edges = { [""] = edge } else edges[name] = edge end
    for _, m in ipairs(hl.get_monitors() or {}) do
        if (name or "") == "" or m.name == name then
            screen(m.name, string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate), string.format("%dx%d", m.x, m.y), m.scale, m.transform)
        end
    end
end
-- The screens as the user set them (Settings › Displays): ~/.config/latteos/monitors, a line for each,
-- NAME MODE POSITION SCALE TURN, as in "DP-3 2560x1080@144 0x0 1 0". A line that says anything else is not read.
local SCREEN = "^(%S+) (%d+x%d+@[%d.]+) (%-?%d+x%-?%d+) ([%d.]+) ([0-7])$"
do
    local f = io.open(config .. "/monitors", "r")
    if f then
        for line in f:lines() do
            local name, mode, position, scale, turn = line:match(SCREEN)
            if name then screen(name, mode, position, tonumber(scale), tonumber(turn)) end
        end
        f:close()
    end
end

local function xkb(what, default)
    local v = os.getenv("XKB_DEFAULT_" .. what)
    return (v and v ~= "") and v or default
end

-- ── the look ──────────────────────────────────────────────────────────────────────────────────────────────
local colors = {
    active = { colors = { "rgb(e4b283)", "rgb(c98a55)" }, angle = 45 },
    inactive = "rgba(4a3b30aa)",
    shadow = 0xcc0b0806,
    glow = 0xaae4b283,
    button = "rgb(e4b283)",
}
hl.config({
    general = {
        gaps_in = 5, gaps_out = 10, border_size = 2, resize_on_border = true,
        col = { active_border = colors.active, inactive_border = colors.inactive },
    },
    decoration = { rounding = 14, rounding_power = 2 },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = 0xff1a1410,         -- espresso, as on the login screen: no black step in between
        force_default_wallpaper = 0,
        -- bin/latte-session is the watchdog: it restarts Hyprland after a crash or goes to SAFE
        disable_watchdog_warning = true,
        -- Should the Goo scene die while it holds the lock, the one started in its place may lock again.
        allow_session_lock_restore = true,
        middle_click_paste = false,
    },
    ecosystem = { no_update_news = true, no_donation_nag = true },
    input = {
        -- the keyboard layout is the system's (system/session-env.sh)
        kb_layout = xkb("LAYOUT", "us"),
        kb_variant = xkb("VARIANT", ""),
        kb_options = xkb("OPTIONS", ""),
        follow_mouse = 2,                      -- a window gets the keyboard when it is clicked, as on Windows
        touchpad = { natural_scroll = true },
    },
    -- The pointer never moves by itself: switching windows from the bar would otherwise pull it away from the bar.
    cursor = { no_warps = true, no_hardware_cursors = not hardware },
})
require("latte.tiers").apply(tier, colors)

-- ── windows, keys ─────────────────────────────────────────────────────────────────────────────────────────
require("latte.windows").setup()
require("latte.keys").setup()
require("latte.bars").setup(colors)
-- The cup: what the windows are made of. The title bars take its colour, and apps are told whether it is
-- a light or a dark one, so that they come in the same. Without a name: the one the user chose before.
local function chosen_cup()
    local f = io.open(config .. "/cup", "r")
    local name = f and (f:read("*l") or ""):gsub("%s", "") or "espresso"
    if f then f:close() end
    return name
end
function latte.cup(name)
    name = name or chosen_cup()
    require("latte.bars").cup(name)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme " .. (name == "porcelain" and "prefer-light" or "prefer-dark"))
end
require("latte.bars").cup(chosen_cup())    -- here too: the configuration is read anew at times
require("latte.glass").setup(tier)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- an app's request to maximise itself is not obeyed: it would cover the drops' band
hl.window_rule({ name = "latte-no-self-maximize", match = { class = ".*" }, suppress_event = "maximize" })
-- a window that fills the screen is being watched or played, with a gamepad as likely as not: nothing locks or goes dark
hl.window_rule({ name = "latte-fullscreen-awake", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- When memory runs out, an app's window goes before the compositor and the shell do.
hl.on("window.open", function(w)
    if w and w.pid and w.pid > 0 then hl.exec_cmd("choom -n 300 -p " .. math.floor(w.pid)) end
end)

-- ── the start ─────────────────────────────────────────────────────────────────────────────────────────────
-- The Goo scene belongs on the main monitor: a real one before the virtual one a machine without a screen is
-- reached through (its EDID says LATTE-VIRT), and of those the leftmost. It is told its name, or it would come
-- up on whichever monitor the pointer happens to be over.
local function virtual(m) return (m.description or ""):find("LATTE-VIRT", 1, true) ~= nil or m.name == os.getenv("LATTE_VIRT") end
local function main_monitor()
    local best
    for _, m in ipairs(hl.get_monitors() or {}) do
        if not best or (virtual(best) and not virtual(m)) or (virtual(best) == virtual(m) and m.x < best.x) then best = m end
    end
    return best
end
-- Beside a real monitor the virtual one shows the same picture: nobody sits in front of it, and a window that
-- went there could not be found. When the real one goes it is a monitor of its own again.
local mirrored = nil
local function mirror()
    local main = main_monitor()
    if not main then
        if mirrored then hl.monitor({ output = mirrored, mode = "preferred", position = "auto", scale = 1, reserved_area = band(edges[mirrored] or edges[""] or "bottom") }) end
        mirrored = nil
        return
    end
    if virtual(main) then return end
    for _, m in ipairs(hl.get_monitors() or {}) do
        if virtual(m) then
            hl.monitor({ output = m.name, mode = string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate), position = "auto", scale = 1, mirror = main.name })
            mirrored = m.name
        end
    end
end
-- Every other monitor has a window bar of its own, a scene for each (latte-goo-side@NAME.service). Which scenes
-- run is latte-screens's business: it looks at what runs, so nothing is remembered here that a reload would lose.
-- `before`: what the session's start says first.
local function place_shell(before)
    if type(before) ~= "string" then before = nil end
    mirror()
    local main = main_monitor()
    if not main then return end
    local names = { main.name }
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= main.name and m.name ~= mirrored then names[#names + 1] = m.name end
    end
    hl.exec_cmd("sh -c '" .. (before and (before .. "; latte-screens --start ") or "latte-screens ") .. table.concat(names, " ") .. "'")
end
hl.on("monitor.added", place_shell)
hl.on("monitor.removed", place_shell)
hl.on("config.reloaded", place_shell)
-- A screen as the user wants it now; with `keep` it also comes up so the next time. Settings tries a change
-- without keeping it and puts the old one back unless the user says the picture is fine.
function latte.screen(name, mode, position, scale, turn, keep)
    local line = string.format("%s %s %s %s %d", name, mode, position, scale, turn)
    if not line:match(SCREEN) then return end
    screen(name, mode, position, scale, turn)
    -- once it is so: the main monitor may be another one now, and a window may be left outside the picture
    hl.timer(function() place_shell() latte.win.gather() end, { timeout = 600, type = "oneshot" })
    if not keep then return end
    local lines = {}
    local f = io.open(config .. "/monitors", "r")
    if f then
        for old in f:lines() do if old:match("^(%S+)") ~= name then lines[#lines + 1] = old end end
        f:close()
    end
    lines[#lines + 1] = line
    os.execute("mkdir -p '" .. config .. "'")
    f = io.open(config .. "/monitors", "w")
    if f then f:write(table.concat(lines, "\n") .. "\n") f:close() end
end

-- The wallpaper: the user's own choice (a path in ~/.config/latteos/wallpaper), or the one LatteOS brings.
-- With a path it becomes the choice; the picture on the screen changes at once.
function latte.wallpaper(path)
    if path then
        os.execute("mkdir -p '" .. config .. "'")
        local f = io.open(config .. "/wallpaper", "w")
        if f then f:write(path .. "\n") f:close() end
    end
    local picture = share .. "/wallpapers/latteos-2.jpg"
    local chosen = io.open(config .. "/wallpaper", "r")
    if chosen then
        local kept = (chosen:read("*l") or ""):gsub("^%s+", ""):gsub("%s+$", "")
        chosen:close()
        local there = kept ~= "" and io.open(kept, "r")
        if there then there:close() picture = kept end
    end
    -- The new one comes up before the old one goes, so the background colour never shows through. A film is
    -- played by mpvpaper, silent and round again; a picture is shown by swaybg.
    local film = picture:lower():match("%.mp4$") or picture:lower():match("%.webm$") or picture:lower():match("%.mkv$") or picture:lower():match("%.mov$")
    local show = film and "mpvpaper -o \"no-audio loop\" \"*\" \"$1\"" or "swaybg -i \"$1\" -m fill"
    hl.exec_cmd("sh -c 'old=$(pgrep -x swaybg; pgrep -x mpvpaper); " .. show .. " & sleep 0.8; [ -n \"$old\" ] && kill $old' sh '" .. picture:gsub("'", "'\\''") .. "'")
end

hl.on("hyprland.start", function()
    latte.wallpaper()
    latte.cup()
    -- systemd and D-Bus learn where the session is; the target starts the Goo scene and the portals.
    place_shell("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE "
        .. "HYPRLAND_INSTANCE_SIGNATURE LATTE_MODE LATTE_RENDERER LATTE_TIER LANG")
    -- What is copied is kept (cliphist), for the clipboard in the shore's panel; without cliphist nothing is.
    hl.exec_cmd("sh -c 'command -v cliphist >/dev/null && exec wl-paste --watch cliphist store'")
    -- A session whose shell is still up after a minute is a healthy one: the crash count goes back to zero.
    hl.exec_cmd("latte-boot ok --after 60 --require pleamar")
end)

-- ── the user's own ────────────────────────────────────────────────────────────────────────────────────────
do
    local own = config .. "/hyprland.lua"
    local f = io.open(own, "r")
    if f then
        f:close()
        local ok, err = pcall(dofile, own)
        if not ok then hl.exec_cmd("notify-send -u critical LatteOS '" .. own .. ": " .. tostring(err):gsub("'", "") .. "'") end
    end
end
