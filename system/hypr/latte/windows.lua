-- How windows are arranged, and what the bar asks of them.
--
-- Four modes, as the head of the window bar shows them:
--   tape      an endless horizontal strip (Hyprland's scrolling layout); nothing is ever put away
--   tiles     tiles (dwindle)
--   floating  every window floats, as on Windows
--   glance    one window in the middle, the others looking out from the sides (after Scott Jenson's Glance)
-- The choice is kept in ~/.local/state/latteos/window-mode and told to the Goo scene (its event `window_mode`).
--
-- A window put away sits on the hidden workspace special:minimized. The scene knows windows by the address
-- `hyprctl clients` gives them and calls the functions in `latte.win` with it (goo/lib/wm.luau).
local W = {}

W.order = { "tape", "tiles", "floating", "glance" }
local MINIMIZED = "special:minimized"
local GAP = 10
local state = (os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")) .. "/latteos/window-mode"
local float_rule

local function valid(mode) for _, m in ipairs(W.order) do if m == mode then return true end end return false end
local function load_mode()
    local f = io.open(state, "r")
    if not f then return "tape" end
    local m = (f:read("*l") or ""):match("%a+")
    f:close()
    return valid(m) and m or "tape"
end
local function save_mode(m)
    os.execute("mkdir -p \"$(dirname '" .. state .. "')\"")
    local f = io.open(state, "w")
    if f then f:write(m .. "\n") f:close() end
end

local function sel(w) return "address:" .. w.address end
local function find(address) return address and hl.get_window("address:" .. address) end
local function put_away(w) return w.workspace ~= nil and tostring(w.workspace.name or ""):find("^special:minimized") ~= nil end
local function xy(v) if type(v) == "table" then return v.x or v[1] or 0, v.y or v[2] or 0 end return 0, 0 end
local function tape() return W.current == "tape" end

-- ── parts of the screen a window can be laid in, as shares of what the monitor has free: x, y, w, h ───────
local zones = {
    left = { 0, 0, 1 / 2, 1 },      right = { 1 / 2, 0, 1 / 2, 1 },   top = { 0, 0, 1, 1 / 2 },      bottom = { 0, 1 / 2, 1, 1 / 2 },
    tl = { 0, 0, 1 / 2, 1 / 2 },    tr = { 1 / 2, 0, 1 / 2, 1 / 2 },  bl = { 0, 1 / 2, 1 / 2, 1 / 2 }, br = { 1 / 2, 1 / 2, 1 / 2, 1 / 2 },
    center = { 0.15, 0.1, 0.7, 0.8 }, full = { 0, 0, 1, 1 },
}
local before = {}            -- address → where the window was before it was laid in a zone
local function place(w, r)
    if not w.floating then hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel(w) })) end
    hl.dispatch(hl.dsp.window.resize({ x = r.w, y = r.h, window = sel(w) }))
    hl.dispatch(hl.dsp.window.move({ x = r.x, y = r.y, window = sel(w) }))
end
local function snap(w, zone, on)
    local z, m = zones[zone], on or w.monitor or hl.get_active_monitor()
    if not z or not m then return end
    local scale, res = m.scale or 1, m.reserved or { top = 0, right = 0, bottom = 0, left = 0 }
    local ax, ay = m.x + res.left + GAP, m.y + res.top + GAP
    local aw, ah = m.width / scale - res.left - res.right - 2 * GAP, m.height / scale - res.top - res.bottom - 2 * GAP
    if w.fullscreen == 1 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = sel(w) })) end
    if not before[w.address] then
        local x, y = xy(w.at)
        local ww, wh = xy(w.size)
        before[w.address] = { x = x, y = y, w = ww, h = wh }
    end
    place(w, {
        x = math.floor(ax + z[1] * aw + (z[1] > 0 and GAP / 2 or 0)),
        y = math.floor(ay + z[2] * ah + (z[2] > 0 and GAP / 2 or 0)),
        w = math.floor(z[3] * aw - ((z[1] > 0 or z[1] + z[3] < 1) and GAP / 2 or 0)),
        h = math.floor(z[4] * ah - ((z[2] > 0 or z[2] + z[4] < 1) and GAP / 2 or 0)),
    })
end
local function unsnap(w)
    local r = before[w.address]
    if not r then return false end
    before[w.address] = nil
    place(w, r)
    return true
end

-- ── a window dropped at an edge of the screen is laid there, as on Windows ────────────────────────────────
-- The pointer at the top edge: maximised; at a side: that half; near a corner of a side: that quarter. A
-- window taken out of a zone and dropped elsewhere has its own size again. Floating windows only: on the
-- tape and in tiles the layout places them. Hyprland does not say when a window is let go; the plugin
-- latte-events does (plugins/latte-events), and without it nothing here happens.
W.plugin = (os.getenv("LATTE_PLUGINS") or "/usr/lib64/latteos") .. "/latte-events.so"
local EDGE, CORNER = 8, 0.18         -- px from the edge; the share of a side that counts as its corner
local function edge_zone(m, x, y)
    local scale = m.scale or 1
    local w, h = m.width / scale, m.height / scale
    local rx, ry = x - m.x, y - m.y
    -- an edge another monitor continues behind is no edge: the pointer is only on its way there
    local function open_edge(px, py) local o = hl.get_monitor_at(px, py) return o == nil or o.name == m.name end
    local side = (rx <= EDGE and open_edge(m.x - 2, y) and "l") or (rx >= w - 1 - EDGE and open_edge(m.x + w + 2, y) and "r") or nil
    if side then
        if ry <= h * CORNER then return "t" .. side end
        if ry >= h * (1 - CORNER) then return "b" .. side end
        return side == "l" and "left" or "right"
    end
    return (ry <= EDGE and open_edge(x, m.y - 2)) and "full" or nil
end
-- Wherever it is let go, a window stays within reach: its top on the screen, where its header and its buttons
-- are, and enough of it to take hold of. One that was dropped further out comes back that far.
-- `whole`: all of it comes back, made smaller if the screen is; for when the screen changed under it.
local function within_reach(w, m, whole)
    local scale, res = m.scale or 1, m.reserved or { top = 0, right = 0, bottom = 0, left = 0 }
    local mw, mh = m.width / scale, m.height / scale
    if (m.transform or 0) % 2 == 1 then mw, mh = mh, mw end
    local x, y = xy(w.at)
    local width, height = xy(w.size)
    local nx = math.max(m.x - width + 140, math.min(x, m.x + mw - 140))
    local ny = math.max(m.y + (res.top or 0), math.min(y, m.y + mh - (res.bottom or 0) - 70))
    if whole then
        local fw, fh = math.min(width, mw), math.min(height, mh - (res.top or 0) - (res.bottom or 0))
        if fw ~= width or fh ~= height then hl.dispatch(hl.dsp.window.resize({ x = math.floor(fw), y = math.floor(fh), window = sel(w) })) end
        nx = math.max(m.x, math.min(x, m.x + mw - fw))
        ny = math.max(m.y + (res.top or 0), math.min(y, m.y + mh - (res.bottom or 0) - fh))
    end
    if nx ~= x or ny ~= y then hl.dispatch(hl.dsp.window.move({ x = math.floor(nx), y = math.floor(ny), window = sel(w) })) end
end
local glance_dropped                 -- what glance does with a window let go; set further down
local function dropped(w, x, y)
    if w and W.current == "glance" then return glance_dropped(w, x, y) end
    if not w or W.current ~= "floating" then return end
    local m = hl.get_monitor_at(x, y) or w.monitor
    local zone = m and edge_zone(m, x, y)
    if zone == "full" then
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set", window = sel(w) }))
    elseif zone then
        snap(w, zone, m)
    else
        local r = before[w.address]
        if r then
            before[w.address] = nil
            hl.dispatch(hl.dsp.window.resize({ x = r.w, y = r.h, window = sel(w) }))
        end
        if m then within_reach(w, m) end
    end
end
local cut = {}                              -- address → true: windows of an app cut off the internet (below)
hl.on("window.close", function(w) if w then before[w.address] = nil cut[w.address] = nil end end)
-- ── a window that plays a sound or asks to be looked at says so itself: its border pulses ────────────────
-- Where one looks for it is the window. Which windows ask for attention the compositor knows; which ones
-- sound, the Goo scene says (`latte.win.sounding`: it hears the mixer). Asking is red and quick and lasts
-- until the window is in front; a sound is pale and slow, and not shown on the window one is working in.
local wanting, sounding = {}, {}           -- address → true
local ATTENTION, SOUND = "rgb(e5484d)", "rgb(ffe8c2)"
local beat, lit, slow = nil, false, 0
-- An app cut off the internet (bin/latte-net) says so too: its windows keep a border the colour of cold steel.
local CUT = "rgb(6c7a89)"
local function border(address, color, size)
    if not color and cut[address] then color = CUT end
    local set = function(prop, value) hl.dispatch(hl.dsp.window.set_prop({ prop = prop, value = value or "unset", window = "address:" .. address })) end
    set("active_border_color", color)
    set("inactive_border_color", color)
    set("border_size", size)
end
local function pulse()
    lit, slow = not lit, (slow + 1) % 4
    local active, any = hl.get_active_window(), false
    for address in pairs(wanting) do
        if find(address) then any = true border(address, lit and ATTENTION or nil, lit and "3" or nil) else wanting[address] = nil end
    end
    for address in pairs(sounding) do
        if not wanting[address] then
            if not find(address) then sounding[address] = nil
            else
                any = true
                local mine = active ~= nil and active.address == address
                if slow % 2 == 0 then border(address, (slow == 0 and not mine) and SOUND or nil) end
            end
        end
    end
    if not any and beat then beat:set_enabled(false) end
end
local function start_pulse()
    if not beat then beat = hl.timer(pulse, { timeout = 450, type = "repeat" }) end
    beat:set_enabled(true)
end
hl.on("window.urgent", function(w)
    if not w or not w.address then return end
    wanting[w.address] = true
    start_pulse()
    -- the bar waves too when the window is out of sight
    hl.exec_cmd(string.format('latte-say "text win_wants %s" "emit win_urgent"', w.address))
end)
hl.on("window.active", function(w)
    if w and w.address and wanting[w.address] then wanting[w.address] = nil border(w.address) end
end)
-- the windows that sound now, as a list of addresses; the ones that no longer do go back to their own border
local function set_sounding(list)
    local now = {}
    for _, address in ipairs(type(list) == "table" and list or {}) do now[address] = true end
    for address in pairs(sounding) do if not now[address] and not wanting[address] and find(address) then border(address) end end
    sounding = now
    if next(now) then start_pulse() end
end

local function windows_on(workspace)
    local out = {}
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.mapped ~= false and w.workspace and w.workspace.id == workspace then out[#out + 1] = w end
    end
    return out
end

-- The hidden workspace must not stay shown: new windows would open on it and look put away.
local function hide_special()
    for _, m in ipairs(hl.get_monitors() or {}) do
        local sp = m.active_special_workspace
        if sp and tostring(sp.name or ""):find("^special:minimized") then
            hl.dispatch(hl.dsp.workspace.toggle_special("minimized"))
            return
        end
    end
end
local function activate(w)
    local ws = hl.get_active_workspace()
    if put_away(w) and ws then hl.dispatch(hl.dsp.window.move({ workspace = tostring(ws.id), window = sel(w) })) end
    hl.dispatch(hl.dsp.focus({ window = sel(w) }))
    hide_special()
end
local function cycle(dir)
    local ws, active = hl.get_active_workspace(), hl.get_active_window()
    local list = ws and windows_on(ws.id) or {}
    if #list == 0 then return end
    table.sort(list, function(p, q)
        local px, py = xy(p.at)
        local qx, qy = xy(q.at)
        if px ~= qx then return px < qx end
        return py < qy
    end)
    local at = 0
    for i, w in ipairs(list) do if active and w.address == active.address then at = i end end
    hl.dispatch(hl.dsp.focus({ window = sel(list[(at - 1 + (dir or 1)) % #list + 1]) }))
    hide_special()
end
-- On the tape nothing is put away, as in niri: the window only leaves the view.
local function minimize(w)
    if tape() then
        local active = hl.get_active_window()
        if active and active.address == w.address then cycle(1) end
        return
    end
    -- The scene lets it fall into the bar as a drop: it is told where the window was, on its own monitor.
    local x, y = xy(w.at)
    local width, height = xy(w.size)
    local m = w.monitor
    hl.exec_cmd(string.format('latte-say "fact win.x %d" "fact win.y %d" "fact win.w %d" "fact win.h %d" "fact win.on %d" "emit win_min"',
                              x - (m and m.x or 0), y - (m and m.y or 0), width, height, m and m.id or 0))
    hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(w) }))
    if W.current == "glance" and W.glance_next then W.glance_next(w) end      -- the middle does not stay empty
end

-- ── a window born of a drop comes in a bubble; closed, it bursts (LATTEOS-GOO rule 14) ──────────────────────
-- The scene says a drop was pressed (`latte.win.expect`); the next window within a few seconds is kept clear
-- while the bubble flies from the drop to it and blows up to its size. Both ways the scene is told where the
-- window is, as for a window put away.
local expected, BLOWS = 0, 600             -- os.time() until which a window is expected; ms the bubble takes
local born_rule                            -- keeps the expected window clear from its first frame (W.setup)
local function tell_where(w, event)
    local x, y = xy(w.at)
    local width, height = xy(w.size)
    local m = w.monitor
    hl.exec_cmd(string.format('latte-say "fact win.x %d" "fact win.y %d" "fact win.w %d" "fact win.h %d" "fact win.on %d" "emit %s"',
                              x - (m and m.x or 0), y - (m and m.y or 0), width, height, m and m.id or 0, event))
end
-- Clear is no picture, no blur behind it, no shadow and no animation. The window's opacity multiplies the configured one (the
-- glass's): 1 gives that back; "unset" is refused.
-- ponytail: no_anim, no_blur and no_shadow go back to 0, not to what a window rule may have set; a rule for them needs keeping
local function clear(address, on)
    local function set(prop, value) hl.dispatch(hl.dsp.window.set_prop({ prop = prop, value = value, window = "address:" .. address })) end
    set("no_anim", on and "1" or "0")          -- first: else the window fades out, a ghost, and back in without fading
    set("opacity", on and "0" or "1")
    set("no_blur", on and "1" or "0")
    set("no_shadow", on and "1" or "0")
end
local hiding = false                       -- born_rule is on
local function hide(on) hiding = on if born_rule then born_rule:set_enabled(on) end end
local function expect()
    expected = os.time() + 5
    hide(true)
    -- no window came: the rule must not hide one that comes later
    hl.timer(function() if os.time() > expected then hide(false) end end, { timeout = 5500, type = "oneshot" })
end
hl.on("window.open", function(w)
    if not w then return end
    local was = hiding
    if was then hide(false) end
    if os.time() > expected then if was then clear(w.address, false) end return end   -- late: what the rule did is undone
    expected = 0
    local address = w.address
    clear(address, true)
    -- the glass plugin takes no_blur in only when it is set again once the window is up
    hl.timer(function() if find(address) then clear(address, true) end end, { timeout = 1, type = "oneshot" })
    -- where it ends up is known once the layout has placed it; its rules, applied meanwhile, gave back the blur
    hl.timer(function() local v = find(address) if v then clear(address, true) tell_where(v, "win_born") end end, { timeout = 60, type = "oneshot" })
    hl.timer(function() if find(address) then clear(address, false) end end, { timeout = BLOWS, type = "oneshot" })
end)
hl.on("window.close", function(w)
    if w and not put_away(w) and w.fullscreen ~= 2 then tell_where(w, "win_pop") end
end)

-- ── glance: the window one works in fills the middle; the others look out from the sides ──────────────────
-- After Scott Jenson's Glance (github.com/scottjenson/Glance, MIT), with what Hyprland has: a window cannot be
-- drawn smaller than it is, so one at the side keeps the size of the middle and shows the strip of it that the
-- screen has left there, its title on top; several on a side share the height, one title under another.
-- Clicking one brings it to the middle and sends the other to where it came from. Putting a window away is
-- parking it: it becomes a berry of the bar, as in the floating mode.
-- The middle is as wide as suits its height, never less than half the screen and never so wide that nothing
-- shows beside it: on a wide monitor the sides hold most of a window, on a small one only a strip to click.
local SIDE_LEAST = 96                -- px of a window that always shows at a side
local glance_side, glance_seen, glance_clock = {}, {}, 0      -- address → "l" | "r"; → when it was last in the middle
local function glance_room(m)
    local scale, res = m.scale or 1, m.reserved or { top = 0, right = 0, bottom = 0, left = 0 }
    local mw, mh = m.width / scale, m.height / scale
    if (m.transform or 0) % 2 == 1 then mw, mh = mh, mw end
    -- the title bar the compositor draws is above the window's own box (latte/bars.lua): room for it, for every
    -- window alike, so that their tops are in one line
    local title = (hl.plugin and hl.plugin.hyprbars) and 30 or 0
    local ax, ay = m.x + res.left + GAP, m.y + res.top + GAP + title
    local aw, ah = mw - res.left - res.right - 2 * GAP, mh - res.top - res.bottom - 2 * GAP - title
    local main = math.floor(math.max(aw * 0.5, math.min(ah * 1.45, aw - 2 * (SIDE_LEAST + GAP))))
    return ax, ay, aw, ah, main, math.floor(ax + (aw - main) / 2)
end
local function glance()
    if W.current ~= "glance" then return end
    local ws, active = hl.get_active_workspace(), hl.get_active_window()
    if not ws then return end
    local list = windows_on(ws.id)
    if #list == 0 then return end
    for _, w in ipairs(list) do if w.fullscreen == 2 then return end end      -- a window on the whole screen: leave all be
    if active and active.workspace and active.workspace.id == ws.id then
        glance_clock = glance_clock + 1
        glance_seen[active.address] = glance_clock
    end
    table.sort(list, function(a, b) return (glance_seen[a.address] or 0) > (glance_seen[b.address] or 0) end)
    local main = list[1]
    local m = main.monitor or hl.get_active_monitor()
    if not m then return end
    local ax, ay, aw, ah, width, mx = glance_room(m)
    local sides = { l = {}, r = {} }
    for i = 2, #list do
        local w = list[i]
        local side = glance_side[w.address] or (#sides.l <= #sides.r and "l" or "r")
        glance_side[w.address] = side
        sides[side][#sides[side] + 1] = w
    end
    glance_side[main.address] = nil
    for side, ws_ in pairs(sides) do
        local share = ah / math.max(#ws_, 1)
        for k, w in ipairs(ws_) do
            if w.fullscreen == 1 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", window = sel(w) })) end
            local down = math.floor((k - 1) * share)
            place(w, { x = side == "l" and (mx - GAP - width) or (mx + width + GAP), y = ay + down, w = width, h = ah - down })
            hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = sel(w) }))     -- a lower one covers the one above it
        end
    end
    if main.fullscreen ~= 1 then place(main, { x = mx, y = ay, w = width, h = ah }) end
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = sel(main) }))
end
-- the window that was in the middle last, other than `w`, comes there
function W.glance_next(w)
    local ws = hl.get_active_workspace()
    local list, best = ws and windows_on(ws.id) or {}, nil
    for _, o in ipairs(list) do
        if o.address ~= w.address and (not best or (glance_seen[o.address] or 0) > (glance_seen[best.address] or 0)) then best = o end
    end
    if best then hl.dispatch(hl.dsp.focus({ window = sel(best) })) end
    glance()
end
-- to a side on purpose
local function glance_aside(w, side)
    glance_side[w.address], glance_seen[w.address] = side, 0
    W.glance_next(w)
end
glance_dropped = function(w, x, y)
    local m = hl.get_monitor_at(x, y) or w.monitor
    if not m then return end
    local _, _, _, _, width, mx = glance_room(m)
    if x < mx then glance_aside(w, "l")
    elseif x > mx + width then glance_aside(w, "r")
    else hl.dispatch(hl.dsp.focus({ window = sel(w) })) glance() end
end
hl.on("window.active", function() glance() end)
hl.on("window.open", function() if W.current == "glance" then hl.timer(function() glance() end, { timeout = 120, type = "oneshot" }) end end)
hl.on("window.close", function(w)
    if w then glance_side[w.address], glance_seen[w.address] = nil, nil end
    if W.current == "glance" then hl.timer(function() glance() end, { timeout = 120, type = "oneshot" }) end
end)

-- the scene learns the mode by its place in `order`, from 0
local function tell()
    for i, m in ipairs(W.order) do
        if m == W.current then hl.exec_cmd('latte-say "emit window_mode ' .. (i - 1) .. '"') end
    end
end

-- Switches the mode and fits the windows that are there to it.
function W.apply(mode)
    W.current = mode
    local floating = mode == "floating" or mode == "glance"
    hl.config({ general = { layout = mode == "tape" and "scrolling" or "dwindle" } })
    if float_rule then float_rule:set_enabled(floating) end
    local ws = hl.get_active_workspace()
    for _, w in ipairs(hl.get_windows() or {}) do
        -- on the tape nothing is hidden: what was put away comes back
        if mode == "tape" and ws and put_away(w) then hl.dispatch(hl.dsp.window.move({ workspace = tostring(ws.id), follow = false, window = sel(w) })) end
        if w.floating ~= floating then hl.dispatch(hl.dsp.window.float({ action = floating and "enable" or "disable", window = sel(w) })) end
    end
    if mode == "tape" then hide_special() end
    save_mode(mode)
    tell()
    glance()
end

function W.setup()
    hl.config({
        scrolling = { column_width = 0.5, fullscreen_on_one_column = true, follow_focus = true, focus_fit_method = 1 },
        dwindle = { preserve_split = true },
    })
    float_rule = hl.window_rule({ name = "latte-floating", match = { class = ".*" }, float = true })
    born_rule = hl.window_rule({ name = "latte-born", match = { class = ".*" }, no_anim = true, opacity = "0", no_blur = true, no_shadow = true })
    born_rule:set_enabled(false)
    -- read anew, the configuration has forgotten which windows were pulsing: none keeps a lit border
    for _, w in ipairs(hl.get_windows() or {}) do border(w.address) end
    local plugin = io.open(W.plugin, "r")
    if plugin then
        plugin:close()
        -- its event is there only once the plugin has really been loaded
        if pcall(hl.plugin.load, W.plugin) then
            for _, p in ipairs(hl.get_loaded_plugins() or {}) do
                if p.name == "latte-events" then hl.on("latte.drag_end", dropped) end
            end
        end
    end

    latte.mode = {
        tell = tell,
        set = function(mode) if valid(mode) then W.apply(mode) end end,
        next = function()
            local at = 1
            for i, m in ipairs(W.order) do if m == W.current then at = i end end
            W.apply(W.order[at % #W.order + 1])
        end,
    }

    local function with(f) return function(address, ...) local w = find(address) if w then return f(w, ...) end end end
    latte.win = {
        cut = function(address, on) cut[address] = on or nil border(address) end,
        -- the screens changed (Settings › Displays): no floating window is left where it cannot be reached
        gather = function()
            for _, w in ipairs(hl.get_windows() or {}) do
                if w.floating and w.monitor then within_reach(w, w.monitor, true) end
            end
        end,
        activate = with(activate),
        minimize = with(minimize),
        expect = expect,
        -- a press on a window in the bar, as on Windows: one that is not in front comes forward, the one in front is put away
        toggle = with(function(w)
            local active = hl.get_active_window()
            if active and active.address == w.address and not put_away(w) then
                if tape() then hl.dispatch(hl.dsp.layout("center")) else minimize(w) end
            else
                activate(w)
            end
        end),
        close = with(function(w) hl.dispatch(hl.dsp.window.close({ window = sel(w) })) end),
        maximize = with(function(w)
            hl.dispatch(hl.dsp.focus({ window = sel(w) }))
            hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = sel(w) }))
        end),
        -- back to the size it had before it was maximised or laid in a zone
        restore = with(function(w)
            if w.fullscreen ~= 0 then hl.dispatch(hl.dsp.window.fullscreen({ mode = w.fullscreen == 1 and "maximized" or "fullscreen", action = "unset", window = sel(w) }))
            else unsnap(w) end
        end),
        pin = with(function(w)
            if not w.floating then hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel(w) })) end
            hl.dispatch(hl.dsp.window.pin({ window = sel(w) }))
        end),
        snap = with(snap),
        sounding = set_sounding,
        to_desk = with(function(w, n) hl.dispatch(hl.dsp.window.move({ workspace = n == 0 and "empty" or tostring(n), follow = false, window = sel(w) })) end),
        -- to another screen (its name), onto the desktop shown there; a floating window stays within reach
        to_screen = with(function(w, name)
            hl.dispatch(hl.dsp.window.move({ monitor = name, window = sel(w) }))
            local moved = find(w.address)
            for _, m in ipairs(hl.get_monitors() or {}) do
                if m.name == name and moved and moved.floating then within_reach(moved, m, true) end
            end
        end),
        -- for the buttons of a title bar: the window that was pressed has the keyboard by then
        minimize_active = function() local w = hl.get_active_window() if w then minimize(w) end end,
        maximize_active = function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) end,
        cycle = cycle,
        -- the tape slides by a quarter of the screen
        scroll = function(dir)
            if not tape() then return end
            local m = hl.get_active_monitor()
            hl.dispatch(hl.dsp.layout(string.format("move %s%d", dir > 0 and "-" or "+", math.floor(((m and m.width) or 1920) * 0.25))))
        end,
        minimize_all = function(keep_active)
            if tape() then return end
            local ws, active = hl.get_active_workspace(), hl.get_active_window()
            for _, w in ipairs(ws and windows_on(ws.id) or {}) do
                if not (keep_active and active and w.address == active.address) then minimize(w) end
            end
        end,
        restore_all = function()
            local ws = hl.get_active_workspace()
            for _, w in ipairs(hl.get_windows() or {}) do
                if ws and put_away(w) then hl.dispatch(hl.dsp.window.move({ workspace = tostring(ws.id), follow = false, window = sel(w) })) end
            end
            hide_special()
        end,
        -- the arrow keys with the Windows key: in floating mode as on Windows, otherwise they move the focus
        arrow = function(dir)
            local w = hl.get_active_window()
            if W.current == "glance" and w then
                -- left and right: to that side; down: parked in the bar; up: the whole screen and back
                if dir == "left" or dir == "right" then return glance_aside(w, dir == "left" and "l" or "r") end
                if dir == "down" then return minimize(w) end
                hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
                return glance()
            end
            if W.current ~= "floating" or not w then return hl.dispatch(hl.dsp.focus({ direction = dir })) end
            if dir == "up" then
                if w.fullscreen ~= 1 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) end
            elseif dir == "down" then
                if w.fullscreen == 1 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
                elseif not unsnap(w) then minimize(w) end
            else
                snap(w, dir)
            end
        end,
        -- the n-th window of the desktop, left to right; the one in front is put away, as on a taskbar
        nth = function(n)
            local ws = hl.get_active_workspace()
            local list = ws and windows_on(ws.id) or {}
            table.sort(list, function(a, b) return (xy(a.at)) < (xy(b.at)) end)
            local w, active = list[n], hl.get_active_window()
            if not w then return end
            if active and active.address == w.address then minimize(w) else hl.dispatch(hl.dsp.focus({ window = sel(w) })) end
        end,
    }

    -- ── desktops (workspaces), in a row as on Windows ───────────────────────────────────────────────────────
    local shown_from = nil
    local function empty(ws) return #windows_on(ws.id) == 0 end
    latte.desk = {
        -- Shows the desktop: an empty workspace, and the same again goes back. Only back from the empty one
        -- this got to: whoever went elsewhere meanwhile is shown the desktop again.
        show = function()
            local ws = hl.get_active_workspace()
            if shown_from and ws and ws.id ~= shown_from and empty(ws) then
                hl.dispatch(hl.dsp.focus({ workspace = shown_from }))
                shown_from = nil
            else
                shown_from = ws and ws.id or nil
                hl.dispatch(hl.dsp.focus({ workspace = "empty" }))
            end
        end,
        new = function() hl.dispatch(hl.dsp.focus({ workspace = "empty" })) end,
        step = function(d)
            local ws = hl.get_active_workspace()
            local to = (ws and ws.id or 1) + d
            if to >= 1 then hl.dispatch(hl.dsp.focus({ workspace = to })) end
        end,
        close = function()
            local ws = hl.get_active_workspace()
            local id = ws and ws.id or 1
            local to = id > 1 and id - 1 or id + 1
            for _, w in ipairs(windows_on(id)) do hl.dispatch(hl.dsp.window.move({ workspace = tostring(to), follow = false, window = sel(w) })) end
            hl.dispatch(hl.dsp.focus({ workspace = to }))
        end,
    }

    W.apply(load_mode())
end

return W
