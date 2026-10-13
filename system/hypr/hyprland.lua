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
function latte.band(edge)
    for _, m in ipairs(hl.get_monitors() or {}) do
        hl.monitor({ output = m.name, mode = string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate),
                     position = string.format("%dx%d", m.x, m.y), scale = m.scale, reserved_area = band(edge) })
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
-- The Goo scene belongs on the main monitor, the one in the corner of the layout: it is told its name, or it
-- would come up on whichever monitor the pointer happens to be over. When monitors come and go and the main
-- one is another, the scene starts again there.
local shell_on = nil
local function main_monitor()
    local first
    for _, m in ipairs(hl.get_monitors() or {}) do
        first = first or m.name
        if m.x == 0 and m.y == 0 then return m.name end
    end
    return first
end
local function place_shell()
    local name = main_monitor()
    if not name or name == shell_on then return end
    local again = shell_on ~= nil
    shell_on = name
    hl.exec_cmd("sh -c 'systemctl --user set-environment LATTE_GOO_SCREEN=" .. name .. (again and "; systemctl --user restart latte-goo.service" or "") .. "'")
end
hl.on("monitor.added", place_shell)
hl.on("monitor.removed", place_shell)

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
    -- the new picture comes up before the old one goes, so the background colour never shows through
    hl.exec_cmd("sh -c 'old=$(pgrep -x swaybg); swaybg -i \"$1\" -m fill & sleep 0.6; [ -n \"$old\" ] && kill $old' sh '" .. picture:gsub("'", "'\\''") .. "'")
end

hl.on("hyprland.start", function()
    place_shell()
    latte.wallpaper()
    -- systemd and D-Bus learn where the session is; the target starts the Goo scene and the portals.
    hl.exec_cmd("sh -c 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE "
        .. "HYPRLAND_INSTANCE_SIGNATURE LATTE_MODE LATTE_RENDERER LATTE_TIER LANG; systemctl --user start latte-session.target'")
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
