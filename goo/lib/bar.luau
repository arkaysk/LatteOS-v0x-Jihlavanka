-- The window bar. Its head (drops/bargoo.luau) shows how windows are arranged; beside it every window is a
-- berry with its app's icon. Windows of one app hang together as a bunch of grapes, the first at the edge
-- and the rest above it, the same way every time; the more of them, the smaller. The pointer over a bunch
-- spreads it out into a row. The window in front is fuller, one put away smaller and dimmed.
--
-- The berries are out only where windows float. On the tape and in tiles every window is in sight already:
-- the head then says how many there are. A window that plays a sound or wants attention shows it on its own
-- border (the compositor does that; which windows sound it is told from here), and the head waves only for one
-- that is out of sight, on another desktop. The
-- pointer resting on the head brings the berries out for as long as it stays with them, which is also the way
-- to a window on another desktop. Whether they are out is `berries_out()`'s to say and nobody else's: nothing
-- here may take a berry for granted.
--
-- A bunch only piles up where nothing is above it: under a window it lies down in a row along the edge.
-- A press on a berry is a press on a taskbar: the window comes forward, the one in front is put away.
local E = require("lib/engine")
local wm = require("lib/wm")
local card = require("lib/card")
local ctx = require("lib/ctx")
local M = {}
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local HEAD = "bargoo"
local ROOM = fact.slots - 8          -- berries at most: the other drops need places too
local R, R_LOW = 22, 17              -- a berry's radius; smaller in a row under a window
-- where each berry of a bunch sits, in radii from the first (x along the edge, y away from it is negative),
-- and how far each is nudged so that no bunch looks ruled
local BUNCH = { { 0, 0 }, { 1.72, -0.42 }, { 0.78, -1.62 }, { -0.98, -1.3 }, { 2.28, -1.86 },
                { 0.02, -3.0 }, { 1.62, -3.12 }, { -1.25, -2.85 }, { 2.9, -3.0 }, { 0.85, -4.2 },
                { -0.6, -4.3 }, { 2.2, -4.3 }, { 3.4, -1.1 }, { 0.1, -5.4 }, { 1.55, -5.5 },
                { -1.3, -5.2 }, { 3.1, -4.4 }, { -1.9, -1.9 }, { 0.8, -6.6 }, { 2.4, -6.4 } }
local NUDGE = { { 0, 0 }, { 0.06, -0.04 }, { -0.05, 0.07 }, { 0.08, 0.03 }, { -0.07, -0.05 },
                { 0.05, 0.06 }, { -0.04, 0.05 }, { 0.07, -0.06 }, { -0.06, 0.04 }, { 0.04, -0.07 },
                { 0.03, 0.05 }, { -0.05, -0.03 }, { 0.06, 0.02 }, { -0.03, -0.06 }, { 0.05, 0.04 },
                { -0.06, 0.03 }, { 0.02, -0.05 }, { 0.04, 0.06 }, { -0.04, -0.04 }, { 0.06, -0.02 } }
local ZIGZAG = { 0, 0.46, 0.12, 0.52, 0.04, 0.38, 0.18, 0.5 }      -- a row under a window is not straight either
-- how windows are arranged, as the compositor counts the modes
local MODES = { [0] = { glyph = "layout-columns", name = N("Tape") }, { glyph = "layout-grid", name = N("Tiles") },
                { glyph = "app-window", name = N("Floating windows") }, { glyph = "layout-distribute-vertical", name = N("Glance") } }

local wins = {}                      -- the windows of this monitor, as the compositor lists them
local every_win = {}                 -- …and those of every monitor
local shown = {}                     -- id of a berry → its window
local order = {}                     -- the apps in the order the user dragged them into
local middles = {}                   -- { key, x }: where each bunch's middle is, px from the head
local hot, hot_n = nil, 0            -- the bunch under the pointer
local mode = 0
local blocks, low = {}, {}           -- windows above the bar as stretches along it; which bunches lie low
local peeking = false                -- the pointer has rested on the head: the berries are out for now
local urgent = {}                    -- address → true: the windows that want attention
local audio = {}                     -- what is playing, as the service tells it

-- The one place that says how the windows are shown beside the head.
local function berries_out() return mode >= 2 or peeking end      -- floating and glance: a window put away is a berry
M.berries_out = berries_out

-- ── a window's app ───────────────────────────────────────────────────────────────────────────────────────────
-- The launcher's entry gives a window its icon and says which windows belong together: by the class its
-- windows declare, by its id or the id's last part (a Flatpak's windows say "firefox", its id is
-- org.mozilla.firefox), else by name.
local apps = { class = {}, id = {}, tail = {}, name = {} }
local function index(list)
    apps = { class = {}, id = {}, tail = {}, name = {} }
    for _, a in ipairs(list or {}) do
        if a.wmclass and a.wmclass ~= "" then apps.class[a.wmclass:lower()] = a end
        if a.id then
            local id = a.id:lower()
            local tail = id:match("([^%.]+)$") or id
            apps.id[id] = a
            apps.tail[tail] = apps.tail[tail] or a
        end
        if a.name then apps.name[a.name:lower()] = apps.name[a.name:lower()] or a end
    end
end
function M.app_of(w)
    local c = (w.class or ""):lower()
    return apps.class[c] or apps.id[c] or apps.tail[c] or apps.name[c]
end
local function key_of(w)
    local a = M.app_of(w)
    return a and ("app:" .. (a.id or a.name)) or (w.class ~= "" and w.class or "?")
end
local function app_name(w)
    local a = M.app_of(w)
    return a and (a.local_name or a.name) or w.class
end
function M.windows() return every_win end

-- ── where the berries go ─────────────────────────────────────────────────────────────────────────────────────
local function free_above(x0, x1)
    local gap = 999
    for _, b in ipairs(blocks) do
        if b.a1 > x0 and b.a0 < x1 then gap = math.min(gap, b.gap) end
    end
    return gap
end

-- `net`: "on" or "off" when the app can be cut off the internet (bin/latte-net), nil when nothing here does that
local function menu(w, net)
    local function act(what, arg) return function() wm.win(what, w.address, arg) after(150, M.refresh) end end
    local function zone(id, label, glyph) return { label = tr(label), glyph = glyph, run = act("snap", id) } end
    local desks = {}
    for n = 1, 4 do desks[n] = { label = tr("Desktop") .. " " .. n, on = w.desk == n, run = act("to_desk", n) } end
    desks[#desks + 1] = { label = tr("New desktop"), glyph = "plus", run = act("to_desk", 0) }
    local rows = {
        { label = tr("Restore"), glyph = "arrows-minimize", run = act(w.away and "activate" or "restore") },
        { label = tr("Minimize"), glyph = "minus", off = w.away or mode == 0, run = act("minimize") },
        { label = tr("Maximize"), glyph = "arrows-maximize", off = w.maximized, run = act("maximize") },
        { label = tr("Layout"), glyph = "layout-grid", sub = {
            zone("left", N("Left half"), "layout-sidebar"), zone("right", N("Right half"), "layout-sidebar-right"),
            zone("tl", N("Top left"), "layout-grid"), zone("tr", N("Top right"), "layout-grid"),
            zone("bl", N("Bottom left"), "layout-grid"), zone("br", N("Bottom right"), "layout-grid"),
            zone("center", N("Center"), "focus-centered") } },
        { label = tr("Always on top (all desktops)"), glyph = "pin", on = w.pinned, run = act("pin") },
        { label = tr("Move to desktop"), glyph = "stack-2", sub = desks },
        { label = tr("Close"), glyph = "x", hint = "Alt+F4", danger = true, line = true, run = act("close") },
    }
    if net then
        table.insert(rows, #rows, { label = tr("Cut off the internet"), glyph = "world-off", on = net == "off", line = true,
                                    run = function() run("latte-net", { "toggle", w.address }, function() end) end })
    end
    ctx.open(rows, { width = 280 })
end
-- the menu, once it is known whether the app has the internet
local function ask_menu(w)
    run("latte-net", { "status", w.address }, function(out)
        local net = (out or ""):match("^(o[nf]f?)%s*$")
        menu(w, net)
    end)
end

-- the windows that did not fit, as a list
local function rest(from)
    local rows = { { head = true, label = tr("MORE WINDOWS") } }
    for i = from, #wins do
        local w = wins[i]
        local a = M.app_of(w)
        rows[#rows + 1] = { label = w.title ~= "" and w.title or app_name(w), icon = a and a.icon or "", glyph = "app-window",
                            hint = w.away and tr("put away") or "", run = function() wm.win("activate", w.address) after(150, M.refresh) end }
    end
    card.open(rows, { width = 340 })
end

local function layout()
    local head = E.get(HEAD)
    if not head then return end
    local out = berries_out()
    local count = (not out and #wins > 0) and tostring(#wins) or ""
    head:set({ label = count, still = count ~= "" })         -- with a number on it the head does not sink: it has to stay whole
    local groups, first = {}, {}
    local over = #wins > ROOM
    for i, w in ipairs(wins) do
        if not out or i > ROOM then break end
        local key = (over and i == ROOM) and "~more" or key_of(w)
        if not groups[key] then groups[key] = {} first[#first + 1] = key end
        table.insert(groups[key], i)
    end
    local keys, used = {}, {}
    for _, key in ipairs(order) do if groups[key] and not used[key] then keys[#keys + 1] = key used[key] = true end end
    for _, key in ipairs(first) do if not used[key] then keys[#keys + 1] = key used[key] = true end end

    local r0 = mode == 0 and 24 or R
    local place, u = {}, E.radius(head) + 8          -- u: where the next bunch starts, px from the head's centre
    for _, key in ipairs(keys) do
        local idx = groups[key]
        local n = #idx
        local r = r0 * math.max(0.72, 1 - 0.07 * (n - 1))
        local lo, hi, top = 0, 0, 0
        for j = 1, math.min(n, #BUNCH) do
            local x = BUNCH[j][1] + NUDGE[j][1]
            lo, hi, top = math.min(lo, x), math.max(hi, x), math.max(top, -(BUNCH[j][2] + NUDGE[j][2]))
        end
        -- A bunch needs its own height free above it, and a little more once it has lain down, so that it
        -- does not flicker between the two.
        local need = top * r + r + 56 + (low[key] and 16 or 0)
        local tight = free_above(u, u + (hi - lo) * r + 2 * r) < need
        low[key] = tight
        local row = tight or n == 1 or key == hot or n > #BUNCH
        if key == hot and not tight then r = r0 end
        if tight then r = math.min(r, R_LOW) end
        if row and tight and n > 1 then
            local step = r * 1.45
            for j, i in ipairs(idx) do
                place[i] = { x = u + r + (j - 1) * step, y = -ZIGZAG[(j - 1) % #ZIGZAG + 1] * r, r = r * (1 + 0.05 * ((j - 1) * 37 % 5 - 2) / 2), tight = true }
            end
            u += 2 * r + (n - 1) * step + 12
        elseif row then
            local step = r * 1.86
            for j, i in ipairs(idx) do place[i] = { x = u + r + (j - 1) * step, y = 0, r = r, tight = tight } end
            u += 2 * r + (n - 1) * step + 12
        else
            local x0 = u + r - lo * r
            for j, i in ipairs(idx) do
                place[i] = { x = x0 + (BUNCH[j][1] + NUDGE[j][1]) * r, y = (BUNCH[j][2] + NUDGE[j][2]) * r, r = r * (1 + 0.06 * ((j - 1) * 37 % 5 - 2) / 2) }
            end
            u = x0 + hi * r + r + 12
        end
    end
    -- The string has to end before the edge does: all of it shrinks by the same share.
    local room = E.limit(head) - E.along(head) - 20
    if u > room and u > 0 then
        local f = math.max(room / u, 0.25)
        for _, p in pairs(place) do p.x, p.y, p.r = p.x * f, p.y * math.max(f, 0.5), p.r * math.max(f, 0.5) end
    end

    local now = {}
    for i, w in ipairs(wins) do
        local p = place[i]
        if p then
            local more = over and i == ROOM
            local id = more and "w:more" or ("w:" .. w.address)
            local a = M.app_of(w)
            now[id] = w
            local d = E.upsert({
                id = id, name = more and tr("More windows") or (w.title ~= "" and w.title or app_name(w)), about = more and "" or app_name(w),
                icon = (not more and a and a.icon) or "", glyph = more and "dots" or "app-window",
                size = p.r * (w.away and not more and 0.84 or 1) * (w.front and not more and 1.06 or 1),
                beside = HEAD, gap = p.x, seat = p.r * 0.8 - p.y, nature = "calm", pull = 0.15, lift = p.tight and 0.15 or 0.55, sticky = 0.35,
                swell = 0.1, reach = 160, team = 1, melt = 0.35, puddle = 0.15,
                click = function() if more then rest(i) else wm.win("toggle", w.address) after(150, M.refresh) end end,
                right = function() if not more then ask_menu(w) end end,
                enter = function() M.enter(key_of(w)) end,
                leave = function() M.leave() end,
                -- let go after a drag: its app moves in front of the bunch it was let go over; the berry stays in the bar
                letgo = function(_, x, y) local h = E.get(HEAD) M.reorder(key_of(w), h and h.edge % 2 == 1 and y or x) return false end,
            })
            if d then d:fade(w.away and not more and 1 or 0) end
        end
    end
    for id in pairs(shown) do if not now[id] then E.remove(id) end end
    shown = now
    middles = {}
    for _, key in ipairs(keys) do
        local sum, n = 0, 0
        for _, i in ipairs(groups[key]) do sum, n = sum + (place[i] and place[i].x or 0), n + 1 end
        middles[#middles + 1] = { key = key, x = n > 0 and sum / n or 0 }
    end
end

function M.enter(key)
    hot_n += 1
    if key ~= hot then hot = key layout() end
end
function M.leave()
    hot_n += 1
    local mine = hot_n
    after(500, function() if mine == hot_n and hot then hot = nil layout() end end)
    -- brought out by the pointer, they go back in once it has left them and the head alone
    after(900, function() if mine == hot_n and peeking then peeking = false layout() end end)
end
-- the pointer on the head, or off it: resting there brings the berries out
function M.rest(on)
    if not on then return M.leave() end
    hot_n += 1
    local mine = hot_n
    after(450, function() if mine == hot_n and not berries_out() then peeking = true layout() end end)
end

-- A wave from the head, for a window that cannot say it itself because it is out of sight. Only while the
-- berries are in; out, the berry is there to be seen.
local function wave(force)
    local head = E.get(HEAD)
    if not head or berries_out() then return end
    head:squash()
    head:ripple(force)
end
-- The windows that play a sound. What plays says its program's name (or only its own, or its icon's); a
-- window says its class: the two are matched by one containing the other.
local function sounding(list)
    local out = {}
    for _, s in ipairs(type(audio.apps) == "table" and audio.apps or {}) do
        if s.playing and not s.muted then
            for _, w in ipairs(list) do
                local c = w.class:lower()
                for _, said in ipairs({ s.binary or "", s.name or "", s.icon or "" }) do
                    local b = said:lower()
                    if c ~= "" and b ~= "" and (c:find(b, 1, true) or b:find(c, 1, true)) then out[#out + 1] = w break end
                end
            end
        end
    end
    return out
end
-- The compositor is told which windows sound, by the main scene alone: it is one list for all monitors.
local told_sound = nil
local function tell_sound()
    if E.side then return end
    local addresses = {}
    for _, w in ipairs(sounding(every_win)) do addresses[#addresses + 1] = w.address end
    table.sort(addresses)
    local s = table.concat(addresses, " ")
    if s ~= told_sound then told_sound = s wm.sounding(addresses) end
end
local function hidden(list)
    for _, w in ipairs(list) do if not w.visible then return true end end
    return false
end
on("win_urgent", function()
    local address = text.win_wants or ""
    for _, w in ipairs(wins) do
        if w.address == address and not w.front then
            urgent[address] = true
            if not w.visible then wave(6) end
        end
    end
end)
-- x: where along the bar's edge the berry was let go, px
function M.reorder(key, x)
    local head = E.get(HEAD)
    if not head then return end
    local at_x = x - E.along(head)
    local others = {}
    for _, m in ipairs(middles) do if m.key ~= key then others[#others + 1] = m end end
    local at = #others + 1
    for i, m in ipairs(others) do if at_x < m.x then at = i break end end
    order = {}
    for i, m in ipairs(others) do
        if i == at then order[#order + 1] = key end
        order[#order + 1] = m.key
    end
    if at > #others then order[#order + 1] = key end
    after(30, layout)
end

-- ── the head ─────────────────────────────────────────────────────────────────────────────────────────────────
local function show_mode()
    local head, m = E.get(HEAD), MODES[mode]
    if head and m then head:glyph(m.glyph) head:name(tr(m.name)) end
end
on("window_mode", function(n)
    -- The compositor says this each time it has read its configuration, and that puts the band back at the bottom.
    local head = E.get(HEAD)
    if head and head.edge ~= 0 then M.band() end
    told_sound = nil                         -- …and makes the compositor forget which windows sound
    if not MODES[n] or n == mode then return end
    mode, peeking = n, false
    show_mode()
    layout()
end)
-- windows leave the bar's edge free
function M.band()
    local head = E.get(HEAD)
    if head then wm.band(head.edge) end
end
function M.mode() return mode end
function M.next_mode() wm.next_mode() end
function M.show_desktop() wm.show_desktop() end
-- the wheel on the head: the tape slides; floating, the next window comes forward; tiles stay as they are
function M.wheel(dir)
    if mode == 0 then wm.scroll(dir) elseif mode >= 2 then wm.cycle(dir) after(150, M.refresh) end
end

-- The right button on a window's own title bar: its menu, where the pointer is (the compositor has said where).
on("win_menu", function()
    local address = text.win_asked or ""
    for _, w in ipairs(wins) do
        if w.address == address then
            local x, y = wm.origin()         -- the pointer was told as the compositor counts, across all monitors
            fact["tap.x"], fact["tap.y"] = fact["tap.x"] - x, fact["tap.y"] - y
            return ask_menu(w)
        end
    end
end)

-- A window was put away (the compositor says where it was): it falls as a drop into the bar, beside the head,
-- or straight down when the bar is on another edge, and the surface ripples where it lands.
on("win_min", function()
    local x, y, w, h = fact["win.x"], fact["win.y"], fact["win.w"], fact["win.h"]
    local sw, sh = tonumber(fact.sw) or 0, tonumber(fact.sh) or 0
    if wm.monitor() and fact["win.on"] ~= wm.monitor() then return end                           -- on another monitor
    if w <= 0 or h <= 0 or sw <= 0 or x >= sw or y >= sh then return end
    local head = E.get(HEAD)
    local cx, cy = x + w / 2, y + h / 2
    local to = (head and head.edge == 0) and math.min(E.along(head) + (berries_out() and 90 or 0), E.limit(head)) or cx
    local takes = math.sqrt(2 * math.max(40, sh - 6 - cy) / 800)            -- the scene's gravity, px/s²
    fact["gone.x0"], fact["gone.y0"], fact["gone.x1"], fact["gone.w"], fact["gone.h"], fact["gone.for"] = cx, cy, to, w, h, takes
    fact.gone_n += 1
    after((takes + 0.2) * 1000, function() E.ripple(to / sw, 7, "stone") end)
    after(250, M.refresh)                    -- its berry dims at once
end)

-- ── keeping up with the windows ──────────────────────────────────────────────────────────────────────────────
local asked, signature = false, ""
function M.refresh()
    if asked then return end
    asked = true
    wm.windows(function(all)
        asked = false
        if not all then return end
        local list = {}                      -- every monitor has a bar of its own
        for _, w in ipairs(all) do if w.here then list[#list + 1] = w end end
        every_win = all
        local head = E.get(HEAD)
        local at, h = head and E.along(head) or 0, tonumber(fact.sh) or 0
        local sig, above = {}, {}
        for _, w in ipairs(list) do
            sig[#sig + 1] = table.concat({ w.address, w.title, w.class, tostring(w.front), tostring(w.away), tostring(w.maximized), tostring(w.pinned), w.desk }, "\1")
            -- windows right above a bar on the bottom edge: the stretch each covers, and how much room it leaves
            if w.visible and w.here then sig[#sig + 1] = w.x .. ":" .. w.y .. ":" .. w.w .. ":" .. w.h end
            if head and head.edge == 0 and w.visible and w.here and h > 0 and h - (w.y + w.h) < 400 then
                above[#above + 1] = { a0 = w.x - at, a1 = w.x + w.w - at, gap = math.max(0, h - (w.y + w.h)) }
            end
        end
        local s = table.concat(sig, "\2")
        if s == signature then return end
        signature, wins, blocks = s, list, above
        -- a window that wanted attention has it once it is in front, or is gone
        local there = {}
        for _, w in ipairs(list) do if urgent[w.address] and not w.front then there[w.address] = true end end
        urgent = there
        layout()
        -- the drops on the other edges step out of the way of the windows in sight
        local seen = {}
        for _, w in ipairs(list) do if w.visible and w.here and not w.fullscreen then seen[#seen + 1] = w end end
        E.avoid(seen)
    end)
end

function M.start()
    -- a film or a game over the whole screen: no weather on the surface meanwhile
    E.busy = function(answer)
        for _, w in ipairs(wins) do if w.fullscreen and w.visible and w.here then return answer(true) end end
        answer(false)
    end
    sys.watch("apps", function(list) index(list) signature = "" M.refresh() end)
    -- The service tells that something about the windows changed; what, the compositor is asked.
    local soon
    pcall(sys.watch, "window", function()
        if soon then cancel(soon) end
        soon = after(60, function() soon = nil M.refresh() end)
    end)
    every(2000, M.refresh)           -- a window moved or resized changes nothing the service reports
    pcall(sys.watch, "audio", function(v) audio = type(v) == "table" and v or {} tell_sound() end)
    every(3500, function()
        tell_sound()
        local asking = {}
        for _, w in ipairs(wins) do if urgent[w.address] then asking[#asking + 1] = w end end
        if hidden(asking) then wave(5) elseif hidden(sounding(wins)) then wave(2.5) end
    end)
    on("fact:sw", function() signature = "" M.refresh() end)
    wm.tell_mode()
    M.band()
    M.refresh()
end

return M
