-- The desktop (parts/desk.plm): the Recycle Bin and what is in the user's Desktop folder, as icons over the wallpaper,
-- used the way a desktop is on Windows; without icons (Settings › Background) only the desktop's own menu. The files
-- are moved by `latte-files`, as in DualBrew (one Ctrl+Z for both); `latte-desktop` lists them, says when they change
-- and opens them. Here is only what is where and what a press, a key or a drop does. What the user chose (size of the icons, order, where each one lies) is kept
-- in ~/.config/latteos/desktop.json, as apps/desktop.qml kept it before it was replaced (ROADMAP 7B.05).
local ctx = require("lib/ctx")
local open = require("lib/open")

local M = {}

local MAX = 128                                -- what parts/desk.plm's model holds
local EDGE = 12                                -- from the screen's edge to the first cell
local SIZES = { small = { 84, 78, 36, 11 }, medium = { 104, 98, 52, 12 }, large = { 136, 128, 76, 12 },
                xlarge = { 176, 166, 112, 13 }, huge = { 236, 220, 164, 14 } }       -- a cell, its picture, its letters

local folder, trash, trashed = "", "", 0
local files = {}                               -- { path, name, dir, icon, size, date }
local prefs = { size = "medium", auto = false, sort = "name", reversed = false, at = {} }
local saved = ""                               -- where prefs are kept
local chosen = {}                              -- path → true
local places = {}                              -- path → { column, row }
local shown = {}                               -- the model's order: place → path
local last_press, last_at = -1, 0              -- for twice: the icon pressed last and when
local clock = 0                                -- milliseconds, counted by a timer (the logic has no clock)

local function key(p) return p == trash and "::trash" or p:match("[^/]*$") end
local function size() return SIZES[prefs.size] or SIZES.medium end
local function is_dir(p)
    if p == trash then return true end
    for _, f in ipairs(files) do if f.path == p then return f.dir end end
    return false
end
local function picked()
    local out = {}
    for _, p in ipairs(shown) do if chosen[p] and p ~= trash then out[#out + 1] = p end end
    return out
end
local function cat(args) local out = { "-c", args[1], "sh" }; for i = 2, #args do out[#out + 1] = args[i] end; return out end

local function keep()
    if saved ~= "" then run("sh", cat({ 'mkdir -p "${1%/*}" && printf "%s" "$2" > "$1"', saved, json.encode(prefs) }), nil) end
end

-- what the scene shows: one record a icon, where it lies and how it looks now
local function publish()
    local s, out = size(), {}
    local many = picked()
    local carried = table.concat(many, "\n")
    for i, p in ipairs(shown) do
        if i > MAX then break end
        local f, at = nil, places[p] or { 0, 0 }
        for _, g in ipairs(files) do if g.path == p then f = g; break end end
        local name, icon = tr("Recycle Bin"), trashed > 0 and "user-trash-full" or "user-trash"
        if f then name, icon = f.name, f.icon end
        -- the picture under the pointer while it is carried: only a PNG will do, so a picture that is one
        -- ponytail: icons of the theme are SVG, carried without a picture; rasterise them once if it is missed
        out[i] = { label = name, icon = icon, has_icon = icon ~= "", pic = icon:match("^/.*%.png$") and icon or "",
                   x = EDGE + at[1] * s[1], y = EDGE + at[2] * s[2], picked = chosen[p] == true,
                   into = p == trash or (f ~= nil and f.dir), badge = tostring(trashed), has_badge = p == trash and trashed > 0,
                   carry = p == trash and "" or (chosen[p] and carried or p) }
    end
    model.dfile = out
    fact.dk_cw, fact.dk_ch, fact.dk_pic, fact.dk_font = s[1], s[2], s[3], s[4]
end

-- The Recycle Bin first, then the files: where the user put them, or the next free cell down the columns.
local function arrange()
    local s = size()
    local rows = math.max(1, math.floor(((tonumber(fact.sh) or 1080) - 2 * EDGE) / s[2]))
    local list = {}
    for _, f in ipairs(files) do list[#list + 1] = f end
    local by = prefs.sort
    table.sort(list, function(a, b)
        if a.dir ~= b.dir then return a.dir end
        local x, y
        if by == "size" then x, y = a.size, b.size
        elseif by == "kind" then x, y = a.icon, b.icon
        elseif by == "date" then x, y = a.date, b.date
        else x, y = a.name:lower(), b.name:lower() end
        if x == y then x, y = a.name:lower(), b.name:lower() end
        if prefs.reversed then return x > y end
        return x < y
    end)
    shown = { trash }
    for _, f in ipairs(list) do shown[#shown + 1] = f.path end
    local used, out = {}, {}
    if not prefs.auto then
        for _, p in ipairs(shown) do
            local at = prefs.at[key(p)] or (p == trash and { 0, 0 } or nil)
            if at and at[2] < rows and not used[at[1] .. ":" .. at[2]] then out[p] = at; used[at[1] .. ":" .. at[2]] = true end
        end
    end
    for _, p in ipairs(shown) do
        if not out[p] then
            local c, r = 0, 0
            while used[c .. ":" .. r] do r += 1; if r >= rows then r = 0; c += 1 end end
            out[p] = { c, r }; used[c .. ":" .. r] = true
        end
    end
    places = out
    fact.dk_rows = rows
    publish()
end

local function reload()
    run("latte-desktop", { "list" }, function(out)
        local list = {}
        for line in (out or ""):gmatch("[^\n]+") do
            local a, b, c, d, e, f = line:match("^([^\t]*)\t([^\t]*)\t?([^\t]*)\t?([^\t]*)\t?([^\t]*)\t?([^\t]*)")
            if a == "#" then folder, trashed = b, tonumber(c) or 0
            elseif a then list[#list + 1] = { path = a, name = b, dir = c == "1", icon = d or "", size = tonumber(e) or 0, date = tonumber(f) or 0 } end
        end
        files = list
        for p in pairs(chosen) do
            local there = p == trash
            for _, g in ipairs(files) do if g.path == p then there = true end end
            if not there then chosen[p] = nil end
        end
        arrange()
    end)
end

-- latte-files does it, as for DualBrew, then the icons are read again (the watch would tell too, a moment later)
local function act(args) run("latte-files", args, function() reload() end) end
local function with(args, paths) for _, p in ipairs(paths) do args[#args + 1] = p end; return args end
local function to_trash(paths) if #paths > 0 then act(with({ "trash" }, paths)); chosen = {} end end
-- how: move, or auto (moved on the same disk, copied from another, as DualBrew lets go of files)
local function into(how, paths, dir)
    if #paths == 0 then return end
    act(how == "auto" and with({ "job", "auto", dir }, paths) or with({ how, dir }, paths)); chosen = {}
end
local function open_all(paths) if #paths > 0 then run("latte-desktop", with({ "open" }, paths), nil) end end

local function choose(p) chosen = {}; if p then chosen[p] = true end; publish() end
local function set(k, v) prefs[k] = v; keep(); arrange() end

-- icons dragged to other cells: all of them by the same step, each to the nearest cell that is free
local function carry(paths, dc, dr)
    local rows, taken, moving = tonumber(fact.dk_rows) or 1, {}, {}
    for _, p in ipairs(paths) do moving[p] = true end
    -- the others stay where they are now, as on Windows: none moves up into the cell let go
    for p, at in pairs(places) do if not moving[p] then taken[at[1] .. ":" .. at[2]] = true; prefs.at[key(p)] = at end end
    for _, p in ipairs(shown) do
        if moving[p] then
            local at = places[p]
            local c, r = math.max(0, at[1] + dc), math.clamp(at[2] + dr, 0, rows - 1)
            while taken[c .. ":" .. r] do r += 1; if r >= rows then r = 0; c += 1 end end
            taken[c .. ":" .. r] = true
            prefs.at[key(p)] = { c, r }
        end
    end
    prefs.auto = false
    keep(); arrange()
end

-- ── renaming (ROADMAP 10L.02, as Nautilus): a small Goo card grown from the icon, the name chosen without its ending
-- (a folder's all of it), Rename or Enter keeps it, Escape or a press elsewhere leaves it as it was. F2 or the menu only.
local card = require("lib/card")
local function rename(p, name)
    name = (name or ""):match("^%s*(.-)%s*$")
    local old = p:match("[^/]*$")
    if name == "" or name == old then return end
    if not p:match("%.desktop$") and prefs.at[old] then prefs.at[name] = prefs.at[old]; prefs.at[old] = nil; keep() end
    -- what was renamed stays chosen, as on Windows: F2 or Enter next goes to it
    if p:match("%.desktop$") then run("latte-desktop", { "name", p, name }, function() reload() end); return end
    chosen = { [p:match("^(.*)/") .. "/" .. name] = true }
    act({ "rename", p, name })
end
local function rename_start(p)
    if not p or p == trash then return end
    local f
    for _, g in ipairs(files) do if g.path == p then f = g end end
    if not f then return end
    choose(p)
    -- the card grows from the icon, whether the menu or F2 asked
    local at, s = places[p], size()
    if at then fact["tap.x"], fact["tap.y"] = EDGE + at[1] * s[1] + s[1] / 2, EDGE + at[2] * s[2] + s[3] + 10 end
    local done = function(t) card.close(); rename(p, t); return false end
    card.open({
        { head = true, label = f.dir and tr("Rename folder") or tr("Rename file") },
        { pills = { { label = tr("Rename"), glyph = "pencil", run = function() done(card.text()) end } } },
    }, { id = "desk-rename", width = 300,
         field = { text = f.name, hint = tr("Name"), select = (f.dir or p:match("%.desktop$")) and "all" or "stem", submit = done } })
end

-- Properties: a window of its own (goo/props.plm), the same one DualBrew and every app open (ROADMAP 10L.01)
local function properties(paths) if #paths > 0 then run("latte-properties", paths, nil, { output = false }) end end

-- ── the menus ──────────────────────────────────────────────────────────────────────────────────────────────────
local function bare_menu()
    local ok, home = pcall(sys.ask, "env", "HOME")
    ctx.open({
        { label = tr("Files"), glyph = "folder", run = function() open.path(ok and home or "/") end },
        { label = tr("Open in terminal"), glyph = "terminal-2", run = function() open.terminal() end },
        { label = tr("Display settings"), glyph = "device-desktop", line = true, run = function() open.settings("displays") end },
        { label = tr("Wallpaper"), glyph = "photo", run = function() open.settings("background") end },
        { label = tr("Personalize"), glyph = "palette", run = function() open.settings("coffee") end },
        { label = tr("Drops"), glyph = "droplet", run = function() open.settings("drops") end },
        { label = tr("Monitor"), glyph = "activity", line = true, keys = "Ctrl+Shift+Esc", run = function() open.monitor() end },
        { label = tr("All settings…"), glyph = "settings", keys = "Win+I", run = function() open.settings() end },
    }, { width = 290 })
end

local function desktop_menu()
    local function big(id, label) return { label = label, on = prefs.size == id, run = function() set("size", id) end } end
    local function by(id, label) return { label = label, on = prefs.sort == id, run = function() prefs.auto = true; set("sort", id) end } end
    ctx.open({
        { label = tr("View"), glyph = "layout-grid", sub = {
            big("huge", tr("Huge icons")), big("xlarge", tr("Extra large icons")), big("large", tr("Large icons")),
            big("medium", tr("Medium icons")), big("small", tr("Small icons")),
            { label = tr("Auto arrange icons"), line = true, on = prefs.auto, run = function() set("auto", not prefs.auto) end },
            { label = tr("Show desktop icons"), on = true, run = function() run("latte-desktop", { "off" }, nil) end } } },
        { label = tr("Sort by"), glyph = "arrows-sort", sub = {
            by("name", tr("Name")), by("size", tr("Size")), by("kind", tr("Item type")), by("date", tr("Date modified")),
            { label = tr("Descending"), line = true, on = prefs.reversed, run = function() set("reversed", not prefs.reversed) end } } },
        { label = tr("Refresh"), glyph = "refresh", keys = "F5", run = reload },
        { label = tr("Undo"), glyph = "arrow-back-up", keys = "Ctrl+Z", run = function() act({ "undo" }) end },
        { label = tr("Paste"), glyph = "clipboard", line = true, keys = "Ctrl+V", run = function() act({ "paste", folder }) end },
        { label = tr("New"), glyph = "plus", sub = {
            { label = tr("Folder"), glyph = "folder-plus", run = function() M.create("folder", tr("New folder")) end },
            { label = tr("Text Document"), glyph = "file-text", run = function() M.create("file", tr("New Text Document") .. ".txt") end } } },
        { label = tr("Display settings"), glyph = "device-desktop", line = true, run = function() open.settings("displays") end },
        { label = tr("Personalize"), glyph = "palette", run = function() open.settings("coffee") end },
        { label = tr("Wallpaper"), glyph = "photo", run = function() open.settings("background") end },
        { label = tr("Open in terminal"), glyph = "terminal-2", line = true, run = function() run("sh", cat({ 'cd "$1" && exec foot', folder }), nil, { output = false }) end },
    }, { width = 290 })
end

local function icon_menu(p, apps)
    if p == trash then
        ctx.open({
            { label = tr("Open"), glyph = "external-link", run = function() open_all({ trash }) end },
            { label = tr("Empty Recycle Bin"), glyph = "trash", danger = true, run = function() if trashed > 0 then act({ "empty" }) end end },
        }, { width = 270 })
        return
    end
    if apps == nil and not is_dir(p) and not p:match("%.desktop$") then
        run("latte-desktop", { "openers", p }, function(out)
            local list = {}
            for id, name in (out or ""):gmatch("([^\t\n]+)\t([^\n]+)") do
                if #list < 8 then list[#list + 1] = { label = name, run = function() run("gtk-launch", { id, p }, nil, { output = false }) end } end
            end
            icon_menu(p, list)
        end)
        return
    end
    local many = #picked() > 1
    local rows = { { label = tr("Open"), glyph = "external-link", keys = "Enter", run = function() open_all(picked()) end } }
    if apps and #apps > 0 and not many then rows[#rows + 1] = { label = tr("Open with"), glyph = "apps", sub = apps } end
    rows[#rows + 1] = { label = tr("Cut"), glyph = "cut", line = true, keys = "Ctrl+X", run = function() M.clip("cut") end }
    rows[#rows + 1] = { label = tr("Copy"), glyph = "copy", keys = "Ctrl+C", run = function() M.clip("copy") end }
    rows[#rows + 1] = { label = tr("Copy as path"), glyph = "clipboard", run = function() run("wl-copy", { "--", table.concat(picked(), "\n") }, nil) end }
    if not many then rows[#rows + 1] = { label = tr("Rename"), glyph = "pencil", line = true, keys = "F2", run = function() rename_start(p) end } end
    rows[#rows + 1] = { label = tr("Delete"), glyph = "trash", danger = true, line = many, keys = "Del", run = function() to_trash(picked()) end }
    rows[#rows + 1] = { label = tr("Properties"), glyph = "info-circle", line = true, keys = "Alt+Enter", run = function() properties(picked()) end }
    ctx.open(rows, { width = 290 })
end

function M.clip(how) local l = picked(); if #l > 0 then run("latte-files", with({ "clip", how }, l), nil) end end
-- a new folder or file, and its name ready to be typed, as on Windows
function M.create(kind, name)
    run("latte-files", { kind, folder, name }, function(out)
        local made = (out or ""):match("[^\n]+")
        reload()
        if made then after(400, function() rename_start(made) end) end
    end)
end

-- something let go over the desktop: files from an app, or the desktop's own icons carried by the compositor
local function dropped(data)
    local paths = {}
    for line in (data or ""):gmatch("[^\r\n]+") do
        local p = line:match("^file://(.*)$")
        if p then paths[#paths + 1] = p:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end) end
    end
    if #paths == 0 or folder == "" then return end
    local onto = shown[(tonumber(fact.dk_onto) or -1) + 1]
    fact.dk_onto = -1
    local ours = true
    for _, p in ipairs(paths) do if p:match("^(.*)/") ~= folder then ours = false end end
    local self_drop = false
    for _, p in ipairs(paths) do if p == onto then self_drop = true end end
    if onto == trash then to_trash(paths)
    elseif onto and is_dir(onto) and not self_drop then into(ours and "move" or "auto", paths, onto)
    elseif ours then
        local from = shown[last_press + 1]
        local at = from and places[from]
        if at then
            local s = size()
            local c = math.floor(((tonumber(fact.dk_dropx) or 0) - EDGE) / s[1])
            local r = math.floor(((tonumber(fact.dk_dropy) or 0) - EDGE) / s[2])
            carry(paths, c - at[1], r - at[2])
        end
    else into("auto", paths, folder) end
end

-- main: the scene of the monitor the icons are on; the others keep only the desktop's menu
function M.start(main)
    on("desk_menu", function() if main and fact.desk_icons then desktop_menu() else bare_menu() end end)
    if not main then return end
    run("sh", { "-c", 'printf "%s\\n%s" "${XDG_CONFIG_HOME:-$HOME/.config}/latteos/desktop.json" "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files"' }, function(out)
        local a, b = (out or ""):match("^([^\n]*)\n(.*)$")
        saved, trash = a or "", b or ""
        run("cat", { saved }, function(text_)
            local ok, p = pcall(json.decode, text_ or "")
            if ok and type(p) == "table" then for k, v in pairs(p) do prefs[k] = v end end
            if type(prefs.at) ~= "table" then prefs.at = {} end
            reload()
        end)
    end)
    run("latte-desktop", { "status" }, function(out) fact.desk_icons = (out or ""):match("^on") ~= nil end)
    local pending = false
    spawn("latte-desktop", { "watch" }, function()
        if pending then return end
        pending = true
        after(250, function() pending = false; reload() end)
    end)
    every(100, function() clock += 100 end)
    on("fact:sw", arrange)
    on("fact:sh", arrange)

    on("dk_press", function(i)
        local p = shown[(i or -1) + 1]
        if not p then return end
        if last_press == i and clock - last_at <= 500 then open_all(chosen[p] and (p == trash and { trash } or picked()) or { p }); last_press = -1; return end
        last_press, last_at = i, clock
        if not chosen[p] then choose(p) end
    end)
    on("dk_menu", function(i)
        local p = shown[(i or -1) + 1]
        if not p then return end
        if not chosen[p] then choose(p) end
        icon_menu(p)
    end)
    on("dk_bare", function() choose(nil) end)
    -- the rectangle drawn over the bare desktop chooses what it touches, as it is drawn
    on("fact:dk_bw", function()
        local x0, y0, w, h = tonumber(fact.dk_bx) or 0, tonumber(fact.dk_by) or 0, tonumber(fact.dk_bw) or 0, tonumber(fact.dk_bh) or 0
        if (tonumber(fact.dk_band) or 0) == 0 or (w < 4 and h < 4) then return end      -- let go: what it chose stays
        local s, out = size(), {}
        for _, p in ipairs(shown) do
            local at = places[p]
            local ix, iy = EDGE + at[1] * s[1], EDGE + at[2] * s[2]
            if ix < x0 + w and ix + s[1] > x0 and iy < y0 + h and iy + s[2] > y0 then out[p] = true end
        end
        chosen = out; publish()
    end)
    on("dk_key", function(k)
        local one = picked()
        if k == 1 then if #one == 1 then rename_start(one[1]) end
        elseif k == 2 then to_trash(one)
        elseif k == 3 then open_all(chosen[trash] and #one == 0 and { trash } or one)
        elseif k == 4 then properties(one)
        elseif k == 5 then chosen = {}; for _, p in ipairs(shown) do if p ~= trash then chosen[p] = true end end; publish()
        elseif k == 6 then M.clip("copy")
        elseif k == 7 then M.clip("cut")
        elseif k == 8 then act({ "paste", folder })
        elseif k == 9 then reload()
        elseif k == 10 then choose(nil)
        elseif k == 11 then act({ "undo" }) end
    end)
    -- the logic hears the drop from the zone on top only: the bare desktop, or an icon
    on("drop:desk_hit", function(data) after(40, function() dropped(data) end) end)
    on("drop:dk_hit", function(data) after(40, function() dropped(data) end) end)
    on("fact:desk_icons", function() if not fact.desk_icons then choose(nil) end end)
end

return M
