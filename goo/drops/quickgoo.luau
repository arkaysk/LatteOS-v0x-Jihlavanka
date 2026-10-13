-- QuickGoo: the apps kept at hand. A press stretches it along its edge into a strip of their icons
-- (parts/launch.plm); a press on one starts it and the strip draws back in, a second press on the drop does
-- too. Which apps: LensGoo's right button on an app puts it on the strip or takes it off, and so does the right
-- button on an icon here. Until the user has chosen any, the apps started most lately stand in.
local open = require("lib/open")
local M = {}

local FILE = "quick.json"
local MOST = 8                               -- icons on the strip
local CELL, R = 44, 22
local kept = {}                              -- the ids of the apps the user chose, in order
local apps, by_id = {}, {}
local shown = {}                             -- the apps on the strip now
local out = false
local drop, lately

local function save() pcall(sys.call, "files.write", FILE, kept) end
local function fill()
    shown = {}
    for _, id in ipairs(kept) do if by_id[id] and #shown < MOST then shown[#shown + 1] = by_id[id] end end
    if #kept == 0 then
        for _, id in ipairs(lately and lately() or {}) do if by_id[id] and #shown < 5 then shown[#shown + 1] = by_id[id] end end
        for _, a in ipairs(apps) do if #shown < 5 and not table.find(shown, a) then shown[#shown + 1] = a end end
    end
    local pins = {}
    for i, a in ipairs(shown) do
        pins[i] = { icon = a.icon or "", has_icon = (a.icon or "") ~= "", glyph = "", name = a.local_name or a.name or a.id or "" }
    end
    model.pin = pins
end
local function shape()
    fact.launch_owner, fact.launch_cell = drop.k, CELL
    drop:stretch(math.max(#shown, 1) * CELL / 2 + 3, R)
end
local function draw_in()
    if not out then return end
    out = false
    fact.launch_on = false
    drop:shrink()
end
local function bring_out()
    if out or not drop then return end
    fill()
    if #shown == 0 then return drop:shiver() end
    out = true
    shape()
    fact.launch_on = true
    drop:squash()
end

function M.has(a) return a ~= nil and table.find(kept, a.id) ~= nil end
function M.add(a)
    if not a or not a.id or M.has(a) or #kept >= MOST then return end
    kept[#kept + 1] = a.id
    save()
    if out then fill() shape() end
end
function M.remove(a)
    local i = a and table.find(kept, a.id)
    if not i then return end
    table.remove(kept, i)
    save()
    if out then fill() if #shown == 0 then draw_in() else shape() end end
end
-- who knows which apps were started lately (LensGoo): a function that lists their ids
function M.lately(f) lately = f end

-- The definition is this module: the engine takes it as a drop, LensGoo asks it what is on the strip.
for key, value in pairs({
    id = "quickgoo", name = "QuickGoo", glyph = "rocket", nature = "curious", size = 24, seat = 17, swell = 0.1,
    home = { edge = 0, at = 0.27 },
    about = function() return tr("left: the apps kept at hand") end,
    start = function(d)
        drop = d
        local ok, saved = pcall(sys.ask, "files.read", FILE, "json")
        if ok and type(saved) == "table" then kept = saved end
        sys.watch("apps", function(list)
            apps, by_id = list or {}, {}
            for _, a in ipairs(apps) do if a.id then by_id[a.id] = a end end
            if out then fill() shape() end
        end)
        on("launch_pick", function(u)
            local a = shown[(u or 0) + 1]
            draw_in()
            if a then after(80, function() open.app(a) end) end
        end)
        on("launch_right", function(u)
            local a = shown[(u or 0) + 1]
            if a and M.has(a) then M.remove(a) end
        end)
        on("launch_hover", function(u) local a = shown[(u or 0) + 1] if a then d:tip(a.local_name or a.name or a.id or "") end end)
    end,
    click = function() if out then draw_in() else bring_out() end end,
    -- moved to another edge, or to where the capsule has no room on that side: it is shaped again
    placed = function() if out then after(400, function() if out then shape() end end) end end,
}) do M[key] = value end

return M
