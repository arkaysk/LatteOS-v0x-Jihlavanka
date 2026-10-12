-- The launcher: the card LensGoo opens. What is typed is searched for in the mode the tabs choose:
--   Applications   with nothing typed the apps used last, as tiles; typing finds apps
--   Command        a line for the terminal, which stays open afterwards; a dangerous one asks once more
-- Enter takes the first row. A mode is one entry in MODES and one branch in `rows`.
-- The mode, the apps used last and the commands run are kept in lens.json in the scene's folder.
local card = require("lib/card")
local find = require("lib/find")
local dangerous = require("lib/dangerous")
local open = require("lib/open")
local M = {}
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local WIDTH = 450
local FILE = "lens.json"
local MODES = {
    [0] = { glyph = "apps", name = N("Applications"), hint = N("Search apps…") },
    [1] = { glyph = "terminal-2", name = N("Command"), hint = N("Run a command…") },
}
local apps, by_id = {}, {}
local kept = { mode = 0, recent = {}, commands = {} }
local owner                          -- LensGoo
local typed, confirm = "", nil       -- what is in the field; the dangerous command asked about
local render

local function save() pcall(sys.call, "files.write", FILE, kept) end

-- The card lets go of the keyboard first and the app starts a moment later: a window that opens while the
-- shell still holds the keyboard does not get it when the shell lets go.
local function launch(a)
    card.close()
    after(80, function() open.app(a) end)
    if not a.id then return end
    local recent = { a.id }
    for _, id in ipairs(kept.recent) do if id ~= a.id and #recent < 18 then recent[#recent + 1] = id end end
    kept.recent = recent
    save()
end
local function run_command(cmd)
    local commands = { cmd }
    for _, c in ipairs(kept.commands) do if c ~= cmd and #commands < 12 then commands[#commands + 1] = c end end
    kept.commands = commands
    save()
    card.close()
    after(80, function() open.shell(cmd) end)
end
-- a dangerous command is asked about once: entered again, it runs
local function confirmed(cmd)
    if not dangerous(cmd) or confirm == cmd then return true end
    confirm = cmd
    render(true)
    return false
end

local function tile(a) return { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", run = function() launch(a) end } end
local function rows()
    local out = {}
    if kept.mode == 1 then
        if typed ~= "" then
            if confirm == typed then out[#out + 1] = { label = tr("Dangerous command: press Enter again to run it"), glyph = "alert-triangle", danger = true, quiet = true } end
            out[#out + 1] = { label = tr("Run in terminal"), line2 = typed, glyph = "terminal-2", run = function() if confirmed(typed) then run_command(typed) end end, keep = true }
        else
            out[#out + 1] = { label = tr("Open terminal"), glyph = "terminal-2", run = function() after(80, open.terminal) end }
            for i, c in ipairs(kept.commands) do
                if i == 1 then out[#out + 1] = { head = true, label = tr("RECENTLY USED"), line = true } end
                out[#out + 1] = { label = c, glyph = "history", run = function() if confirmed(c) then run_command(c) end end, keep = true }
            end
        end
        return out
    end
    if typed ~= "" then
        for _, a in ipairs(find(apps, typed, 8)) do
            out[#out + 1] = { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", hint = tr("App"), run = function() launch(a) end }
        end
        if #out == 0 then out[1] = { label = tr("Nothing found"), glyph = "search", quiet = true } end
        return out
    end
    -- nothing typed: the apps used last, and failing that the first ones there are
    local tiles, seen = {}, {}
    for _, id in ipairs(kept.recent) do
        local a = by_id[id]
        if a and not seen[id] and #tiles < 18 then seen[id] = true tiles[#tiles + 1] = tile(a) end
    end
    local head = N("RECENTLY USED")
    if #tiles == 0 then
        head = N("APPLICATIONS")
        for i = 1, math.min(18, #apps) do tiles[i] = tile(apps[i]) end
    end
    return { { head = true, label = tr(head) }, { tiles = tiles, per = 6 } }
end

local function set_mode(m)
    if kept.mode == m then return end
    kept.mode, typed, confirm = m, "", nil
    save()
    card.text("")
    render(false)
end

render = function(keep)
    local tabs = {}
    for m = 0, #MODES do
        tabs[#tabs + 1] = { label = tr(MODES[m].name), glyph = MODES[m].glyph, on = kept.mode == m, run = function() set_mode(m) end }
    end
    card.open(rows(), {
        owner = owner, id = "lens", width = WIDTH, keep = keep, tabs = tabs, min_height = 330,
        field = {
            hint = tr(MODES[kept.mode].hint), text = typed,
            change = function(t)
                t = t:gsub("^%s+", ""):gsub("%s+$", "")
                if t == typed then return end
                typed, confirm = t, nil
                render(true)
            end,
            -- Enter: the first thing found; a command runs as typed
            submit = function(t)
                if kept.mode == 1 then
                    if confirmed(t) then run_command(t) end
                    return true
                end
                local first = find(apps, t, 1)[1]
                if first then launch(first) end
                return first == nil
            end,
        },
    })
end

function M.open(m)
    if m and MODES[m] then kept.mode = m end
    typed, confirm = "", nil
    render(false)
end
function M.toggle()
    if card.id() == "lens" then card.close() else M.open() end
end
-- the right button: the apps used last, to start one with a single press
function M.quick()
    local tiles = {}
    for _, id in ipairs(kept.recent) do
        local a = by_id[id]
        if a and #tiles < 8 then tiles[#tiles + 1] = tile(a) end
    end
    local out = {}
    if #tiles > 0 then
        out[#out + 1] = { head = true, label = tr("RECENTLY USED") }
        out[#out + 1] = { tiles = tiles, per = 4 }
    end
    out[#out + 1] = { label = tr("Search…"), glyph = "search", line = #tiles > 0, run = function() after(60, M.open) end }
    card.open(out, { owner = owner, id = "quick", width = 300 })
end

function M.start(d)
    owner = d
    local ok, saved = pcall(sys.ask, "files.read", FILE, "json")
    if ok and type(saved) == "table" then
        kept.mode = MODES[saved.mode] and saved.mode or 0
        kept.recent = type(saved.recent) == "table" and saved.recent or {}
        kept.commands = type(saved.commands) == "table" and saved.commands or {}
    end
    sys.watch("apps", function(list)
        apps, by_id = list or {}, {}
        for _, a in ipairs(apps) do if a.id then by_id[a.id] = a end end
        if card.id() == "lens" then render(true) end
    end)
    on("lens_toggle", M.toggle)
    on("lens_mode", function(m) M.open(m) end)
end

return M
