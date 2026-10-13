-- The user's own drops, made of ready parts with no programming: drops.json in the scene's folder, a list,
-- taken up as soon as it is saved.
--   { "id": "calc", "name": "Calculator", "app": "org.gnome.Calculator" }
--        an app: the drop carries its icon and a press starts it. LensGoo's right button on an app pins one.
--   { "id": "load", "name": "Load", "glyph": "cpu", "nature": "playful",
--     "text": "cut -d' ' -f1 /proc/loadavg", "every": 5, "click": "foot -e htop", "middle": "…" }
--        `text`: a command whose first line is written on the drop, asked every so many seconds;
--        `click`, `middle`: commands for the shell. `nature`: calm, curious, sticky, heavy, playful.
-- The right button is the same on all of them: back to its place, or remove it.
local E = require("lib/engine")
local card = require("lib/card")
local open = require("lib/open")
local M = {}

local FILE = "drops.json"
local list = {}                      -- the file, as it was last read
local made = {}                      -- id → true: the drops that are on the desktop from it
local apps = {}                      -- an app's id → its entry in the launcher

local function shell(command) run("sh", { "-c", command }, nil, { output = false }) end
local function save() pcall(sys.call, "files.write", FILE, list) end

local function menu(d, entry)
    card.open({
        { label = tr("Back to its place"), glyph = "home-2", run = function() d:go_home() end },
        { label = tr("Remove the drop"), glyph = "x", danger = true, line = true, run = function() M.remove(entry.id) end },
    }, { owner = d, id = "own", width = 260 })
end

local function define(entry, i)
    local app = entry.app and apps[entry.app]
    local name = entry.name or (app and (app.local_name or app.name)) or entry.id
    local def = {
        id = entry.id, name = name, glyph = entry.glyph or (entry.app and "apps" or "droplet"), nature = entry.nature or "curious",
        icon = app and app.icon or "", home = { edge = 0, at = 0.06 + 0.035 * i }, about = name,
        right = function(d) menu(d, entry) end,
    }
    if entry.app then
        def.click = function(d) if apps[entry.app] then open.app(apps[entry.app]) d:hop() else d:shiver() end end
    elseif type(entry.click) == "string" then
        def.click = function(d) shell(entry.click) d:hop() end
    end
    if type(entry.middle) == "string" then def.middle = function() shell(entry.middle) end end
    if type(entry.text) == "string" then
        def.every = math.max(2, tonumber(entry.every) or 10) * 1000
        def.tick = function(d)
            run("sh", { "-c", entry.text }, function(out) d:label(((out or ""):match("[^\n]*") or ""):sub(1, 8)) end)
        end
    end
    return def
end

-- the drops are made to be what the file says: new ones come, changed ones are made again, the rest go
local shown = {}                     -- id → the entry as it was when its drop was made
local function same(a, b)
    for _, key in ipairs({ "name", "glyph", "nature", "app", "click", "middle", "text", "every" }) do if a[key] ~= b[key] then return false end end
    return true
end
local function apply()
    local now = {}
    for i, entry in ipairs(list) do
        if type(entry) == "table" and type(entry.id) == "string" and entry.id:match("^[%w_-]+$") and not now["own-" .. entry.id] then
            local id = "own-" .. entry.id
            now[id] = true
            local known = entry.app == nil or apps[entry.app] ~= nil
            if not made[id] or not same(shown[id], entry) or shown[id].known ~= known then
                local def = define(entry, i - 1)
                def.id = id
                E.define(def)
                made[id], shown[id] = true, table.clone(entry)
                shown[id].known = known
            end
        end
    end
    for id in pairs(made) do
        if not now[id] then E.remove(id) made[id], shown[id] = nil, nil end
    end
    if E.apply_hidden() then E.apart() E.publish() end       -- one the user has hidden stays hidden
end

local function read()
    local ok, t = pcall(sys.ask, "files.read", FILE, "json")
    list = ok and type(t) == "table" and t or {}
    apply()
end

-- LensGoo's "pin as a drop": an app, by its entry in the launcher
function M.pinned(a)
    for _, entry in ipairs(list) do if entry.app == a.id then return true end end
    return false
end
function M.pin(a)
    if not a or not a.id or M.pinned(a) then return end
    list[#list + 1] = { id = (a.id:gsub("[^%w_-]", "-")), app = a.id }
    save()
    apply()
end
function M.remove(id)
    for i, entry in ipairs(list) do
        if entry.id == id or entry.app == id then table.remove(list, i) break end
    end
    save()
    apply()
end

function M.start()
    read()
    pcall(sys.watch, "files:" .. FILE, read)
    sys.watch("apps", function(all)
        apps = {}
        for _, a in ipairs(all or {}) do if a.id then apps[a.id] = a end end
        apply()
    end)
end

return M
