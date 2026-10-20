-- The launcher: the card LensGoo opens. What is typed is searched for in the mode the tabs choose:
--   Applications   with nothing typed: the most launched, the favourites (QuickGoo's) and the newly installed, under
--                  a row of filters, in glass above a divider of coffee with the count below it; typing finds apps, works out a line of
--                  arithmetic, and offers to take the text to the files or to the web
--   Files          with nothing typed the home folders; typing finds files and folders by name (fd)
--   Web            an address opens; anything else goes to a search engine, the user's own first
--   Command        a line for the terminal, which stays open afterwards; a dangerous one asks once more
-- Enter takes the first row. A mode is one entry in MODES with its rows.
-- The mode, the apps used last, the commands run and the search engine are kept in lens.json in the scene's folder.
local card = require("lib/card")
local find = require("lib/find")
local calc = require("lib/calc")
local dangerous = require("lib/dangerous")
local open = require("lib/open")
local own = require("lib/own")
local quick = require("drops/quickgoo")
local M = {}
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local WIDTH = 600
local FILE = "lens.json"
local ENGINES = {
    { id = "duckduckgo", name = "DuckDuckGo", url = "https://duckduckgo.com/?q=%s" },
    { id = "google", name = "Google", url = "https://www.google.com/search?q=%s" },
    { id = "bing", name = "Bing", url = "https://www.bing.com/search?q=%s" },
    { id = "startpage", name = "Startpage", url = "https://www.startpage.com/do/search?q=%s" },
    { id = "ecosia", name = "Ecosia", url = "https://www.ecosia.org/search?q=%s" },
    { id = "brave", name = "Brave Search", url = "https://search.brave.com/search?q=%s" },
}
-- the user's folders, by the names xdg-user-dir knows them by
local FOLDERS = { { key = "DOCUMENTS", name = N("Documents"), glyph = "file" }, { key = "DOWNLOAD", name = N("Downloads"), glyph = "arrow-right" },
                  { key = "PICTURES", name = N("Pictures"), glyph = "sun" }, { key = "MUSIC", name = N("Music"), glyph = "volume" },
                  { key = "VIDEOS", name = N("Videos"), glyph = "player-play" } }

local apps, by_id = {}, {}
local kept = { mode = 0, recent = {}, commands = {}, engine = "duckduckgo", counts = {}, filter = "all", fav = {},
              layout = { most = true, fav = true, fresh = true, chips = true }, off = {} }
local born = {}                      -- app id → when it was installed (the birth of its .desktop file)
-- the filters of the app overview: which desktop categories each takes
local FILTERS = {
    { id = "all", name = N("All"), glyph = "apps" },
    { id = "work", name = N("Work"), glyph = "star", cats = { "Office", "Utility", "Network", "Education" } },
    { id = "media", name = N("Media"), glyph = "palette", cats = { "AudioVideo", "Audio", "Video", "Graphics" } },
    { id = "dev", name = N("Develop"), glyph = "code", cats = { "Development" } },
    { id = "fun", name = N("Fun"), glyph = "device-gamepad-2", cats = { "Game" } },
}
local owner                          -- LensGoo
local home, folders = "", {}
local typed, confirm = "", nil       -- what is in the field; the dangerous command asked about
local found, asked = nil, 0          -- the files found for what is typed; which question the answer is to
local pages, pages_for = {}, ""      -- the pages of the Settings that match what is typed; what that was
local render, set_mode

local function save() pcall(sys.call, "files.write", FILE, kept) end
local function short(path) return home ~= "" and path:sub(1, #home) == home and ("~" .. path:sub(#home + 1)) or path end
local function urlencode(s) return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end)) end
local function engine()
    for _, e in ipairs(ENGINES) do if e.id == kept.engine then return e end end
    return ENGINES[1]
end
-- The card lets go of the keyboard first and the thing starts a moment later: a window that opens while the
-- shell still holds the keyboard does not get it when the shell lets go.
local function then_do(f) card.close() after(80, f) end

local function launch(a)
    then_do(function() open.app(a) end)
    if not a.id then return end
    local recent = { a.id }
    for _, id in ipairs(kept.recent) do if id ~= a.id and #recent < 18 then recent[#recent + 1] = id end end
    kept.recent = recent
    kept.counts[a.id] = (kept.counts[a.id] or 0) + 1
    save()
end
local function run_command(cmd)
    local commands = { cmd }
    for _, c in ipairs(kept.commands) do if c ~= cmd and #commands < 12 then commands[#commands + 1] = c end end
    kept.commands = commands
    save()
    then_do(function() open.shell(cmd) end)
end
-- a dangerous command is asked about once: entered again, it runs
local function confirmed(cmd)
    if not dangerous(cmd) or confirm == cmd then return true end
    confirm = cmd
    render(true)
    return false
end
local function search_web(e, text) then_do(function() open.url(string.format(e.url, urlencode(text))) end) end
-- the right button on an app: it can be pinned to the desktop as a drop of its own
local function app_menu(a)
    local pinned = own.pinned(a)
    local loved = table.find(kept.fav, a.id) ~= nil
    card.open({
        { label = loved and tr("Remove from favourites") or tr("Add to favourites"), glyph = "star",
          run = function()
              if loved then table.remove(kept.fav, table.find(kept.fav, a.id)) elseif a.id and #kept.fav < 12 then kept.fav[#kept.fav + 1] = a.id end
              save()
              after(60, function() render(false) end)
          end },
        { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", line = true, run = function() launch(a) end },
        { label = quick.has(a) and tr("Take off QuickGoo") or tr("Keep at hand in QuickGoo"), glyph = "rocket", line = true,
          run = function() if quick.has(a) then quick.remove(a) else quick.add(a) end end },
        { label = pinned and tr("Unpin the drop") or tr("Pin as a drop"), glyph = "pin",
          run = function() if pinned then own.remove(a.id) else own.pin(a) end end },
    }, { owner = owner, id = "lens-app", width = 280 })
end
local function tile(a) return { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", run = function() launch(a) end, right = function() app_menu(a) end } end
local function number(v)
    local s = string.format("%.10g", v)
    return (tr("%d.%d G"):find(",", 1, true) and s:gsub("%.", ",") or s)       -- the decimal mark of the user's language
end

-- ── what each mode shows ─────────────────────────────────────────────────────────────────────────────────────
local function rows_apps()
    if typed == "" then
        local function category(a, f)
            local text = type(a.categories) == "table" and table.concat(a.categories, ";") or tostring(a.categories or "")
            for _, c in ipairs(f.cats or {}) do if (";" .. text .. ";"):find(";" .. c .. ";", 1, true) then return true end end
            return false
        end
        local function row_of(list, n)
            local tiles = {}
            for i = 1, math.min(n, #list) do tiles[i] = tile(list[i]) end
            return { tiles = tiles, per = 6 }
        end
        local rows, filter = {}, FILTERS[1]
        for _, f in ipairs(FILTERS) do if f.id == kept.filter and not kept.off[f.id] then filter = f end end
        if kept.layout.chips then
            local chips = {}
            for _, f in ipairs(FILTERS) do
                if f.id == "all" or not kept.off[f.id] then
                    chips[#chips + 1] = { label = tr(f.name), glyph = f.glyph, on = f.id == filter.id, keep = true,
                                          run = function() kept.filter = f.id save() render(true) end }
                end
            end
            rows[#rows + 1] = { pills = chips, per = 6 }
        end
        -- what passes the filter, the most launched first (then the order of the list)
        local pool = {}
        for _, a in ipairs(apps) do if filter.id == "all" or category(a, filter) then pool[#pool + 1] = a end end
        table.sort(pool, function(x, y) return (kept.counts[x.id or ""] or 0) > (kept.counts[y.id or ""] or 0) end)
        if filter.id == "all" then
            if kept.layout.most then
                local most = {}
                for _, a in ipairs(pool) do if (kept.counts[a.id or ""] or 0) > 0 and #most < 6 then most[#most + 1] = a end end
                if #most == 0 then
                    for _, id in ipairs(kept.recent) do if by_id[id] and #most < 6 then most[#most + 1] = by_id[id] end end
                end
                if #most == 0 then for i = 1, math.min(6, #pool) do most[i] = pool[i] end end
                rows[#rows + 1] = { head = true, label = tr(N("MOST LAUNCHED")) }
                rows[#rows + 1] = row_of(most, 6)
            end
            -- the favourites: the heading stays even when there are none, and says how to add one
            if kept.layout.fav then
                local fav = {}
                for _, id in ipairs(kept.fav) do if by_id[id] and #fav < 6 then fav[#fav + 1] = by_id[id] end end
                rows[#rows + 1] = { head = true, label = tr(N("FAVOURITES")) }
                if #fav > 0 then rows[#rows + 1] = row_of(fav, 6)
                else rows[#rows + 1] = { label = tr("Right-click an app and choose Add to favourites"), glyph = "star", quiet = true } end
            end
            if kept.layout.fresh then
                local fresh = {}
                for _, a in ipairs(apps) do if a.id and born[a.id] then fresh[#fresh + 1] = a end end
                table.sort(fresh, function(x, y) return born[x.id] > born[y.id] end)
                rows[#rows + 1] = { head = true, label = tr(N("NEWLY INSTALLED")) }
                if #fresh > 0 then rows[#rows + 1] = row_of(fresh, 6)
                else rows[#rows + 1] = { label = tr("Nothing installed lately"), glyph = "clock", quiet = true } end
            end
        else
            rows[#rows + 1] = { head = true, label = tr(filter.name):upper() }
            rows[#rows + 1] = row_of(pool, 18)
        end
        -- under the glass: the coffee, with a way to edit this page and how many apps there are
        rows[#rows + 1] = { wave = true }
        rows[#rows + 1] = { label = tr("Customize this page"), glyph = "adjustments-horizontal", hint = string.format(tr("%d apps"), #apps), keep = true, more = true,
                            run = function() M.customize() end }
        return rows
    end
    local rows = {}
    local result = calc(typed)
    if result then
        local shown = number(result)
        rows[#rows + 1] = { label = shown, glyph = "calculator", hint = tr("click copies"), run = function() pcall(sys.call, "clipboard.set", shown) end }
    end
    for _, a in ipairs(find(apps, typed, 7)) do
        rows[#rows + 1] = { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", hint = tr("App"), run = function() launch(a) end, right = function() app_menu(a) end }
    end
    -- under a line: what the Settings have about it
    for i, p in ipairs(pages_for == typed and pages or {}) do
        if i > 4 then break end
        rows[#rows + 1] = { label = p.name, glyph = p.icon, hint = tr("Settings") .. " · " .. p.area_name, line = i == 1,
                            run = function() then_do(function() open.settings(p.page) end) end }
    end
    -- the same text, taken elsewhere
    local text = typed
    rows[#rows + 1] = { label = tr("Search files") .. ": " .. text, glyph = "folder", line = #rows > 0, keep = true, run = function() set_mode(1, true) end }
    rows[#rows + 1] = { label = tr("Search the web") .. ": " .. text, glyph = "world", hint = engine().name, run = function() search_web(engine(), text) end }
    return rows
end

-- the Settings' pages that are about what is typed (bin/latte-settings knows them, in the user's language too)
local function look_for_settings()
    local text = typed
    if #text < 2 then pages, pages_for = {}, text return end
    run("latte-settings", { "find", text }, function(out)
        if text ~= typed then return end                  -- something else has been typed since
        local ok, list = pcall(json.decode, out or "")
        pages, pages_for = ok and type(list) == "table" and list or {}, text
        if card.id() == "lens" and kept.mode == 0 and #pages > 0 then render(true) end
    end)
end

local function look_for_files()
    asked += 1
    local mine, text = asked, typed
    found = nil
    if text == "" or home == "" then return end
    run("fd", { "--max-results", "10", "--absolute-path", "--ignore-case", "--", text, home }, function(out)
        if mine ~= asked then return end                 -- something else has been typed since
        found = {}
        for path in (out or ""):gmatch("[^\n]+") do found[#found + 1] = path end
        if card.id() == "lens" and kept.mode == 1 then render(true) end
    end)
end
local function rows_files()
    local rows = {}
    if typed == "" then
        rows[1] = { label = tr("Home"), glyph = "home-2", hint = "~", run = function() then_do(function() open.path(home) end) end }
        for _, f in ipairs(folders) do
            rows[#rows + 1] = { label = tr(f.name), glyph = f.glyph, hint = short(f.path), run = function() then_do(function() open.path(f.path) end) end }
        end
        return rows
    end
    for _, path in ipairs(found or {}) do
        local folder = path:sub(-1) == "/"
        local clean = folder and path:sub(1, -2) or path
        local parent = clean:match("^(.*)/[^/]*$") or "/"
        rows[#rows + 1] = { label = clean:match("([^/]+)$") or clean, glyph = folder and "folder" or "file", hint = short(parent),
                            run = function() then_do(function() open.path(clean) end) end,
                            right = function() then_do(function() open.path(parent) end) end }
    end
    if #rows == 0 then rows[1] = { label = found and tr("Nothing found") or tr("Searching…"), glyph = "search", quiet = true } end
    return rows
end

local function rows_web()
    local rows, default = {}, engine()
    if typed == "" then
        -- the engines: a press makes one the user's own
        for _, e in ipairs(ENGINES) do
            rows[#rows + 1] = { label = e.name, glyph = "world", on = e.id == default.id, keep = true, run = function() kept.engine = e.id save() render(true) end }
        end
        return rows
    end
    local text = typed
    if text:match("^[%w%-]+%.[%w%-%.]+[/%S]*$") or text:match("^%a+://%S+$") then
        local url = text:match("^%a+://") and text or ("https://" .. text)
        rows[#rows + 1] = { label = tr("Open") .. " " .. text, glyph = "world-www", run = function() then_do(function() open.url(url) end) end }
    end
    rows[#rows + 1] = { label = default.name .. ": " .. text, glyph = "search", run = function() search_web(default, text) end }
    for _, e in ipairs(ENGINES) do
        if e.id ~= default.id then rows[#rows + 1] = { label = e.name .. ": " .. text, glyph = "world", line = #rows == (rows[1].glyph == "world-www" and 2 or 1), run = function() search_web(e, text) end } end
    end
    return rows
end

local function rows_command()
    local rows = {}
    if typed ~= "" then
        if confirm == typed then rows[#rows + 1] = { label = tr("Dangerous command: press Enter again to run it"), glyph = "alert-triangle", danger = true, quiet = true } end
        local cmd = typed
        rows[#rows + 1] = { label = tr("Run in terminal"), line2 = cmd, glyph = "terminal-2", keep = true, run = function() if confirmed(cmd) then run_command(cmd) end end }
        return rows
    end
    rows[1] = { label = tr("Open terminal"), glyph = "terminal-2", run = function() after(80, open.terminal) end }
    for i, c in ipairs(kept.commands) do
        if i == 1 then rows[#rows + 1] = { head = true, label = tr("RECENTLY USED"), line = true } end
        rows[#rows + 1] = { label = c, glyph = "history", keep = true, run = function() if confirmed(c) then run_command(c) end end }
    end
    return rows
end

-- ── AI: a conversation in the card. Who answers is latte-ai's to know; the mode is there only if somebody does ──
local ai = { providers = {}, at = 1, talk = {}, waiting = nil }
local function ask(question)
    local p = ai.providers[ai.at]
    if not p or ai.waiting then return end
    ai.talk[#ai.talk + 1] = { role = "user", content = question }
    while #ai.talk > 8 do table.remove(ai.talk, 1) end           -- what it is reminded of: the last four turns
    local lines = {}
    ai.waiting = spawn("latte-ai", { "ask", p.id, json.encode(ai.talk) }, function(line) lines[#lines + 1] = line end, function()
        ai.waiting = nil
        ai.talk[#ai.talk + 1] = { role = "assistant", content = table.concat(lines, "\n") }
        if card.id() == "lens" and kept.mode == 4 then render(true) end
    end)
    typed = ""
    card.text("")
    render(true)
end
-- an answer as bubbles, a few paragraphs each: a bubble holds fourteen lines
local function bubbles(answer)
    local out, now = {}, ""
    for part in (answer .. "\n\n"):gmatch("(.-)\n%s*\n") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if part ~= "" then
            if now ~= "" and #now + #part > 600 then out[#out + 1] = now now = "" end
            now = now == "" and part or (now .. "\n\n" .. part)
        end
    end
    if now ~= "" then out[#out + 1] = now end
    local rows = {}
    for i = 1, math.min(#out, 4) do rows[i] = { para = true, label = (#out[i] > 900 and (out[i]:sub(1, 900) .. " …") or out[i]) .. ((i == 4 and #out > 4) and " …" or "") } end
    return rows
end
local function rows_ai()
    local p = ai.providers[ai.at]
    if not p then
        return { { label = tr("No AI on this computer"), glyph = "sparkles", quiet = true },
                 { label = tr("Settings") .. " › AI", glyph = "settings", line = true, run = function() then_do(function() open.settings("ai") end) end } }
    end
    local rows = {}
    if typed ~= "" and not ai.waiting then
        local question = typed
        rows[#rows + 1] = { label = tr("Ask") .. ": " .. question, glyph = "sparkles", keep = true, run = function() ask(question) end }
    end
    -- who answers, and whether the question leaves this computer; a press takes the next one there is
    rows[#rows + 1] = { label = p.name, glyph = p["local"] and "device-desktop" or "cloud", hint = p["local"] and tr("on this computer") or tr("online service"),
                        quiet = #ai.providers < 2, keep = true, run = function() ai.at = ai.at % #ai.providers + 1 render(true) end }
    local question, answer
    for _, m in ipairs(ai.talk) do if m.role == "user" then question, answer = m.content, nil else answer = m.content end end
    if question then rows[#rows + 1] = { label = question, glyph = "user", quiet = true, line = true } end
    if ai.waiting then
        rows[#rows + 1] = { para = true, label = tr("Thinking…") }
    elseif answer then
        for _, r in ipairs(bubbles(answer)) do rows[#rows + 1] = r end
        rows[#rows + 1] = { label = tr("Copy the answer"), glyph = "copy", keep = true, line = true, run = function() pcall(sys.call, "clipboard.set", answer) end }
        rows[#rows + 1] = { label = tr("New conversation"), glyph = "plus", keep = true, run = function() ai.talk = {} render(true) end }
    end
    return rows
end

-- ── editing the apps page: which parts it has, which filters, and the favourites by hand ─────────────────────
local function toggle(t, key) return function() t[key] = not t[key] save() M.customize() end end
function M.customize()
    local rows = {
        { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() render(false) end },
        { head = true, label = tr("PARTS OF THE PAGE"), line = true },
        { label = tr("The row of filters"), glyph = "adjustments-horizontal", on = kept.layout.chips, keep = true, run = toggle(kept.layout, "chips") },
        { label = tr(N("MOST LAUNCHED")), glyph = "flame", on = kept.layout.most, keep = true, run = toggle(kept.layout, "most") },
        { label = tr(N("FAVOURITES")), glyph = "star", on = kept.layout.fav, keep = true, run = toggle(kept.layout, "fav") },
        { label = tr(N("NEWLY INSTALLED")), glyph = "clock", on = kept.layout.fresh, keep = true, run = toggle(kept.layout, "fresh") },
        { head = true, label = tr("FILTERS"), line = true },
    }
    for _, f in ipairs(FILTERS) do
        if f.id ~= "all" then
            rows[#rows + 1] = { label = tr(f.name), glyph = f.glyph, on = not kept.off[f.id], keep = true,
                                run = function() kept.off[f.id] = not kept.off[f.id] or nil if kept.filter == f.id then kept.filter = "all" end save() M.customize() end }
        end
    end
    rows[#rows + 1] = { head = true, label = tr(N("FAVOURITES")), line = true }
    local any = false
    for i, id in ipairs(kept.fav) do
        local a = by_id[id]
        if a then
            any = true
            rows[#rows + 1] = { label = a.local_name or a.name or id, icon = a.icon or "", glyph = "apps", hint = tr("remove"), keep = true,
                                run = function() table.remove(kept.fav, i) save() M.customize() end }
        end
    end
    if not any then rows[#rows + 1] = { label = tr("Right-click an app and choose Add to favourites"), glyph = "star", quiet = true } end
    rows[#rows + 1] = { label = tr("Settings"), glyph = "settings", line = true, run = function() then_do(function() open.settings() end) end }
    card.open(rows, { owner = owner, id = "lens-custom", width = WIDTH })
end

-- when each app was installed: the birth of its .desktop file (the change, where a file system does not tell)
local function learn_born()
    run("sh", { "-c", "stat -L -c '%W %Y %n' /usr/share/applications/*.desktop /var/lib/flatpak/exports/share/applications/*.desktop "
                      .. "\"$HOME\"/.local/share/flatpak/exports/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop 2>/dev/null" },
        function(out)
            for t, m, path in (out or ""):gmatch("(%d+) (%d+) ([^\n]+)") do
                local id = path:match("([^/]+)%.desktop$")
                local when = tonumber(t) > 0 and tonumber(t) or tonumber(m)
                if id and when > (born[id] or 0) then born[id] = when end
            end
            if card.id() == "lens" and kept.mode == 0 then render(true) end
        end)
end

local MODES = {
    [0] = { glyph = "apps", name = N("Applications"), hint = N("Search apps…"), rows = rows_apps },
    [1] = { glyph = "folder", name = N("Files"), hint = N("Search files…"), rows = rows_files },
    [2] = { glyph = "world", name = N("Web"), hint = N("Search the web…"), rows = rows_web },
    [3] = { glyph = "terminal-2", name = N("Command"), hint = N("Run a command…"), rows = rows_command },
}

-- to another mode; `keep_text` takes what is typed along
set_mode = function(m, keep_text)
    if kept.mode == m then return end
    kept.mode, confirm = m, nil
    if not keep_text then typed = "" end
    save()
    if m == 1 then look_for_files() end
    render(false)
end

local shown = {}
render = function(keep)
    local tabs = {}
    for m = 0, #MODES do
        tabs[#tabs + 1] = { label = tr(MODES[m].name), glyph = MODES[m].glyph, on = kept.mode == m, run = function() set_mode(m) end }
    end
    shown = MODES[kept.mode].rows()
    card.open(shown, {
        owner = owner, id = "lens", width = WIDTH, keep = keep, tabs = tabs, min_height = 330,
        pane = (kept.mode == 0 and typed == "") and 1 or 0,
        field = {
            hint = tr(MODES[kept.mode].hint), text = typed,
            change = function(t)
                t = t:gsub("^%s+", ""):gsub("%s+$", "")
                if t == typed then return end
                typed, confirm = t, nil
                if kept.mode == 1 then look_for_files() end
                if kept.mode == 0 then look_for_settings() end
                render(true)
            end,
            -- Enter: the first row that does something; what was typed stays if nothing did
            submit = function()
                for _, r in ipairs(shown) do
                    if r.run and not r.quiet and not r.off then r.run() return true end
                end
                return true
            end,
        },
    })
end

function M.open(m)
    if m and MODES[m] then kept.mode = m end
    typed, confirm, found = "", nil, nil
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
    card.open(out, { owner = owner, id = "quick-apps", width = 300 })
end

function M.start(d)
    owner = d
    quick.lately(function() return kept.recent end)
    local ok, saved = pcall(sys.ask, "files.read", FILE, "json")
    if ok and type(saved) == "table" then
        kept.mode = MODES[saved.mode] and saved.mode or 0
        kept.recent = type(saved.recent) == "table" and saved.recent or {}
        kept.commands = type(saved.commands) == "table" and saved.commands or {}
        kept.engine = type(saved.engine) == "string" and saved.engine or kept.engine
        kept.counts = type(saved.counts) == "table" and saved.counts or {}
        if type(saved.fav) == "table" then kept.fav = saved.fav end
        if type(saved.layout) == "table" then for k in pairs(kept.layout) do if saved.layout[k] ~= nil then kept.layout[k] = saved.layout[k] == true end end end
        if type(saved.off) == "table" then kept.off = saved.off end
        kept.filter = type(saved.filter) == "string" and saved.filter or "all"
    end
    local got, h = pcall(sys.ask, "env", "HOME")
    home = got and type(h) == "string" and h or ""
    for i, f in ipairs(FOLDERS) do
        run("xdg-user-dir", { f.key }, function(out)
            local path = (out or ""):gsub("%s+$", "")
            if path == "" or path == home then return end
            folders[#folders + 1] = { name = f.name, glyph = f.glyph, path = path, place = i }
            table.sort(folders, function(a, b) return a.place < b.place end)      -- the answers come in any order
        end)
    end
    -- the AI tab is always there; with nobody to answer it says why and where to turn it on
    MODES[4] = { glyph = "sparkles", name = N("AI"), hint = N("Ask anything…"), rows = rows_ai }
    run("latte-ai", { "providers" }, function(out)
        local found_any, list = pcall(json.decode, out or "")
        if found_any and type(list) == "table" then ai.providers = list end
    end)
    sys.watch("apps", function(list)
        apps, by_id = list or {}, {}
        for _, a in ipairs(apps) do if a.id then by_id[a.id] = a end end
        learn_born()
        if card.id() == "lens" then render(true) end
    end)
    on("lens_toggle", M.toggle)
    on("lens_mode", function(m) M.open(m) end)
end

return M
