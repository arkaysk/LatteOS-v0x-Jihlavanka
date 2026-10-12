-- How windows are arranged, and what the bar asks of them.
--
-- Three modes, as the head of the window bar shows them:
--   tape      an endless horizontal strip (Hyprland's scrolling layout); nothing is ever put away
--   tiles     tiles (dwindle)
--   floating  every window floats, as on Windows
-- The choice is kept in ~/.local/state/latteos/window-mode and told to the Goo scene (its event `window_mode`).
--
-- A window put away sits on the hidden workspace special:minimized. The scene knows windows by the address
-- `hyprctl clients` gives them and calls the functions in `latte.win` with it (goo/lib/wm.luau).
local W = {}

W.order = { "tape", "tiles", "floating" }
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
local function snap(w, zone)
    local z, m = zones[zone], w.monitor or hl.get_active_monitor()
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
hl.on("window.close", function(w) if w then before[w.address] = nil end end)

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
    hl.exec_cmd(string.format('pleamar --say goo "fact win.x %d" "fact win.y %d" "fact win.w %d" "fact win.h %d" "fact win.on %d" "emit win_min"',
                              x - (m and m.x or 0), y - (m and m.y or 0), width, height, m and m.id or 0))
    hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(w) }))
end

-- the scene learns the mode by its place in `order`, from 0
local function tell()
    for i, m in ipairs(W.order) do
        if m == W.current then hl.exec_cmd('pleamar --say goo "emit window_mode ' .. (i - 1) .. '"') end
    end
end

-- Switches the mode and fits the windows that are there to it.
function W.apply(mode)
    W.current = mode
    local floating = mode == "floating"
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
end

function W.setup()
    hl.config({
        scrolling = { column_width = 0.5, fullscreen_on_one_column = true, follow_focus = true, focus_fit_method = 1 },
        dwindle = { preserve_split = true },
    })
    float_rule = hl.window_rule({ name = "latte-floating", match = { class = ".*" }, float = true })

    latte.mode = {
        tell = tell,
        next = function()
            local at = 1
            for i, m in ipairs(W.order) do if m == W.current then at = i end end
            W.apply(W.order[at % #W.order + 1])
        end,
    }

    local function with(f) return function(address, ...) local w = find(address) if w then return f(w, ...) end end end
    latte.win = {
        activate = with(activate),
        minimize = with(minimize),
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
        to_desk = with(function(w, n) hl.dispatch(hl.dsp.window.move({ workspace = n == 0 and "empty" or tostring(n), follow = false, window = sel(w) })) end),
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
