-- The Goo engine: the register of drops. One set of rules for all of them (the scene: parts/drops.plm); a
-- drop is a definition, a table of numbers and of what it does when something happens to it. The scene moves
-- the drops and hears the mouse, this decides what follows, and lays the drops out along the edges: where
-- each one's home is, who its neighbours are, who gives way when two would overlap.
--
-- A definition (drops/NAME.luau returns one; everything but `id` may be left out):
--   id, name, glyph (an icon of the icon font, by name), label, about (the tooltip: a text or function(d))
--   nature     "calm" | "curious" | "sticky" | "heavy" | "playful": a bundle of the numbers below
--   size       its radius, px                   seat    how high its centre sits above the edge (0.8 × size)
--   home       { edge = 0…3, at = 0…1 }: bottom, left, top, right, and where along it
--   beside, gap    next to the drop of that id, this many px along the edge (it follows it around)
--   pull 0…1, reach px (the pointer's attraction)  lift 0…2 (how high it rises to the pointer)
--   sticky 0…1, tear px (how it holds on to home when dragged)   glint, swell   draggable   zoomable
--   core       it belongs to the desktop itself: it cannot be hidden
--   returns    let go in mid-air it goes back where it was instead of falling
--   team       0 on its own, 1 a berry of the window bar, 2 the bar's head: berries melt only with their bar
--   kind       "icon" | "ring" (filled to `value`) | "clock" (`label` large, `line2` under it)
--   fx, fx_k   "breath" | "wobble" | "shiver" | "beat" and its strength
--   melt, puddle, cap, cap_dir, line2, still, crown: see the record in parts/drops.plm
-- What it does (each gets the drop `d`):
--   start · click · right · middle · hold · wheel(d, ±1) · enter · leave · grab
--   letgo(d, x, y, edge) → false: stay where it was · placed: a drag has ended and it is home, old or new
--   idle(d, stage 0…3) · tick, every `every` ms
-- A press it has nothing for makes the drop shiver: a button does something or says that it does not.
local icons = require("lib/icons")
local card = require("lib/card")
local E = {}

local N = fact.slots
local FX = { none = 0, breath = 1, wobble = 2, shiver = 3, beat = 4 }
local KINDS = { icon = 0, ring = 1, clock = 2 }
local HUES = { hardware = 0, network = 1, software = 2, warning = 3, light = 4, other = 5 }      -- a core
local BEADS = { hardware = 0, network = 1, software = 2, yellow = 3, system = 4, light = 5 }
E.NATURES = {
    calm    = { pull = 0.12, sticky = 0.2, fx = "breath", fx_k = 0.6 },
    curious = { pull = 0.6, reach = 280, fx = "breath", swell = 0.12 },
    sticky  = { pull = 0.25, sticky = 0.9, tear = 120, fx = "wobble", fx_k = 0.4 },
    heavy   = { pull = 0.05, sticky = 0.35, size = 30, lift = 0.5 },
    playful = { pull = 0.4, reach = 240, fx = "wobble", fx_k = 0.8 },
}
local DEFAULTS = { size = 26, pull = 0.3, reach = 220, lift = 1, sticky = 0, tear = 90, glint = 0.5, swell = 0.08,
                   draggable = true, fx = "none", fx_k = 1, kind = "icon", zoomable = true, team = 0, melt = 1, puddle = 1 }
local ZOOM_MIN, ZOOM_MAX = 0.5, 2.2
local THREAD = 2.3           -- neighbours join while their centres are within this many sums of their radii
local MIN_GAP = 0.95         -- centres stay this many sums of radii apart: drops touch and melt, never cover
local BERRY_GAP = 1.2        -- a stranger keeps further from a bar's berries, so as not to melt with them
local STICK = 130            -- let go within this many px of an edge, a drop sticks to it
local GRAVITY = 800          -- px/s², the scene's: how long a fall takes
local PLACES = "places.json"

local slots, by_id = {}, {}  -- place (0…N−1) → drop; id → drop
local places = {}            -- id → { at, rise, zoom, edge }: where the user left each drop
local Drop = {}
Drop.__index = Drop

local function num(v, d) return type(v) == "number" and v or d end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function glyph(name) return name and (icons[name] or (name:byte(1) or 0) >= 128 and name) or "" end
local function env(name) local ok, v = pcall(sys.ask, "env", name) return ok and type(v) == "string" and v or "" end
E.env = env

-- ── where a drop is ──────────────────────────────────────────────────────────────────────────────────────────
-- A home is an edge, a share of its length and a height above it; the scene turns that into pixels. Laying
-- drops out against each other needs lengths, so the scene says how big the screen is.
local function side(d) return d.edge % 2 == 1 end
local function len(d)
    local l = num(side(d) and fact.sh or fact.sw, 0)
    return l > 0 and l or (side(d) and 1080 or 1920)
end
local function along(d) return d.at * len(d) + d.shift end
local function radius(d) return d.v.size * d.zoom end
local function docked(d) return d.rise < radius(d) * 1.6 end
local function limit(d) return 0.98 * len(d) end           -- how far along its edge a drop's centre may be
-- a capsule reaches further along the edge than a drop, and its middle is off the drop's centre
local function cap_shift(d) return num(d.v.cap, 0) * num(d.v.cap_dir, 0) end
local function span(d) return radius(d) + num(d.v.cap, 0) end
E.len, E.along, E.radius, E.limit = len, along, radius, limit

local function record(d)
    local v = d.v
    return {
        on = not d.hidden, name = v.name or "", edge = d.edge, at = d.at, shift = d.shift + (d.aside or 0), rise = d.rise,
        r = v.size, zoom = d.zoom, swell = v.swell, pull = d.pinned and 0 or clamp(num(v.pull, 0), 0, 1), reach = v.reach,
        lift = clamp(num(v.lift, 1), 0, 2), sticky = v.sticky, tear = v.tear, glint = v.glint, draggable = v.draggable,
        fx = FX[v.fx] or 0, fx_k = v.fx_k, kind = KINDS[v.kind] or 0, value = num(v.value, 0),
        glyph = glyph(v.glyph), label = v.label or "", icon = v.icon or "", has_icon = (v.icon or "") ~= "", dim = d.dim or 0,
        beads = d.beads or 0, bead_hues = d.bead_hues or 0, bead_text = d.bead_text or "",
        core = d.core or 0, core_hue = d.core_hue or 0, core_beat = d.core_beat == true,
        melt = num(v.melt, 1), puddle = num(v.puddle, 1), crown = glyph(v.crown), cap = num(v.cap, 0), cap_dir = num(v.cap_dir, 0),
        line2 = v.line2 or "", lines = (v.line2 or "") ~= "" and 2 or 1, still = v.still == true, chosen = d.chosen == true,
        hop = d.n.hop, squash = d.n.squash, dip = d.n.dip, shiver = d.n.shiver, land = d.n.land, fall = d.n.fall, fall_h = d.fall_h or 0,
    }
end

-- Neighbours: the drops sitting on an edge, in order along it. Two next to each other within reach rise
-- together, lean to each other and are joined by water and a thread. A drop being dragged is nobody's
-- neighbour, or a long thread would hang to where it was.
local function neighbours()
    local sitting = {}
    for k = 0, N - 1 do
        local d = slots[k]
        if d then
            d.left, d.right = nil, nil
            if docked(d) and not d.dragging and not d.hidden then sitting[#sitting + 1] = d end
        end
    end
    table.sort(sitting, function(a, b)
        if a.edge ~= b.edge then return a.edge < b.edge end
        return along(a) < along(b)
    end)
    local function one_body(a, b)
        local x, y = a.v.team, b.v.team
        return x == y or x == 2 or y == 2
    end
    for i = 1, #sitting - 1 do
        local a, b = sitting[i], sitting[i + 1]
        if a.edge == b.edge and one_body(a, b) and along(b) - along(a) < THREAD * (radius(a) + radius(b)) then a.right, b.left = b, a end
    end
end

-- ── drops never cover each other ─────────────────────────────────────────────────────────────────────────────
-- When two would, one moves aside along its edge, and so on down the row. The one that gives way is the one
-- that can: not a window's berry, which its bar lays out, and not a drop that stays beside another; of two
-- that can, the one something was let go onto.
local save
local apart_wanted, apart_keep = false, nil
local function movable(d, other)
    if d.live or d.dragging then return false end
    if not d.def.beside then return true end
    -- A drop beside another does yield to a capsule that grew over it and is not itself tied to it.
    return other ~= nil and num(other.v.cap_dir, 0) ~= 0 and (other.moved == true or other.def.beside ~= d.def.id)
end
local function apart()
    local list, moved = {}, {}
    for k = 0, N - 1 do if slots[k] and not slots[k].hidden then list[#list + 1] = slots[k] end end
    for _ = 1, 10 do
        local any = false
        for i = 1, #list do
            for j = i + 1, #list do
                local a, b = list[i], list[j]
                local berry = a.v.team == 1 or b.v.team == 1
                local family = berry and (a.v.team == b.v.team or a.v.team == 2 or b.v.team == 2)
                if a.edge == b.edge and not family then
                    local l = len(a)
                    local ax, bx = along(a) + cap_shift(a), along(b) + cap_shift(b)
                    local need = (berry and BERRY_GAP or MIN_GAP) * (span(a) + span(b))
                    local dx, dy = bx - ax, b.rise - a.rise
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < need - 0.5 then
                        local mv, other
                        if movable(b, a) and (b ~= apart_keep or not movable(a, b)) then mv, other = b, a
                        elseif movable(a, b) then mv, other = a, b end
                        if mv then
                            local ox, px = along(mv) + cap_shift(mv), along(other) + cap_shift(other)
                            local vx, vy = ox - px, mv.rise - other.rise
                            if docked(mv) then vy = 0 end
                            local l2 = math.sqrt(vx * vx + vy * vy)
                            if l2 < 0.5 then vx, vy, l2 = 1, 0, 1 end          -- exactly on top: to the right
                            local push = need - dist + 2
                            local hi = limit(mv) / l
                            mv.at = clamp((ox + vx / l2 * push - cap_shift(mv) - mv.shift) / l, 0.02, hi)
                            mv.rise = math.max(0, mv.rise + vy / l2 * push)
                            -- at the end of the edge there is nowhere to go: to the other side
                            if (mv.at <= 0.02 or mv.at >= hi - 0.0005) and docked(mv) then
                                mv.at = clamp((px - vx / l2 * need - cap_shift(mv) - mv.shift) / l, 0.02, 0.98)
                            end
                            mv.moved, moved[mv], any = true, true, true
                        end
                    end
                end
            end
        end
        if not any then break end
    end
    for d in pairs(moved) do d.n.squash += 1 end
    if next(moved) then save() end
    apart_keep = nil
end
function E.apart(keep) apart_wanted, apart_keep = true, keep or apart_keep end

-- A drop beside another keeps to where that one is now, until the user moves it away himself.
local function follow_anchor(d, depth)
    local a = d.def.beside and by_id[d.def.beside]
    if not a or d.moved or d.dragging or depth > 4 then return end
    follow_anchor(a, depth + 1)
    d.at, d.shift, d.edge = a.at, a.shift + num(d.def.gap, 0), a.edge
end

-- Several changes in one step are one record handed to the scene.
local publishing, again = false, false
local function publish()
    if publishing then again = true return end
    publishing = true
    after(16, function()
        for k = 0, N - 1 do if slots[k] then follow_anchor(slots[k], 0) end end
        if apart_wanted then
            apart_wanted = false
            apart()
            for k = 0, N - 1 do if slots[k] then follow_anchor(slots[k], 0) end end
        end
        neighbours()
        local list = {}
        for k = 0, N - 1 do
            local d = slots[k]
            local r = d and record(d) or { on = false }
            if d and d.left then r.left, r.left_at, r.left_shift = true, d.left.at, d.left.shift + (d.left.aside or 0) end
            if d and d.right then
                local o = d.right
                r.right, r.right_at, r.right_shift, r.right_rise, r.right_r = true, o.at, o.shift + (o.aside or 0), o.rise, radius(o)
            end
            list[k + 1] = r
        end
        model.goo = list
        publishing = false
        if again then again = false publish() end
    end)
end
E.publish = publish

-- ── a drop gets out of a window's way ────────────────────────────────────────────────────────────────────────
-- A drop on a side edge or on the top one must not lie over a window's title with its buttons. While a
-- window's title is under it, it steps aside along its edge to the nearest free spot, and comes back when
-- the window has gone: the step (`aside`) is not kept. On a side edge the whole title counts, on the top
-- edge only its ends, where the buttons are. `windows`: those in sight, each { x, y, w, h }.
local ABOVE, TITLE, GAP = 34, 48, 8      -- the compositor's title bar above a window, the app's own header in it; the room a drop keeps
local BUTTONS_RIGHT, BUTTONS_LEFT = 190, 120
function E.avoid(windows)
    local w, changed = num(fact.sw, 1920), false
    for k = 0, N - 1 do
        local d = slots[k]
        if d and d.aside ~= 0 and (d.hidden or d.edge == 0) then d.aside, changed = 0, true end
        if d and not d.hidden and not d.dragging and d.edge ~= 0 and d.v.team ~= 1 and docked(d) then
            local r, home = span(d), d.at * len(d) + d.shift
            local lo, hi = r + 6, len(d) - r - 6
            local taken = {}                  -- stretches along the edge where its centre must not be
            for _, win in ipairs(windows or {}) do
                if d.edge == 2 then
                    if 6 + d.rise + r > win.y - ABOVE and 6 + d.rise - r < win.y + TITLE then
                        taken[#taken + 1] = { win.x + win.w - BUTTONS_RIGHT - r - GAP, win.x + win.w + r + GAP }
                        taken[#taken + 1] = { win.x - r - GAP, win.x + BUTTONS_LEFT + r + GAP }
                    end
                else
                    local x = d.edge == 1 and 6 + d.rise or w - 6 - d.rise
                    if x + r > win.x and x - r < win.x + win.w then taken[#taken + 1] = { win.y - ABOVE - r - GAP, win.y + TITLE + r + GAP } end
                end
            end
            local function free(p)
                if p < lo or p > hi then return false end
                for _, t in ipairs(taken) do if p > t[1] and p < t[2] then return false end end
                return true
            end
            local best = free(home) and home or nil
            if not best then
                for _, t in ipairs(taken) do
                    for _, p in ipairs({ t[1] - 1, t[2] + 1 }) do
                        if free(p) and (not best or math.abs(p - home) < math.abs(best - home)) then best = p end
                    end
                end
            end
            local aside = best and math.abs(best - home) >= 0.5 and best - home or 0
            if aside ~= d.aside then d.aside, changed = aside, true end
        end
    end
    if changed then publish() end
end

-- ── where the user left each drop ────────────────────────────────────────────────────────────────────────────
local saving
local savers = {}
function E.on_save(f) savers[#savers + 1] = f end       -- whoever else keeps something about where the drops are
save = function()
    if saving then cancel(saving) end
    saving = after(1200, function()
        saving = nil
        local out = {}
        for id, d in pairs(by_id) do
            if not d.live and (d.moved or d.zoom ~= 1) then out[id] = { at = d.at, rise = d.rest or d.rise, zoom = d.zoom, edge = d.edge } end
        end
        pcall(sys.call, "files.write", PLACES, out)
        for _, f in ipairs(savers) do pcall(f) end
    end)
end
E.save = function() save() end

-- ── what a drop can be told to do ────────────────────────────────────────────────────────────────────────────
function Drop:set(t) for key, val in pairs(t) do self.v[key] = val end publish() end
function Drop:label(s) self.v.label = s or "" publish() end
function Drop:name(s) self.v.name = s or "" publish() end
function Drop:glyph(name) self.v.glyph = name publish() end
function Drop:icon(name) self.v.icon = name or "" publish() end
function Drop:value(x) self.v.value = x publish() end
function Drop:fx(name, k) self.v.fx, self.v.fx_k = name, k or self.v.fx_k publish() end
function Drop:fade(x) self.dim = x or 0 publish() end
function Drop:resize(zoom)
    local old = self.zoom
    self.zoom = clamp(zoom, ZOOM_MIN, ZOOM_MAX)
    -- A sitting drop grows from the surface: its centre rises with its size, or the edge would cut it.
    if old > 0 and self.rise < self.v.size * old * 1.6 then self.rise = self.rise / old * self.zoom end
    E.apart(self) publish() save()
end
function Drop:move(at, rise) self.at, self.rise, self.shift, self.moved = clamp(at, 0.02, 0.98), math.max(0, rise), 0, true publish() save() end
function Drop:go_home()
    self.at, self.rise, self.shift, self.zoom, self.edge, self.moved = self.home.at, self.home.rise, self.home.shift, 1, self.home.edge, false
    publish() save()
end
function Drop:hop() self.n.hop += 1 publish() end
function Drop:squash() self.n.squash += 1 publish() end
function Drop:shiver() self.n.shiver += 1 publish() end
function Drop:tip(s) text.tip = s or "" end
-- Beads beside the drop: how many, and their colour: one for all, or a list, one each.
function Drop:set_beads(n, hue)
    n = math.max(0, math.floor(n or 0))
    local code = 0
    for j = 0, 3 do
        local h = type(hue) == "table" and (hue[j + 1] or hue[#hue]) or hue
        code += (BEADS[h] or num(h, 3)) * 8 ^ j
    end
    self.beads, self.bead_hues, self.bead_text = math.min(n, 5), code, n > 4 and tostring(n) or ""
    publish()
end
-- A coloured core, by default pulsing; without a colour it goes out.
function Drop:set_core(hue, strength, beat)
    if hue == nil then self.core = 0
    else self.core, self.core_hue, self.core_beat = strength or 1, HUES[hue] or num(hue, 5), beat ~= false end
    publish()
end
-- A drop that only makes sense at times (a chat that is running) can take itself off the desktop.
function Drop:present(yes)
    local absent = yes == false
    if absent ~= (self.absent == true) then
        self.absent = absent
        if E.apply_hidden() then E.apart() publish() end
    end
end
function Drop:ripple(force) E.ripple(self, force or 6, "stone") end
function Drop:tremble(force) E.ripple(self, force or 3, "tremble") end

-- ── the surface: four ripples at a time, taken in turn ───────────────────────────────────────────────────────
local ripples, next_ripple = {}, 0
for i = 1, 4 do ripples[i] = { at = 0, shift = 0, force = 0, kind = 0, n = 0 } end
-- where: a drop, or a share (0…1) of the bottom edge, which is the only one that ripples
function E.ripple(where, force, kind)
    if type(where) == "table" and where.edge ~= 0 then return end
    local r = ripples[next_ripple + 1]
    next_ripple = (next_ripple + 1) % 4
    if type(where) == "table" then r.at, r.shift = where.at, where.shift else r.at, r.shift = where or 0.5, 0 end
    r.force, r.kind, r.n = force or 6, kind == "tremble" and 1 or 0, r.n + 1
    model.ripple = ripples
end

-- ── the register ─────────────────────────────────────────────────────────────────────────────────────────────
local function free_slot()
    for k = 0, N - 1 do if not slots[k] then return k end end
end

-- a place on the bottom edge for a drop that asks for none: after the last one, left to right
local function next_home()
    local at = 0.03
    for k = 0, N - 1 do
        local d = slots[k]
        if d and not d.live and not d.def.beside and d.home.edge == 0 then at = math.max(at, d.home.at + 0.03) end
    end
    return at
end

local function values(def)
    local v = table.clone(DEFAULTS)
    for key, val in pairs(E.NATURES[def.nature] or {}) do v[key] = val end
    for key, val in pairs(def) do v[key] = val end
    return v
end

function E.define(def, live)
    assert(type(def) == "table" and type(def.id) == "string", "a drop needs an id")
    local was = by_id[def.id]                    -- defined again: it stays where the user left it
    if was then
        places[def.id] = { at = was.at, rise = was.rise, zoom = was.zoom, edge = was.edge }
        E.remove(def.id)
    end
    local k = free_slot()
    if not k then log("goo: all " .. N .. " places are taken, no room for " .. def.id) return nil end
    local v = values(def)
    local d = setmetatable({ id = def.id, k = k, v = v, def = def, live = live == true, aside = 0,
                             n = { hop = 0, squash = 0, dip = 0, shiver = 0, land = 0, fall = 0 } }, Drop)
    local seat = num(v.seat, v.size * 0.8)
    local anchor = def.beside and by_id[def.beside]
    if anchor then
        d.home = { at = anchor.home.at, shift = anchor.home.shift + num(def.gap, 0), rise = seat, edge = anchor.home.edge }
    elseif type(def.home) == "table" then
        d.home = { at = num(def.home.at, 0.5), shift = 0, rise = seat, edge = clamp(math.floor(num(def.home.edge, 0)), 0, 3) }
    else
        d.home = { at = next_home(), shift = 0, rise = seat, edge = 0 }
    end
    local p = not d.live and places[def.id] or nil
    d.at, d.rise, d.edge = p and num(p.at, d.home.at) or d.home.at, p and num(p.rise, seat) or seat, clamp(math.floor(num(p and p.edge, d.home.edge)), 0, 3)
    d.zoom = clamp(num(p and p.zoom, 1), ZOOM_MIN, ZOOM_MAX)
    d.shift = p and 0 or d.home.shift
    d.moved = p ~= nil
    -- nothing hangs in the air: a drop saved away from an edge sits down on it
    if d.rise >= v.size * d.zoom * 1.6 then d.rise = seat * d.zoom end
    slots[k], by_id[def.id] = d, d
    E.apart()
    local function safe(name, f)                  -- one drop's mistake does not take the others down
        local ok, err = pcall(f, d)
        if not ok then log("goo: " .. d.id .. "." .. name .. ": " .. tostring(err)) end
    end
    if def.every and def.tick then
        d.timer = every(def.every, function() safe("tick", def.tick) end)
        safe("tick", def.tick)
    end
    if def.start then safe("start", def.start) end
    publish()
    return d
end

-- Adds a drop, or changes one that is there without a jump: its place and its motion stay. For drops that come
-- and go while the desktop runs, like windows.
function E.upsert(def)
    local d = by_id[def.id]
    if not d then return E.define(def, true) end
    d.def = def
    for key, val in pairs(def) do d.v[key] = val end
    local seat = num(def.seat, d.v.size * 0.8)
    local anchor = def.beside and by_id[def.beside]
    if anchor then
        d.home = { at = anchor.home.at, shift = anchor.home.shift + num(def.gap, 0), rise = seat, edge = anchor.home.edge }
    elseif type(def.home) == "table" then
        d.home = { at = num(def.home.at, d.home.at), shift = 0, rise = seat, edge = d.home.edge }
    end
    if not d.moved then d.at, d.rise, d.shift = d.home.at, d.home.rise, d.home.shift end
    E.apart()
    publish()
    return d
end

function E.remove(id)
    local d = by_id[id]
    if not d then return end
    if d.timer then cancel(d.timer) end
    slots[d.k], by_id[id] = nil, nil
    publish()
end

function E.get(id) return by_id[id] end
function E.each(f) for k = 0, N - 1 do if slots[k] then f(slots[k]) end end end

-- ── the card's ear: its owner steps away from the edge and sits in the card's corner ─────────────────────────
function E.can_rise(d) return not d.live and (docked(d) or d.rest ~= nil) end
function E.raise(d, height)
    if d.rest then return end
    d.rest, d.pinned = d.rise, true
    d.rise = height
    publish()
end
function E.lower(d)
    if not d.rest then return end
    d.rise, d.rest, d.pinned = d.rest, nil, false
    d.n.dip += 1
    publish()
end

-- ── what the scene heard ─────────────────────────────────────────────────────────────────────────────────────
local function call(d, name, ...)
    local f = d.def[name]
    if type(f) ~= "function" then return false end
    local ok, res = pcall(f, d, ...)
    if not ok then log("goo: " .. d.id .. "." .. name .. ": " .. tostring(res)) return true end
    return true, res
end
E.call = call

-- A click is the left button let go without a drag and without having been held. The scene reports the press
-- and the release; what happened in between is kept here.
local down = nil
on("goo_down", function(k) down = k end)
on("goo_up", function(k)
    local was = down
    down = nil
    local d = slots[k]
    if not d or was ~= k then return end
    if not call(d, "click") then d:shiver() end
end)
on("goo_right", function(k)
    down = nil
    local d = slots[k]
    if d and not call(d, "right") then d:shiver() end
end)
on("goo_middle", function(k)
    down = nil
    local d = slots[k]
    if d and not call(d, "middle") then d:shiver() end
end)
on("goo_hold", function(k)
    if down ~= k then return end
    down = nil
    local d = slots[k]
    if d then call(d, "hold") end
end)
on("goo_wheel", function(v)
    local d, up = slots[v // 2], v % 2 == 1
    if not d then return end
    -- Any drop that has no other use for the wheel is inflated with it; not a window's berry.
    if not call(d, "wheel", up and 1 or -1) and d.v.zoomable and not d.live then d:resize(d.zoom + (up and 0.1 or -0.1)) end
end)
on("goo_enter", function(k) local d = slots[k] if d then call(d, "enter") end end)
on("goo_leave", function(k) local d = slots[k] if d then call(d, "leave") end end)
-- the tooltip: the drop's name and what it does
local function tip_of(d)
    local about = d.def.about
    if type(about) == "function" then local _, res = call(d, "about") about = res end
    local name = d.v.name or ""
    return (about and about ~= "" and about ~= name) and (name ~= "" and name .. " · " .. about or about) or name
end
on("goo_hover", function(k)
    local d = slots[k]
    if d then d:tip(tip_of(d)) end
end)
on("goo_grab", function(k)
    down = nil
    local d = slots[k]
    if not d then return end
    d.dragging = true
    publish()
    call(d, "grab")
end)

-- Let go after a drag, a drop never stays in the air. Near an edge it sticks to it; anywhere else it falls
-- straight down to the bottom one, dives and comes up, and the surface ripples. One that `returns` goes back.
on("goo_letgo", function(k)
    local d = slots[k]
    if not d then return end
    local x, y = num(fact["freed.x"], 0), num(fact["freed.y"], 0)
    local w, h = num(fact.sw, 0), num(fact.sh, 0)
    if w <= 0 then w = 1920 end
    if h <= 0 then h = 1080 end
    d.dragging = false
    d.drops = (d.drops or 0) + 1
    local edge, best = 0, math.huge
    for e, dist in ipairs({ h - y, x, y, w - x }) do              -- bottom, left, top, right
        if dist < STICK and dist < best then edge, best = e - 1, dist end
    end
    local fell = best == math.huge
    local has, res = call(d, "letgo", x, y, edge)
    local back = (has and res == false) or (fell and d.v.returns)
    local fall = 0
    if not back then
        d.edge = edge
        d.at = math.min(clamp(edge % 2 == 1 and y / h or x / w, 0.02, 0.98), limit(d) / len(d))
        d.rise = num(d.v.seat, d.v.size * 0.8) * d.zoom
        d.moved, d.shift = true, 0
        if fell then fall = math.max(0, (h - 6 - d.rise) - y) end
        save()
    end
    -- The new home, the end of the drag and the height of the fall reach the scene in one record.
    d.n.land += 1
    d.fall_h = fall
    if fall > 0 then d.n.fall += 1 end
    E.apart(d)
    publish()
    call(d, "placed")
    if back then return end
    -- When it lands it flattens and the surface ripples; stuck to an edge it dives and comes up at once.
    after(fall > 0 and math.sqrt(2 * fall / GRAVITY) * 1000 or 0, function()
        if by_id[d.id] ~= d or d.dragging then return end
        if fall > 0 then d.n.squash += 1 else d.n.dip += 1 end
        publish()
        after(fall > 0 and 60 or 200, function() E.ripple(d, (fall > 0 and 3 + math.min(fall, 900) * 0.008 or 4) + radius(d) * 0.12, "stone") end)
    end)
end)

-- ── Goo from the keyboard (parts/keys.plm) ───────────────────────────────────────────────────────────────────
-- A way around when there is no mouse, not a second way of arranging things: the arrows only walk. The scene
-- holds the keyboard meanwhile and nothing can be typed into a window, so it ends by itself: after a window
-- was chosen, after a choice in a card, after a minute without a key.
local chosen, kb_timer = nil, nil
local function choose(d)
    if chosen and by_id[chosen.id] == chosen then chosen.chosen = false end
    chosen = d
    if d then
        d.chosen = true
        fact.kb_at = d.k
        d:tip(tip_of(d))
    else
        fact.kb_at = -1
    end
    publish()
end
local function kb_leave()
    if kb_timer then cancel(kb_timer) kb_timer = nil end
    if fact.kb then fact.kb = false end
    choose(nil)
end
local function kb_touch()
    if kb_timer then cancel(kb_timer) end
    kb_timer = after(60000, kb_leave)
end
-- the drops in order around the screen: the bottom edge left to right, up the right one, back along the top, down the left
local function ring()
    local list = {}
    E.each(function(d) if not d.hidden then list[#list + 1] = d end end)
    local turn = { [0] = 0, [3] = 1, [2] = 2, [1] = 3 }
    local function place(d)
        local a = along(d)
        if d.edge == 3 or d.edge == 2 then a = len(d) - a end
        return turn[d.edge] * 1e6 + a
    end
    table.sort(list, function(a, b) return place(a) < place(b) end)
    return list
end
on("kb_toggle", function()
    if fact.kb then return kb_leave() end
    local list = ring()
    if #list == 0 then return end
    fact.kb = true
    kb_touch()
    local lens = by_id.lensgoo
    choose(lens and not lens.hidden and lens or list[1])
end)
on("kb_exit", kb_leave)
-- An arrow along the drop's edge goes to the next one round, or the one before: left and right on the bottom
-- edge, up and down on the sides. The scene counts the arrows 0 left, 1 right, 2 up, 3 down.
local STEP = { [0] = { [1] = 1, [0] = -1 }, [3] = { [2] = 1, [3] = -1 }, [2] = { [0] = 1, [1] = -1 }, [1] = { [3] = 1, [2] = -1 } }
on("kb_nav", function(arrow)
    if not fact.kb or not chosen then return end
    kb_touch()
    local list = ring()
    local step = STEP[chosen.edge][arrow or 0]
    if not step or #list == 0 then return end
    local at = 1
    for i, d in ipairs(list) do if d == chosen then at = i end end
    choose(list[(at - 1 + step) % #list + 1])
end)
on("kb_act", function(what)
    local d = chosen
    if not fact.kb or not d then return end
    kb_touch()
    if what == 0 then
        if not call(d, "click") then d:shiver() end
        if d.live then after(150, kb_leave) end           -- a window was chosen: the keyboard is its own again
    elseif what == 1 then
        if not call(d, "right") then d:shiver() end
    else
        local dir = what == 2 and 1 or -1
        if not call(d, "wheel", dir) and d.v.zoomable and not d.live then d:resize(d.zoom + dir * 0.1) end
    end
end)
-- a choice in a card that closed it was what the keyboard was wanted for
on("card_pick", function() after(200, function() if fact.kb and not fact.card_open then kb_leave() end end) end)

-- ── left alone: asleep after a minute, then the weather outside on the surface ───────────────────────────────
local weather = { rain = 0, snow = false, wind = 0 }
local raining, blowing, gust_at = nil, nil, 0
local low_battery = false
pcall(sys.watch, "battery", function(b)
    low_battery = type(b) == "table" and b.present == true and (tonumber(b.percent) or 100) < 20 and b.charging ~= true
end)
local TIER = env("LATTE_TIER")
E.busy = nil                 -- function(answer): answers true while the desktop should be left in peace (a film, a game)

local function weather_off()
    if raining then cancel(raining) raining = nil end
    if blowing then cancel(blowing) blowing = nil end
    fact.rain = 0
end
local function weather_on()
    weather_off()
    if weather.rain > 0 then
        fact.snow, fact.rain = weather.snow, weather.rain
        if not weather.snow then
            raining = every(weather.rain == 2 and 650 or 1500, function() E.ripple(math.random(), weather.rain == 2 and 2.6 or 1.8, "stone") end)
        end
    elseif weather.wind >= 30 then                  -- km/h: waves run along the edge
        gust_at = 0
        blowing = every(420, function()
            E.ripple(gust_at, 3.2, "stone")
            gust_at = (gust_at + 1 / 18) % 1
        end)
    end
end
local function sky()
    run("latte-sky", {}, function(out)
        local ok, t = pcall(json.decode, out or "")
        if not ok or type(t) ~= "table" then return end
        weather.rain, weather.snow, weather.wind = tonumber(t.rain) or 0, t.snow == true, tonumber(t.wind) or 0
        local alt = type(t.sun) == "table" and tonumber(t.sun.alt) or 30
        fact.day = clamp((alt + 6) / 12, 0, 1)                     -- civil twilight … the sun 6° up
        fact.golden = clamp(1 - math.abs(alt - 2) / 10, 0, 1)      -- the sun between −8° and 12°
    end)
end
E.weather = { on = weather_on, off = weather_off, now = weather }

on("goo_idle", function(stage)
    E.each(function(d) call(d, "idle", stage) end)
    if stage == 0 then return weather_off() end
    -- Not on a machine that draws in software or is short of battery, and not over a film or a game.
    if stage < 2 or fact.lively == false or TIER == "software" or low_battery then return end
    local function go(busy)
        if not busy and fact.idle >= stage then weather_on() end
    end
    if E.busy then E.busy(go) else go(false) end
end)

-- ── settings: settings.json in the scene's own folder, taken up as soon as it changes ────────────────────────
--   { "lively": true, "material": "coffee" | "glass", "bends": true, "hidden": ["clockgoo"], "zoom": { "lensgoo": 1.2 } }
-- The scenes on the other monitors (side.plm) keep no settings: the main one tells them what it has, when it
-- changes and when one of them starts (`side_hello`). E.tell says something to every Goo scene, this one too.
local SETTINGS = "settings.json"
function E.tell(...) run("latte-say", { ... }) end
local hidden, zooms = {}, {}
local chosen_settings = {}                   -- the file as it was last read
function E.apply_hidden()
    local changed = false
    for id, d in pairs(by_id) do
        local h = (hidden[id] == true or d.absent == true) and not d.def.core and not d.live
        if h ~= (d.hidden == true) then d.hidden = h changed = true end
    end
    return changed
end
local function settings()
    local ok, t = pcall(sys.ask, "files.read", SETTINGS, "json")
    if not ok or type(t) ~= "table" then t = {} end
    chosen_settings = t
    fact.lively = t.lively ~= false
    fact.glassy = t.material == "glass"
    fact.bends = t.bends ~= false
    if not fact.lively then weather_off() end
    hidden = {}
    for _, id in ipairs(type(t.hidden) == "table" and t.hidden or {}) do hidden[id] = true end
    local changed = E.apply_hidden()
    for id, z in pairs(type(t.zoom) == "table" and t.zoom or {}) do
        local d = by_id[id]
        z = tonumber(z)
        if d and z and zooms[id] ~= z then zooms[id] = z d:resize(z) end
    end
    if changed then E.apart() publish() end
    E.tell("fact lively " .. tostring(fact.lively), "fact glassy " .. tostring(fact.glassy), "fact bends " .. tostring(fact.bends))
end

-- what is set now, and setting one thing: it is written down and taken up at once
function E.settings() return chosen_settings end
function E.set(key, value)
    chosen_settings[key] = value
    pcall(sys.call, "files.write", SETTINGS, chosen_settings)
    settings()
end
-- every drop that can be hidden, for whoever offers the choice: { id, name, hidden }
function E.optional()
    local list = {}
    E.each(function(d) if not d.def.core and not d.live then list[#list + 1] = { id = d.id, name = d.def.name or d.id, hidden = hidden[d.id] == true } end end)
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
-- every drop back where it belongs and to its own size
function E.reset_places()
    E.each(function(d) if not d.live and (d.moved or d.zoom ~= 1) then d:go_home() end end)
end

-- The coffee the goo is made of: how much water and milk. `emit coffee_changed` from outside reads it again.
local function coffee()
    run("latte-login", { "coffee" }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if ok and type(c) == "table" and #c == 2 then fact.water, fact.milk = c[1], c[2] end
    end)
end
on("coffee_changed", coffee)

-- ── the start ────────────────────────────────────────────────────────────────────────────────────────────────
-- opts.drops: the names of the modules in drops/, in the order they are defined (one beside another after it)
-- opts.side: this is the scene of a monitor that is not the main one
function E.start(opts)
    card.attach(E)
    local ok, saved = pcall(sys.ask, "files.read", PLACES, "json")
    if ok and type(saved) == "table" then places = saved end
    for _, name in ipairs(opts.drops or {}) do
        local found, def = pcall(require, "drops/" .. name)
        if found and type(def) == "table" then E.define(def)
        else log("goo: drops/" .. name .. ": " .. tostring(def)) end
    end
    if opts.side then
        E.tell("emit side_hello")
    else
        settings()
        pcall(sys.watch, "files:" .. SETTINGS, settings)
        on("side_hello", settings)
    end
    coffee()
    after(1500, sky)
    every(600000, sky)
    -- The screen's size arrives after the start and changes with the monitor: lay the drops out again.
    on("fact:sw", function() E.apart() publish() end)
    on("fact:sh", function() E.apart() publish() end)
    publish()
end

return E
