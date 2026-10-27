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
local icons = require("lib/icons")
local ctx = require("lib/ctx")
local find = require("lib/find")
local calc = require("lib/calc")
local amount = require("lib/amount")
local dangerous = require("lib/dangerous")
local open = require("lib/open")
local own = require("lib/own")
local quick = require("drops/quickgoo")
local drops = require("lib/engine")      -- not `engine`: that is the web search engine below
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

-- The lists of the app overview, each a button in its row of filters. The user's own are kept by the Settings
-- (lens-lists.json: Settings › Launcher); these are what there is before they have changed anything.
local DEFAULT_LISTS = {
    { id = "work", name = N("Work"), builtin = true, on = true, cats = { "Office", "Utility", "Network", "Education" } },
    { id = "media", name = N("Media"), builtin = true, on = true, cats = { "AudioVideo", "Audio", "Video", "Graphics" } },
    { id = "dev", name = N("Develop"), builtin = true, on = true, cats = { "Development" } },
    { id = "fun", name = N("Fun"), builtin = true, on = true, cats = { "Game" } },
}
local GLYPHS = { work = "star", media = "palette", dev = "code", fun = "device-gamepad-2" }
local lists = DEFAULT_LISTS
-- the AI's state (see its part below): load_lists reads which services the choice offers
local ai = { providers = {}, prefer = nil, msgs = {}, usage = {}, waiting = false, choices = {}, files = {} }
local modes_off = {}                 -- the modes the user hid (Settings › Launcher): files 1, web 2, command 3; apps never
local function load_lists()
    local ok, saved = pcall(sys.ask, "files.read", "lens-lists.json", "json")
    lists = ok and type(saved) == "table" and type(saved.lists) == "table" and #saved.lists > 0 and saved.lists or DEFAULT_LISTS
    ai.prefer = ok and type(saved) == "table" and type(saved.ai) == "table" and saved.ai or nil
    modes_off = {}
    for _, m in ipairs(ok and type(saved) == "table" and type(saved.modes_off) == "table" and saved.modes_off or {}) do
        if tonumber(m) and tonumber(m) > 0 then modes_off[tonumber(m)] = true end
    end
end
local function has(list, a)
    for _, id in ipairs(list.apps or {}) do if id == a.id then return true end end
    local text = type(a.categories) == "table" and table.concat(a.categories, ";") or tostring(a.categories or "")
    local auto = false
    for _, c in ipairs(list.cats or {}) do if (";" .. text .. ";"):find(";" .. c .. ";", 1, true) then auto = true end end
    if not auto then return false end
    for _, id in ipairs(list.off or {}) do if id == a.id then return false end end
    return true
end

local apps, by_id = {}, {}
local kept = { mode = 0, recent = {}, commands = {}, engine = "duckduckgo", counts = {}, filter = "all", fav = {},
              layout = { most = true, fav = true, fresh = true, chips = true }, ai = {} }
local born = {}                      -- app id → when it was installed (the birth of its .desktop file)
local owner                          -- LensGoo
local home, folders = "", {}
local typed, confirm = "", nil       -- what is in the field; the dangerous command asked about
local found, asked = nil, 0          -- the files found for what is typed; which question the answer is to
local pages, pages_for = {}, ""      -- the pages of the Settings that match what is typed; what that was
local worked, worked_for = nil, ""   -- an amount in units or money worked out by qalc for what is typed; what that was
local render, set_mode

local function save() pcall(sys.call, "files.write", FILE, kept) end
local function short(path) return home ~= "" and path:sub(1, #home) == home and ("~" .. path:sub(#home + 1)) or path end
local function urlencode(s) return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end)) end
local function engine()
    for _, e in ipairs(ENGINES) do if e.id == kept.engine then return e end end
    return ENGINES[1]
end
-- The card lets go of the keyboard first and the thing starts a moment later: a window that opens while the
-- shell still holds the keyboard does not get it when the shell lets go. The finder's field keeps the keyboard
-- lent 300 ms after the card closes (pleamar's grace for a card that follows), so the start waits it out.
local LET_GO = 350
local function then_do(f) card.close() after(LET_GO, f) end

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
    ctx.open({
        { label = loved and tr("Remove from favourites") or tr("Add to favourites"), glyph = "star",
          run = function()
              if loved then table.remove(kept.fav, table.find(kept.fav, a.id)) elseif a.id and #kept.fav < 12 then kept.fav[#kept.fav + 1] = a.id end
              save()
              render(true)
          end },
        { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", line = true, run = function() launch(a) end },
        { label = quick.has(a) and tr("Take off QuickGoo") or tr("Keep at hand in QuickGoo"), glyph = "rocket", line = true,
          run = function() if quick.has(a) then quick.remove(a) else quick.add(a) end end },
        { label = pinned and tr("Unpin the drop") or tr("Pin as a drop"), glyph = "pin",
          run = function() if pinned then own.remove(a.id) else own.pin(a) end end },
    }, { width = 280 })
end
local function tile(a) return { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", run = function() launch(a) end, right = function() app_menu(a) end } end
local function number(v)
    local s = string.format("%.10g", v)
    return (tr("%d.%d G"):find(",", 1, true) and s:gsub("%.", ",") or s)       -- the decimal mark of the user's language
end

-- ── what each mode shows ─────────────────────────────────────────────────────────────────────────────────────
local function rows_apps()
    if typed == "" then
        local function row_of(list, n)
            local tiles = {}
            for i = 1, math.min(n, #list) do tiles[i] = tile(list[i]) end
            return { tiles = tiles, per = 6 }
        end
        local rows, filter = {}, { id = "all" }
        local shown_lists = {}
        for _, l in ipairs(lists) do if l.on ~= false and #shown_lists < 5 then shown_lists[#shown_lists + 1] = l end end
        for _, l in ipairs(shown_lists) do if l.id == kept.filter then filter = l end end
        local function name_of(l) return l.builtin and tr(l.name) or l.name end
        if kept.layout.chips then
            local chips = { { label = tr("All"), glyph = "apps", on = filter.id == "all", keep = true, run = function() kept.filter = "all" save() render(true) end } }
            for _, l in ipairs(shown_lists) do
                chips[#chips + 1] = { label = name_of(l), glyph = GLYPHS[l.id] or "list", on = l.id == filter.id, keep = true,
                                      run = function() kept.filter = l.id save() render(true) end }
            end
            rows[#rows + 1] = { pills = chips, per = 6 }
        end
        -- what passes the filter, the most launched first (then the order of the list)
        local pool = {}
        for _, a in ipairs(apps) do if filter.id == "all" or has(filter, a) then pool[#pool + 1] = a end end
        table.sort(pool, function(x, y) return (kept.counts[x.id or ""] or 0) > (kept.counts[y.id or ""] or 0) end)
        if filter.id == "all" then
            -- an app is shown once (6B.17): the favourites are the user's own choice, so they keep theirs and the
            -- most launched do without them; the newly installed do without both
            local seen, fav = {}, {}
            if kept.layout.fav then
                for _, id in ipairs(kept.fav) do if by_id[id] and #fav < 6 then fav[#fav + 1] = by_id[id] seen[id] = true end end
            end
            if kept.layout.most then
                local most = {}
                local function take(a) if a and not seen[a.id or ""] and #most < 6 then most[#most + 1] = a end end
                for _, a in ipairs(pool) do if (kept.counts[a.id or ""] or 0) > 0 then take(a) end end
                if #most == 0 then for _, id in ipairs(kept.recent) do take(by_id[id]) end end
                if #most == 0 then for _, a in ipairs(pool) do take(a) end end
                for _, a in ipairs(most) do seen[a.id or ""] = true end
                rows[#rows + 1] = { head = true, label = tr(N("MOST LAUNCHED")) }
                rows[#rows + 1] = row_of(most, 6)
            end
            -- the favourites: the heading stays even when there are none, and says how to add one
            if kept.layout.fav then
                rows[#rows + 1] = { head = true, label = tr(N("FAVOURITES")) }
                if #fav > 0 then rows[#rows + 1] = row_of(fav, 6)
                else rows[#rows + 1] = { label = tr("Right-click an app and choose Add to favourites"), glyph = "star", quiet = true } end
            end
            if kept.layout.fresh then
                local fresh = {}
                for _, a in ipairs(apps) do if a.id and born[a.id] and not seen[a.id] then fresh[#fresh + 1] = a end end
                table.sort(fresh, function(x, y) return born[x.id] > born[y.id] end)
                rows[#rows + 1] = { head = true, label = tr(N("NEWLY INSTALLED")) }
                if #fresh > 0 then rows[#rows + 1] = row_of(fresh, 6)
                else rows[#rows + 1] = { label = tr("Nothing installed lately"), glyph = "clock", quiet = true } end
            end
        else
            rows[#rows + 1] = { head = true, label = name_of(filter):upper() }
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
        rows[#rows + 1] = { label = shown, glyph = "calculator", copy = shown, run = function() pcall(sys.call, "clipboard.set", shown) end }
    elseif worked and worked_for == typed then
        local shown = worked
        rows[#rows + 1] = { label = shown, glyph = "calculator", copy = shown, run = function() pcall(sys.call, "clipboard.set", shown) end }
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

-- An amount in units or money, written loosely and in the user's language ("100 eur to dollars", "15 % of 80"; the words:
-- goo/lang/<code>-amount.json): Qalculate works it out, with the exchange rates of the European Central Bank fetched
-- once a day (6B.06). Without qalc, nothing.
local amount_words = {}
local function look_for_amount()
    local text = typed
    local asked_for = amount(text, amount_words)
    if not asked_for or calc(text) then worked, worked_for = nil, text return end
    local to = asked_for:match(" to (.+)$") or ""
    local money = to:find("^%u%u%u$") or to == "€" or to == "$" or to == "£" or to == "K\u{10D}"      -- money to the cent
    run("qalc", { "-set", "conv 0", "-set", "max decimals " .. (money and 2 or 4), "-set", "upxrates 1", "-t", asked_for }, function(out)
        if text ~= typed then return end                  -- something else has been typed since
        local got = ((out or ""):match("^[^\n]*") or ""):gsub("%s+$", "")
        got = (got .. " "):gsub("(%d+,%d-)0+(%s)", "%1%2"):gsub(",(%s)", "%1"):gsub("%s+$", "")     -- 111,8800 $ → 111,88 $
        local from = asked_for:match("^(.-) to ")
        -- what it could not turn into anything comes back as it went in: no answer, not a wrong one
        if got == "" or got:find("[Ee]rror") or got:find("[Ww]arning") or (from and got:gsub(",0+", "") == from:gsub(",0+", "")) then return end
        worked, worked_for = got, text
        if card.id() == "lens" and kept.mode == 0 then render(true) end
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
    rows[1] = { label = tr("Open terminal"), glyph = "terminal-2", run = function() after(LET_GO, open.terminal) end }
    for i, c in ipairs(kept.commands) do
        if i == 1 then rows[#rows + 1] = { head = true, label = tr("RECENTLY USED"), line = true } end
        rows[#rows + 1] = { label = c, glyph = "history", keep = true, run = function() if confirmed(c) then run_command(c) end end }
    end
    return rows
end

-- ── AI: a conversation in a card of its own (parts/ai.plm). latte-ai knows who answers and keeps the conversations;
-- the one open stays until a new session, also when the card closes. Which services the choice offers is the
-- Settings' (Launcher › AI in LensGoo: `ai` in lens-lists.json); signing in to them is LensAI's.
local HINTS = { claude = N("How can I help you today?"), gemini = N("Ask Gemini"), grok = N("What do you want to know?"),
                chatgpt = N("Ask ChatGPT"), copilot = N("Ask Copilot"), mistral = N("What do you want to build?"),
                deepseek = N("Message DeepSeek"), own = N("Ask anything…") }
local function offered()
    local out = {}
    for _, p in ipairs(ai.providers) do
        if not ai.prefer or table.find(ai.prefer, p.id) then out[#out + 1] = p end
    end
    return #out > 0 and out or ai.providers
end
local function provider()
    local list = offered()
    for _, p in ipairs(list) do if p.id == kept.ai.provider then return p end end
    return list[1]
end
local function model_of(p)
    for _, m in ipairs(p and p.models or {}) do if m.id == kept.ai.model then return m end end
    return p and p.models[1]
end
-- a text with a number in it: tr() translates, the number goes where {n} stands
local function with_n(t, n) return (tr(t):gsub("{n}", function() return tostring(n) end)) end
-- how hard it may think, as the tools name it, in words
local EFFORTS = { low = N("low"), medium = N("medium"), high = N("high"), xhigh = N("very high"), max = N("highest"), think = N("thinking") }
local function effort_of(p)
    for _, e in ipairs(p and p.efforts or {}) do if e == kept.ai.effort then return e end end
    return nil
end
local function percent(x) x = x or 0 return (x > 0 and x < 0.005) and "< 1 %" or (tostring(math.floor(x * 100 + 0.5)) .. " %") end
local function until_(t)
    local left = (t or 0) - os.time()
    if left <= 0 then return "" end
    -- when it starts again, short: it stands beside the share
    if left < 3600 then return "  ·  " .. math.ceil(left / 60) .. " min" end
    if left < 86400 then return "  ·  " .. math.floor(left / 3600) .. " h" end
    return "  ·  " .. math.floor(left / 86400) .. " d"
end
-- the micro-agents: a small fixed task on the field's text or the clipboard, for the AI on this computer
local AGENT_LIST = { { id = "summarize", name = N("Summarize"), glyph = "list" }, { id = "translate", name = N("Translate"), glyph = "world" },
                     { id = "explain", name = N("Explain an error"), glyph = "alert-triangle" }, { id = "command", name = N("A command from words"), glyph = "terminal-2" } }
-- what a service tells of the account (Copilot), and how many questions went to it through Lens: asked now and then
ai.told, ai.told_at = {}, {}
-- ── the field's menus, each a copy of the service's own: latte-ai gives their rows (`plus`, `menu`: see PLUS in
-- bin/latte-ai), the same LensAI draws. What LatteOS can do from here it does here; a row without `do`
-- opens the service's page, drawn in one colour shared by all of them (the user, 21. 10.)
-- how tall a row is and how wide the window, as each service draws them
local ROW_H = { claude = 30, gemini = 34, chatgpt = 30, grok = 32, mistral = 36, copilot = 32, deepseek = 32, own = 32 }
local PLUS_W = { claude = 260, gemini = 280, chatgpt = 470, grok = 250, mistral = 280, own = 250 }
local CHIP_W = { claude = 380, gemini = 230, chatgpt = 300, grok = 320, mistral = 270 }
-- what is chosen is ticked: the model in use, the effort, thinking while it is on; "@effort" says the effort
local function show_rows(rows, style, m, e)
    local out, h = {}, 0
    for k, r in ipairs(rows) do
        local d = r["do"] or {}
        local rh = (r.note and 40) or ((ROW_H[style] or 32) + ((r.desc or "") ~= "" and 17 or 0))
        rh = rh + (r.sep and 9 or 0)
        r.y = h
        local on = r.on == true or (d.model ~= nil and m ~= nil and d.model == m.id) or (d.effort ~= nil and d.effort == e) or (d.think == true and e ~= nil)
        local key = r.key == "@effort" and (e and tr(EFFORTS[e] or e) or "") or (r.key and tr(r.key) or "")
        out[k] = { name = tr(r.name), desc = r.desc and r.desc ~= "" and tr(r.desc) or "", hint = r.hint and tr(r.hint) or "", key = key,
                   glyph = r.glyph and icons[r.glyph] or "", g = r.glyph ~= nil, d = (r.desc or "") ~= "", on = on, sep = r.sep == true,
                   web = r["do"] == nil and not r.note, more = r.more == true, off = r.note == true or (d.reset == true and not fact.ai_typed),
                   note = r.note == true, h = rh }
        h = h + rh
    end
    return out, h
end
local fill_ai
local ai_rows, ai_said, ai_shown = -1, "", {}   -- what the conversation held when it was last shown (fill_ai)
local function ask_told(pid)
    if not pid or (ai.told_at[pid] or 0) > os.time() - 180 then return end   -- latte-ai keeps an answer 15 min, 3 near a limit
    ai.told_at[pid] = os.time()
    run("latte-ai", { "usage", pid }, function(out)
        local ok, r = pcall(json.decode, out or "")
        if ok and type(r) == "table" then ai.told[pid] = r end
        if card.id() == "lens" and kept.mode == 4 then fill_ai() end
    end)
end
fill_ai = function()
    local p, m = provider(), nil
    if p then ask_told(p.id) end
    m = model_of(p)
    fact.ai_style = p and p.style or "own"
    text.ai_hint = tr(HINTS[p and p.style or "own"] or HINTS.own)
    local e = effort_of(p)
    -- the switch at the foot says who answers and with what; the field's own chip says how hard it may think
    text.ai_model = (p and tr(p.name) or "") .. (m and m.name ~= "" and (" · " .. m.name) or "")
    -- the field's own chip, as each service has it: how hard it may think where it has that, else its model
    local style = p and p.style or "own"
    text.ai_effort_word = (style == "claude" and m and (m.name .. (e and ("  " .. tr(EFFORTS[e] or e)) or "")))
        or (style == "chatgpt" and (e and tr(EFFORTS[e] or e) or tr("Thinking")))
        or (style == "deepseek" and tr("Deep thinking")) or (style == "grok" and "Auto")
        or (e and tr(EFFORTS[e] or e)) or (p and #(p.efforts or {}) > 0 and tr("Effort"))
        or (style == "gemini" and ("Gemini " .. (m and m.name or ""))) or (m and m.name or "")
    -- DeepSeek's two chips: deep thinking (its reasoner) lit when on; smart search is its page's
    fact.ai_think = style == "deepseek" and m ~= nil and m.id:find("reasoner") ~= nil
    text.ai_search_word, text.ic_ai_world = tr("Smart search"), icons["world"]
    text.ic_ai_chipicon = icons[({ chatgpt = "bulb", mistral = "cube", copilot = "git-fork", deepseek = "atom" })[style] or "sparkles"]
    local names = {}
    for _, f in ipairs(ai.files) do names[#names + 1] = f:match("[^/]+$") or f end
    text.ai_files, fact.ai_nfiles = table.concat(names, ", "), #ai.files
    local u = ai.usage
    local ctx = (u.window or 0) > 0 and u.context / u.window or 0
    -- figures of the conversation count only when its last answer came from this service: a switch starts afresh
    local last = nil
    for _, msg in ipairs(ai.msgs) do if msg.role ~= "user" then last = msg.provider end end
    if last ~= (p and p.id) then u, ctx = {}, 0 end
    text.ai_who = (p and tr(p.name) or "") .. ((u.window or 0) > 0 and ("  ·  " .. with_n("context {n}", percent(ctx))) or "")
    text.ai_empty = p and tr(p.name) or ""
    -- what the service says over its field on its own page, in its words (translated)
    local hour = tonumber(os.date("%H"))
    local part = hour < 12 and N("Morning, what are we building?") or (hour < 18 and N("Afternoon, what are we building?") or N("Evening, what are we building?"))
    local greet = { claude = with_n("Welcome, {n}", ai.me or ""), gemini = tr("Where shall we start?"), chatgpt = tr("We can start whenever you like."),
                    mistral = tr(part), deepseek = tr("Hi, what can I do for you?"), copilot = tr("Copilot uses AI. Check for mistakes."), grok = "" }
    text.ai_greet = greet[p and p.style or ""] or ""
    text.ai_empty2 = tr("The conversation stays here until you start a new session.")
    -- Claude tells its limits with each answer only: what is shown is from the last one, and says when that was.
    -- A window that has started again since then is empty again, whatever the old figure said.
    -- the block under the coffee is the service's own: what it tells of itself. Figures of the conversation count
    -- only when its last answer came from this service; a switch starts the block afresh.
    -- Claude's limits as Anthropic tells them now (latte-ai usage), else as the last answer told them
    local told = p and ai.told[p.id] and ai.told[p.id].limits or {}
    local lim = p and p.id == "claude" and (told.five_hour and told or (u.limits and next(u.limits) and u.limits or kept.ai.limits)) or nil
    -- ChatGPT's plan has the same two windows, as Codex tells them (latte-ai usage chatgpt)
    if p and p.id == "chatgpt" and told.five_hour then lim = told end
    if lim == told then kept.ai.limits_at = nil end
    if lim and lim.five_hour then
        local function share(w) return (w.resets or 0) > os.time() and (w.used or 0) or 0 end
        local at = kept.ai.limits_at and (os.time() - kept.ai.limits_at > 600) and ("  ·  " .. with_n("as of {n}", os.date("%H:%M", kept.ai.limits_at))) or ""
        text.ai_lim1 = tr("Session (5 h)") .. at
        text.ai_lim1p, fact.ai_l1 = percent(share(lim.five_hour)) .. until_(lim.five_hour.resets), share(lim.five_hour)
        local w = lim.seven_day or { used = 0, resets = 0 }
        text.ai_lim2 = tr("Week (7 days)")
        text.ai_lim2p, fact.ai_l2 = percent(share(w)) .. until_(w.resets), share(w)
    elseif p and p.id == "grok" and told.credits then
        -- Grok's credits for the period, as xAI's billing tells them
        text.ai_lim1 = told.credits.week and tr("Credits (week)") or tr("Credits (month)")
        text.ai_lim1p, fact.ai_l1 = percent(told.credits.used) .. until_(told.credits.resets), told.credits.used
        text.ai_lim2 = with_n("{n} questions through Lens this month", tostring(ai.told[p.id].asked or 0))
        text.ai_lim2p, fact.ai_l2 = "", -1
    elseif p and p.id == "copilot" and ai.told[p.id] and next(ai.told[p.id].limits or {}) then
        -- Copilot's own figures, as GitHub tells them (what VS Code shows): the month's credits and the editor's suggestions
        local l = ai.told[p.id].limits
        local function line(q) return q and q.used or 0 end
        text.ai_lim1 = tr("Credits (month)")
        text.ai_lim1p, fact.ai_l1 = percent(line(l.chat)) .. until_(l.chat and l.chat.resets or 0), line(l.chat)
        text.ai_lim2 = tr("Suggestions in the editor")
        text.ai_lim2p, fact.ai_l2 = percent(line(l.completions)), line(l.completions)
    elseif p and p.id == "claude" then
        -- Claude tells its limits with an answer: until the first one, the lines are there without figures
        text.ai_lim1, text.ai_lim1p, fact.ai_l1 = tr("Session (5 h)"), "—", 0
        text.ai_lim2, text.ai_lim2p, fact.ai_l2 = tr("Week (7 days)"), "—", 0
    elseif p and (p["local"] or (u.window or 0) > 0) then
        -- a model on this computer, or a key's API: how full its window is, and what the conversation has used
        text.ai_lim1, text.ai_lim1p, fact.ai_l1 = tr("Context"), percent(ctx), ctx
        text.ai_lim2 = with_n("{n} tokens in this session", tostring(u.tokens or 0)) .. (p["local"] and ("  ·  " .. tr("on this computer")) or "")
        text.ai_lim2p, fact.ai_l2 = "", -1
    else
        -- a service through its own tool and the user's account: it tells no figures here, so none are made up;
        -- what LatteOS counts itself is said as that, and the account's own share as unknown
        local n = ai.told[p and p.id or ""] and ai.told[p.id].asked or 0
        text.ai_lim1, text.ai_lim1p, fact.ai_l1 = with_n("{n} questions through Lens this month", tostring(n)), "", -1
        text.ai_lim2, text.ai_lim2p, fact.ai_l2 = tr("The account's quota is not told here; the service's own page shows it."), "", -1
    end
    local rows = {}
    local names = {}
    for _, q in ipairs(ai.providers) do names[q.id] = q end
    for _, msg in ipairs(ai.msgs) do
        local who = tr("You")
        if msg.role ~= "user" then
            local q = names[msg.provider] or {}
            local mm = nil
            for _, x in ipairs(q.models or {}) do if x.id == msg.model then mm = x end end
            who = (q.name and tr(q.name) or msg.provider or "") .. (mm and (" · " .. mm.name) or "")
        end
        local attached = (type(msg.files) == "table" and #msg.files > 0 and ("\n📎 " .. table.concat(msg.files, ", ")) or "") .. (msg.stopped and ("\n(" .. tr("stopped") .. ")") or "")
        local body = (msg.content or "") .. attached
        local longest = 0
        for line in (body .. "\n"):gmatch("(.-)\n") do longest = math.max(longest, utf8.len(line) or #line) end
        rows[#rows + 1] = { who = who, body = body, mine = msg.role == "user", failed = msg.ok == false, w = math.clamp(longest * 7.6 + 30, 60, 560) }
    end
    if ai.waiting then rows[#rows + 1] = { who = p and tr(p.name) or "", body = ai.live ~= "" and ai.live or tr("Thinking…"), mine = false, failed = false, w = 560 } end
    while #rows > 40 do table.remove(rows, 1) end
    model.aimsg = rows
    ai_shown = rows
    fact.ai_wait = ai.waiting
    -- The list goes to the end for a new message, and follows a reply being written only if it is already there:
    -- counted up on every refresh, it pulled the wheel back down while one read further up (6B.07).
    local last = rows[#rows]
    local said = #rows .. ":" .. (last and #last.body or 0)
    if #rows ~= ai_rows then ai_rows = #rows fact.ai_new = fact.ai_new + 1 end
    if said ~= ai_said then ai_said = said fact.ai_gen = fact.ai_gen + 1 end
    -- the menu that is out: the services over the switch (LatteOS's own, one line each), the service's + or its chip
    local rows, style = {}, p and p.style or "own"
    if (ai.menu_at or 0) == 0 then
        for _, q in ipairs(offered()) do
            if #rows >= 10 then break end
            local here = p ~= nil and q.id == p.id
            local mm = here and m or q.models[1]
            rows[#rows + 1] = { name = q.name, on = here, key = mm and mm.name or "", ["do"] = { provider = q.id, model = mm and mm.id or "" } }
        end
        style = "own"
    elseif ai.menu_at == 2 then
        rows = p and p.plus or {}
    elseif p then
        rows = p.menu or {}
    end
    ai.pop, ai.pop_style = rows, p and p.style or "own"
    local shown, h = show_rows(rows, style, (ai.menu_at or 0) ~= 0 and m or nil, e)
    model.aipop = shown
    fact.ai_pop_h = h
    fact.ai_pop_w = (ai.menu_at or 0) == 0 and 300 or ai.menu_at == 2 and (PLUS_W[style] or 250) or (CHIP_W[style] or 300)
    fact.ai_pop_hx = (ai.menu_at == 2 and style == "chatgpt") and 196 or 0
    text.ic_ai_more, text.ic_ai_web = icons["chevron-right"], icons["external-link"]
    text.ai_btn_center, text.ai_btn_settings, text.ai_btn_new = tr("LensAI"), tr("Settings"), tr("New session")
    text.ai_btn_do, text.ic_ai_do = tr("Do it for me"), icons["robot"]
    local agents = {}
    for k, g in ipairs(AGENT_LIST) do agents[k] = { name = tr(g.name), glyph = icons[g.glyph] or "" } end
    model.aiagent = agents
    text.ic_ai_center, text.ic_ai_settings, text.ic_ai_new = icons["messages"], icons["settings"], icons["message-plus"]
    text.ic_ai_send, text.ic_ai_chev, text.ic_ai_spark, text.ic_ai_check = icons["arrow-up"], icons["chevron-down"], icons["sparkles"], icons["check"]
    text.ic_ai_copy = icons["copy"]
    text.ic_ai_copied = icons["check"]
    text.ic_ai_wave, text.ic_ai_plane, text.ic_ai_stop = icons["wave-sine"], icons["send"], icons["player-stop"]
    text.ic_ai_plus, text.ic_ai_clip, text.ic_ai_shot, text.ic_ai_x = icons["plus"], icons["paperclip"], icons["screenshot"], icons["x"]
    text.ai_add_file, text.ai_add_shot = tr("Attach a file…"), tr("A picture of the screen")
    text.ai_send_word = ai.waiting and tr("Stop") or tr("Send")
    text.ic_ai_mic = icons[fact.ai_listening == 2 and "loader-2" or "microphone"]
    text.ai_mic_word = fact.ai_listening == 1 and tr("Stop and write it down") or tr("Speak")
end
-- `asked`: a question made for the user (a micro-agent), to whom it goes (`pid`, `mid`); else what is in the field
-- The right button in the conversation (6B.08): copy a message or all of it, and how see-through the page is;
-- in the field, cut, copy and paste. (Ctrl+C on selected letters and Ctrl+V in the field work by themselves.)
local AI_GLASS = { N("Solid"), N("A little see-through"), N("More see-through"), N("Most see-through"), N("Glass") }
on("ai_copy", function(i)
    local said = ai_shown[(i or -1) + 1]
    if not said then return end
    pcall(sys.call, "clipboard.set", said.body)
    fact.ai_copied = i
    after(1200, function() if fact.ai_copied == i then fact.ai_copied = -1 end end)
end)
on("ai_menu", function(i)
    local rows, said = {}, ai_shown[(i or -1) + 1]
    local function copy(t) pcall(sys.call, "clipboard.set", t) end
    if i == -2 then
        -- the question being written: as any field's menu
        local typed = text.ai_q or ""
        if typed ~= "" then
            rows[#rows + 1] = { label = tr("Cut"), glyph = "cut", keys = "Ctrl+X", run = function() copy(typed) text.ai_q, fact.ai_typed = "", false end }
            rows[#rows + 1] = { label = tr("Copy"), glyph = "copy", keys = "Ctrl+C", run = function() copy(typed) end }
        end
        rows[#rows + 1] = { label = tr("Paste"), glyph = "clipboard", keys = "Ctrl+V", run = function()
            local ok, got = pcall(sys.ask, "clipboard")
            if ok and type(got) == "string" and got ~= "" then text.ai_q, fact.ai_typed = (text.ai_q or "") .. got, true end   -- a text the logic writes is not one typed: the hint is told
        end }
    else
        if said then rows[#rows + 1] = { label = tr("Copy"), glyph = "copy", keys = "Ctrl+C", run = function() copy(said.body) end } end
        if #ai_shown > 0 then
            rows[#rows + 1] = { label = tr("Copy the conversation"), glyph = "clipboard", run = function()
                local all = {}
                for _, r in ipairs(ai_shown) do all[#all + 1] = r.who .. ":\n" .. r.body end
                copy(table.concat(all, "\n\n"))
            end }
        end
        -- a service on a page of its own (Claude, Gemini…): how much of the white shows; LatteOS's own has none
        if fact.ai_style ~= "own" then
            local now = tonumber(drops.settings().ai_glass)
            local sub = { { label = tr("As LatteOS"), on = now == nil, run = function() drops.set("ai_glass", nil) end } }
            for k, name in ipairs(AI_GLASS) do sub[#sub + 1] = { label = tr(name), on = now == k - 1, run = function() drops.set("ai_glass", k - 1) end } end
            rows[#rows + 1] = { label = tr("See-through page"), glyph = "droplet", line = #rows > 0, sub = sub }
        end
    end
    ctx.open(rows, { width = 290 })
end)

local function ai_send(asked, pid, mid)
    local q = asked or (text.ai_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local p = provider()
    for _, x in ipairs(ai.providers) do if x.id == pid then p = x end end
    if q == "" or ai.waiting or not p then return end
    local m = model_of(p)
    for _, x in ipairs(p.models) do if x.id == mid then m = x end end
    text.ai_q, fact.ai_typed = "", false
    local args, names = { "send", kept.ai.chat or "new", p.id, m.id, q }, {}
    local e = effort_of(p)
    if e then args[#args + 1] = "--effort" args[#args + 1] = e end
    for _, f in ipairs(ai.files) do
        args[#args + 1] = "--attach" args[#args + 1] = f
        names[#names + 1] = f:match("[^/]+$") or f
    end
    ai.files = {}
    ai.msgs[#ai.msgs + 1] = { role = "user", content = q, provider = p.id, model = m.id, files = names }
    ai.waiting, ai.live = true, ""
    fill_ai()
    -- the answer comes in pieces: each shows as it comes (a refresh at most every 120 ms), the last line is the whole
    args[#args + 1] = "--stream"
    local final, due = nil, false
    ai.job = spawn("latte-ai", args, function(line)
        local ok, m = pcall(json.decode, line or "")
        if not ok or type(m) ~= "table" then return end
        if m.delta then
            ai.live = ai.live .. m.delta
            if not due then due = true after(120, function() due = false if ai.waiting then fill_ai() end end) end
        elseif m.chat then
            final = m
        end
    end, function()
        ai.waiting, ai.job = false, nil
        local ok, r = final ~= nil, final
        if ok and type(r) == "table" and r.chat then
            kept.ai.chat = r.chat
            ai.usage = r.usage or {}
            -- the account's limits are the account's, not the conversation's: kept for the next session too
            if ai.usage.limits and next(ai.usage.limits) then kept.ai.limits, kept.ai.limits_at = ai.usage.limits, os.time() end
            ai.msgs[#ai.msgs + 1] = { role = "assistant", content = r.answer or "", provider = p.id, model = m.id, ok = r.ok, stopped = r.stopped }
            save()
        else
            ai.msgs[#ai.msgs + 1] = { role = "assistant", content = tr("No answer came."), provider = p.id, model = m.id, ok = false }
        end
        fill_ai()
    end)
end
on("ai_send", function() ai_send() end)
on("ai_agent", function(i)
    local g = AGENT_LIST[(i or 0) + 1]
    if not g or ai.waiting then return end
    local typed_now = (text.ai_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    run("latte-ai", { "agent", g.id, typed_now }, function(out)
        local ok, r = pcall(json.decode, out or "")
        if not ok or type(r) ~= "table" or (r.question or "") == "" then
            ai.msgs[#ai.msgs + 1] = { role = "assistant", content = tr("Nothing to work on: write something, or copy it first."), ok = false }
            fill_ai()
            return
        end
        text.ai_q, fact.ai_typed = "", false
        ai_send(r.question, r.provider, r.model)
    end)
end)
-- stopped: latte-ai keeps what had come and says so in its last line
on("ai_stop", function() if ai.job then kill(ai.job, "term") end end)
on("text:ai_q", function() fact.ai_typed = (text.ai_q or "") ~= "" end)
-- a row pressed: what LatteOS can do it does; a row with more opens beside it; a row of the service's page opens that
local attach
local function act(r, sub)
    if not r or r.note then return end
    local d = r["do"]
    if d and d.reset and not fact.ai_typed then return end
    local p = provider()
    if d and d.sub and not sub then
        local shown, h = show_rows(d.sub, ai.pop_style, model_of(p), effort_of(p))
        ai.sub = d.sub
        model.aisub = shown
        fact.ai_sub_y, fact.ai_sub_h = r.y, h
        fact.ai_sub_w = ai.pop_style == "gemini" and 280 or ai.pop_style == "claude" and 170 or 220
        fact.ai_sub = true
        return
    end
    fact.ai_menu, fact.ai_sub = false, false
    if not d or d.sub then
        local url = p and p.web or ""
        if url ~= "" then then_do(function() open.url(url) end) end
        return
    elseif d.attach then
        attach(d.attach)
        return
    elseif d.model then
        kept.ai.provider, kept.ai.model = d.provider or (p and p.id), d.model
    elseif d.effort then
        kept.ai.effort = d.effort
    elseif d.think then
        kept.ai.effort = (kept.ai.effort == nil) and "high" or nil
    elseif d.reset then
        text.ai_q, fact.ai_typed = "", false
    end
    save()
    fill_ai()
end
on("ai_pop", function(i) act(ai.pop and ai.pop[(i or 0) + 1]) end)
on("ai_subpick", function(i) act(ai.sub and ai.sub[(i or 0) + 1], true) end)
-- 0 the services (the switch), 1 the chip, 2 the +, 3 a chip of the service's page. DeepSeek's chip is a switch of its own (deep thinking: its
-- reasoner); where a service has no + menu (Copilot, DeepSeek's paperclip) the + attaches at once
on("ai_open", function(where)
    where = where or 0
    fact.ai_sub = false
    if fact.ai_menu and (ai.menu_at or 0) == where then fact.ai_menu = false return end
    local p = provider()
    local style = p and p.style or "own"
    if where == 2 and p and #(p.plus or {}) == 0 then attach(0) return end
    if where == 3 then local url = p and p.web or "" if url ~= "" then then_do(function() open.url(url) end) end return end
    if where == 1 and style == "deepseek" and p then
        local m = model_of(p)
        for _, x in ipairs(p.models) do
            if (x.id:find("reasoner") ~= nil) ~= (m and m.id:find("reasoner") ~= nil) then kept.ai.model = x.id break end
        end
        save()
        fill_ai()
        return
    end
    ai.menu_at = where
    fact.ai_menu_at = where
    fill_ai()
    fact.ai_menu = true
end)
on("ai_new", function()
    kept.ai.chat, ai.msgs, ai.usage = nil, {}, {}
    save()
    fill_ai()
    focus("ai_q")
end)
-- something to attach: the card steps aside for the file chooser, or for the picture of the screen, and comes back
attach = function(what)
    card.close()
    after(what == 1 and 450 or 120, function()
        run("latte-ai", { what == 1 and "shot" or "pick" }, function(out)
            for path in (out or ""):gmatch("[^\n]+") do
                if #ai.files < 8 and not table.find(ai.files, path) then ai.files[#ai.files + 1] = path end
            end
            M.open(4)
        end)
    end)
end
on("ai_attach", function(what) attach(what) end)
on("ai_unattach", function() ai.files = {} fill_ai() end)
-- the microphone: what is said goes into the field, to be read and changed before it is sent
on("ai_mic", function()
    if fact.ai_listening == 0 then
        fact.ai_listening = 1
        run("latte-ai", { "listen", "start" }, nil)
    else
        fact.ai_listening = 2
        run("latte-ai", { "listen", "stop" }, function(out)
            fact.ai_listening = 0
            local ok, r = pcall(json.decode, out or "")
            local said = ok and type(r) == "table" and r.text or ""
            if said ~= "" then
                text.ai_q = ((text.ai_q or "") ~= "" and (text.ai_q .. " ") or "") .. said
                fact.ai_typed = true
            end
            fill_ai()
            focus("ai_q")
        end)
    end
    fill_ai()
end)
-- "Do it for me": what is in the field goes to an agent in a terminal (latte-ai do), which plans first and asks;
-- with nothing written, LensAI's agents page, where the tasks to start from are
on("ai_do", function()
    local task = (text.ai_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if task == "" then then_do(function() run("latte-app", { "aicenter", "agents" }, nil, { output = false }) end) return end
    text.ai_q, fact.ai_typed = "", false
    then_do(function() run("latte-ai", { "do", task }, nil, { output = false }) end)
end)
on("ai_center", function() then_do(function() run("latte-app", { "aicenter" }, nil, { output = false }) end) end)
on("ai_settings", function() then_do(function() open.settings("launcher") end) end)
-- the conversation that was open, from latte-ai, when LensGoo starts
local function load_chat()
    if not kept.ai.chat then return end
    run("latte-ai", { "chat", kept.ai.chat }, function(out)
        local ok, c = pcall(json.decode, out or "")
        if ok and type(c) == "table" and type(c.messages) == "table" then
            ai.msgs, ai.usage = c.messages, c.usage or {}
        else
            kept.ai.chat = nil
        end
    end)
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
        { label = tr("Lists and filters…"), glyph = "list", line = true, run = function() then_do(function() open.settings("launcher") end) end },
    }
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
    card.open(rows, { owner = owner, id = "lens-custom", uniform = true, plain = true })
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
    [0] = { glyph = "apps", name = N("Applications"), hint = N("Search apps or settings…"), rows = rows_apps },
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

-- the foot of a mode: one way on from there
local function foot()
    local m = kept.mode
    if m == 1 then return { label = tr("Open the file manager"), glyph = "folder", more = true, run = function() then_do(function() run("latte-app", { "files" }, nil, { output = false }) end) end } end
    if m == 2 then
        local e = engine()
        return { label = tr("Open") .. " " .. e.name, glyph = "world-www", more = true, run = function() then_do(function() open.url(e.url:match("^(https?://[^/]+)")) end) end }
    end
    if m == 3 then return { label = tr("Open terminal"), glyph = "terminal-2", more = true, run = function() then_do(open.terminal) end } end
    return { label = tr("Settings") .. " › AI", glyph = "settings", more = true, run = function() then_do(function() open.settings("ai") end) end }
end
local function rows_ai() return {} end

local shown = {}
local shore_render
render = function(keep)
    if fact.lens_shore then return shore_render(keep) end    -- LensShore: its own card out of its capsule
    local tabs = {}
    if modes_off[kept.mode] then kept.mode = 0 end
    for m = 0, #MODES do
        if not modes_off[m] then
            tabs[#tabs + 1] = { label = tr(MODES[m].name), glyph = MODES[m].glyph, on = kept.mode == m, run = function() set_mode(m) end }
        end
    end
    -- the AI is a card of its own: a conversation, not rows
    if kept.mode == 4 and MODES[4] then
        shown = {}
        card.open({}, { owner = owner, id = "lens", width = WIDTH, keep = keep, tabs = tabs, uniform = true, custom = "ai", split = 508, pane = 1 })
        fill_ai()
        if not keep then after(60, function() focus("ai_q") end) end
        return
    end
    shown = MODES[kept.mode].rows()
    -- every mode has the look of the first: glass above, a divider of coffee and a foot below it (not where an answer
    -- of any length stands: its height is not known)
    local list, glassy = shown, kept.mode == 0 and typed == ""
    if kept.mode ~= 0 then
        local plain = true
        for _, r in ipairs(shown) do if r.para then plain = false end end
        if plain then
            list = {}
            for i, r in ipairs(shown) do list[i] = r end
            list[#list + 1] = { wave = true }
            list[#list + 1] = foot()
            glassy = true
        end
    end
    card.open(list, {
        owner = owner, id = "lens", width = WIDTH, keep = keep, tabs = tabs, uniform = true,
        pane = glassy and 1 or 0,
        field = {
            hint = tr(MODES[kept.mode].hint), text = typed,
            change = function(t)
                t = t:gsub("^%s+", ""):gsub("%s+$", "")
                if t == typed then return end
                typed, confirm = t, nil
                if kept.mode == 1 then look_for_files() end
                if kept.mode == 0 then look_for_settings() look_for_amount() end
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
    -- the AI asked for before latte-ai has said who can answer: it opens as soon as it has
    if m == 4 and not MODES[4] then ai.pending = true end
    load_lists()
    if m and MODES[m] and not modes_off[m] then kept.mode = m end
    kept.filter = "all"                  -- the apps always open on All (the user, 26. 10.); a list chosen holds while it is open
    typed, confirm, found = "", nil, nil
    render(false)
end
function M.toggle()
    if fact.lens_shore then return M.shore_toggle() end
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

-- ── LensShore (6B.12): a plate of glass at the top or the bottom edge with a line on it (parts/lensline.plm); its panel
-- slides out of it, one body with it (parts/card.plm, `lens`). The panel is laid out as Raycast's list: a chosen row (at
-- first "Ask the AI", so Enter asks it), sections with a few rows each, the kind of each on the right; the arrows choose
-- another. Not a drop: the drops keep off its stretch of the edge.
local WIDE = 620                             -- the plate's length, which is the panel's width too
local shore = { view = "find", talk = {}, chat = "new", live = "", ctx = {}, use = {}, sure = {}, chats = {} }
local function shore_top() return drops.settings().lens_top ~= false end
-- where it lies, from the Settings: the drops keep off that stretch, the capsule lies on it
local function shore_place()
    local on = fact.lens_shore == true
    if not on then drops.block("lensshore", nil) fact.lens_b = fact.lens_a return end
    local w = tonumber(fact.sw) or 1920
    local x = tonumber(drops.settings().lens_x) or 0.5
    local a = math.floor(math.max(12, math.min(w - WIDE - 12, x * w - WIDE / 2)))
    local e = shore_top() and 2 or 0
    fact.lens_edge, fact.lens_a, fact.lens_b = e, a, a + WIDE
    drops.block("lensshore", e, a, a + WIDE)
end

-- the words of what can be done at once are the English ones and the user's own (the translation table)
local function said(en, s) return s == en or s == tr(en):lower() end
local function word_then_number(en, s)
    for _, w in ipairs({ en, tr(en):lower() }) do
        local n = s:match("^" .. w:gsub("%p", "%%%0") .. "%s+(%d+)%s*%%?$")
        if n then return tonumber(n) end
    end
end
local function quick_rows(s)
    s = s:lower()
    local out, n = {}, nil
    n = word_then_number("brightness", s)
    if n then out[#out + 1] = { label = (tr("Set the brightness to {n} %"):gsub("{n}", n)), glyph = "sun", hint = tr("Do it now"), run = function() run("brightnessctl", { "set", n .. "%" }, function() end) end } end
    n = word_then_number("volume", s)
    if n then out[#out + 1] = { label = (tr("Set the volume to {n} %"):gsub("{n}", n)), glyph = "volume", hint = tr("Do it now"), run = function() run("wpctl", { "set-volume", "@DEFAULT_AUDIO_SINK@", tostring(n / 100) }, function() end) end } end
    if said("turn on wifi", s) then out[#out + 1] = { label = tr("Turn the Wi-Fi on"), glyph = "wifi", hint = tr("Do it now"), run = function() run("nmcli", { "radio", "wifi", "on" }, function() end) end } end
    if said("turn off wifi", s) then out[#out + 1] = { label = tr("Turn the Wi-Fi off"), glyph = "wifi-off", hint = tr("Do it now"), run = function() run("nmcli", { "radio", "wifi", "off" }, function() end) end } end
    n = word_then_number("timer", s)
    if n then out[#out + 1] = { label = (tr("A timer for {n} min"):gsub("{n}", n)), glyph = "clock", hint = tr("Do it now"), run = function()
        after(n * 60000, function() run("notify-send", { "-a", "LatteOS", tr("Timer"), (tr("{n} min are up"):gsub("{n}", n)) }, function() end) end)
    end } end
    if said("do not disturb", s) then out[#out + 1] = { label = tr("Do not disturb"), glyph = "bell-off", hint = tr("Do it now"), run = function() drops.set("quiet", not drops.settings().quiet) end } end
    return out
end

-- what the AI may see, shown as buttons the user switches on: the selected text, the clipboard, the window in front
local function read_context()
    shore.ctx = {}
    run("wl-paste", { "--primary", "--no-newline" }, function(out) shore.ctx.picked = (out or ""):sub(1, 4000) if card.id() == "lens" then render(true) end end)
    local ok, clip = pcall(sys.ask, "clipboard")
    shore.ctx.clip = ok and type(clip) == "string" and clip:sub(1, 4000) or ""
    run("hyprctl", { "-j", "activewindow" }, function(out)
        local okw, w = pcall(json.decode, out or "")
        shore.ctx.front = okw and type(w) == "table" and (w.title or "") ~= "" and (w.title .. " (" .. (w.class or "") .. ")") or ""
        if card.id() == "lens" then render(true) end
    end)
end
local function context_text()
    local parts = {}
    if shore.use.picked and (shore.ctx.picked or "") ~= "" then parts[#parts + 1] = tr("Selected text") .. ":\n" .. shore.ctx.picked end
    if shore.use.clip and (shore.ctx.clip or "") ~= "" then parts[#parts + 1] = tr("Clipboard") .. ":\n" .. shore.ctx.clip end
    if shore.use.front and (shore.ctx.front or "") ~= "" then parts[#parts + 1] = tr("The window in front") .. ": " .. shore.ctx.front end
    return #parts > 0 and (table.concat(parts, "\n\n") .. "\n\n") or ""
end
local function context_row()
    local pills = {}
    local function pill(key, label, glyph)
        pills[#pills + 1] = { label = label, glyph = glyph, on = shore.use[key] == true, keep = true, run = function() shore.use[key] = not shore.use[key] render(true) end }
    end
    if (shore.ctx.picked or "") ~= "" then pill("picked", tr("Selected text"), "cursor-text") end
    if (shore.ctx.clip or "") ~= "" and shore.ctx.clip ~= shore.ctx.picked then pill("clip", tr("Clipboard"), "clipboard") end
    if (shore.ctx.front or "") ~= "" then pill("front", (shore.ctx.front:match("^(.-) %(") or shore.ctx.front):sub(1, 28), "app-window") end
    return #pills > 0 and { pills = pills, per = #pills } or nil
end

-- the AI, asked from the line: the answer comes in pieces, into the card
local function ask(q)
    local p = provider()
    if not p then return end
    local m = model_of(p)
    shore.talk[#shore.talk + 1] = { mine = true, text = q }
    shore.live, shore.view, fact.lens_busy = "", "talk", true
    local final = nil
    local args = { "send", shore.chat, p.id, m and m.id or "", context_text() .. q, "--stream" }
    shore.use = {}
    render(card.id() == "lens")
    local due = false
    shore.job = spawn("latte-ai", args, function(line)
        local ok, r = pcall(json.decode, line or "")
        if not ok or type(r) ~= "table" then return end
        if r.delta then
            shore.live = shore.live .. r.delta
            if not due then due = true after(150, function() due = false if card.id() == "lens" and shore.view == "talk" then render(true) end end) end
        elseif r.chat then final = r end
    end, function()
        fact.lens_busy, shore.job = false, nil
        if final then shore.chat = final.chat shore.talk[#shore.talk + 1] = { mine = false, text = final.answer or "" }
        elseif shore.live ~= "" then shore.talk[#shore.talk + 1] = { mine = false, text = shore.live } end
        shore.live = ""
        if card.id() == "lens" then render(true) else fact.lens_fresh = true end
    end)
end
-- what an answer suggests doing: the commands in it, the addresses in it
local function suggested(answer)
    local out = {}
    for body in answer:gmatch("```[%w]*\n(.-)```") do if #out < 3 then out[#out + 1] = { cmd = body:gsub("%s+$", "") } end end
    for url in answer:gmatch("https?://[^%s%)%]>]+") do if #out < 5 then out[#out + 1] = { url = url } end end
    return out
end
local function ago(stamp)
    local y, mo, d, h, mi = (stamp or ""):match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if not y then return "" end
    local t = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = tonumber(h), min = tonumber(mi) })
    local s = os.time() - t
    if s < 3600 then return (tr("{n} min ago"):gsub("{n}", math.max(1, s // 60))) end
    if s < 86400 then return (tr("{n} h ago"):gsub("{n}", s // 3600)) end
    if s < 172800 then return tr("yesterday") end
    return string.format("%d. %d.", tonumber(d), tonumber(mo))
end

-- the rows, nearest the line first: at the top edge read downwards, at the bottom upwards (`first = "last"`)
local function shore_rows()
    local sections = {}
    local function section(rows) if #rows > 0 then sections[#sections + 1] = rows end end
    if shore.view == "chats" then
        local rows = { { head = true, label = tr(N("CONVERSATIONS")) } }
        for i, c in ipairs(shore.chats) do
            if i > 8 then break end
            rows[#rows + 1] = { label = c.title ~= "" and c.title or "…", glyph = "messages", hint = ago(c.updated), keep = true, run = function()
                run("cat", { (shore.chats_dir or "") .. "/" .. c.id .. ".json" }, function(out)
                    local ok, chat = pcall(json.decode, out or "")
                    if not ok or type(chat) ~= "table" then return end
                    shore.chat, shore.talk, shore.view = chat.id, {}, "talk"
                    for _, m in ipairs(chat.messages or {}) do shore.talk[#shore.talk + 1] = { mine = m.role == "user", text = m.content or "" } end
                    render(true)
                end)
            end }
        end
        if #shore.chats == 0 then rows[#rows + 1] = { label = tr("No conversation yet"), glyph = "messages", quiet = true } end
        section(rows)
        section({ { label = tr("New conversation"), glyph = "plus", keep = true, run = function() shore.chat, shore.talk, shore.view = "new", {}, "find" render(true) focus("lens_q") end } })
    elseif shore.view == "talk" then
        local rows = {}
        for i = math.max(1, #shore.talk - 5), #shore.talk do
            local m = shore.talk[i]
            if m.mine then rows[#rows + 1] = { label = m.text, glyph = "user", quiet = true, line = #rows > 0 }
            else
                rows[#rows + 1] = { para = true, label = m.text }
                for j, s in ipairs(suggested(m.text)) do
                    local key = i .. ":" .. j
                    if s.cmd then rows[#rows + 1] = { label = shore.sure[key] and tr("Really run it?") or tr("Run in a terminal"), line2 = s.cmd:sub(1, 60), glyph = "terminal-2", danger = shore.sure[key] == true, keep = not shore.sure[key],
                                                      run = function() if shore.sure[key] then then_do(function() open.shell(s.cmd) end) else shore.sure[key] = true render(true) end end }
                    else rows[#rows + 1] = { label = tr("Open the link"), line2 = s.url, glyph = "world", run = function() then_do(function() open.url(s.url) end) end } end
                end
                rows[#rows + 1] = { label = tr("Copy"), glyph = "copy", copy = m.text, keep = true, run = function() pcall(sys.call, "clipboard.set", m.text) end }
            end
        end
        if fact.lens_busy then rows[#rows + 1] = { para = true, label = shore.live ~= "" and shore.live or tr("Thinking…") } end
        section(rows)
        section({ { pills = {
            { label = tr("New conversation"), glyph = "plus", keep = true, run = function() shore.chat, shore.talk, shore.view = "new", {}, "find" render(true) focus("lens_q") end },
            { label = tr("Conversations"), glyph = "history", keep = true, run = function() M.shore_chats() end },
            { label = tr("Open in LensAI"), glyph = "external-link", off = shore.chat == "new", run = function() then_do(function() run("latte-app", { "aicenter", shore.chat }, function() end) end) end },
        }, per = 3 } })
    elseif typed == "" then
        local tiles = {}
        for _, id in ipairs(kept.recent) do if by_id[id] and #tiles < 6 then tiles[#tiles + 1] = tile(by_id[id]) end end
        if #tiles > 0 then section({ { head = true, label = tr("RECENTLY USED") }, { tiles = tiles, per = 6 } }) end
        section({ { label = MODES[4] and tr("Type to search; Enter asks the AI") or tr("Type to search"), glyph = MODES[4] and "sparkles" or "search", quiet = true } })
    else
        local q = typed
        -- first, chosen: the AI (Enter); with it off, the best of what was found is first instead
        if MODES[4] then
            local p = provider()
            local first = { { label = tr("Ask the AI") .. ": " .. q, glyph = "sparkles", hint = p and p.name or "", run = function() ask(q) text.lens_q, fact.lens_typed, typed = "", false, "" end } }
            local c = context_row()
            if c then first[#first + 1] = c end
            section(first)
        end
        section(quick_rows(q))
        local result = calc(q)
        local shown_amount = result and number(result) or (worked and worked_for == q and worked)
        if shown_amount then section({ { label = shown_amount, glyph = "calculator", hint = tr("Calculator"), copy = shown_amount, run = function() pcall(sys.call, "clipboard.set", shown_amount) end } }) end
        local hits, rows = find(apps, q, 5), {}
        for i, a in ipairs(hits) do
            if i > 4 then break end
            rows[#rows + 1] = { label = a.local_name or a.name or a.id, icon = a.icon or "", glyph = "apps", hint = tr("App"), run = function() launch(a) end, right = function() app_menu(a) end }
        end
        if #rows > 0 then table.insert(rows, 1, { head = true, label = tr(N("APPLICATIONS")) }) section(rows) end
        rows = { { head = true, label = tr(N("FILES AND FOLDERS")) } }
        local want = q:lower()
        local files, later = {}, {}
        for _, path in ipairs(found or {}) do
            local name = (path:gsub("/$", ""):match("([^/]+)$") or ""):lower()
            if name:sub(1, #want) == want then files[#files + 1] = path else later[#later + 1] = path end
        end
        for _, p in ipairs(later) do files[#files + 1] = p end
        for i, path in ipairs(files) do
            if i > 4 then break end
            local folder = path:sub(-1) == "/"
            local clean = folder and path:sub(1, -2) or path
            local parent = clean:match("^(.*)/[^/]*$") or "/"
            rows[#rows + 1] = { label = clean:match("([^/]+)$") or clean, glyph = folder and "folder" or "file", hint = short(parent),
                                run = function() then_do(function() open.path(clean) end) end, right = function() then_do(function() open.path(parent) end) end }
        end
        if found == nil then rows[#rows + 1] = { label = tr("Searching…"), glyph = "search", quiet = true } end
        if #rows > 1 or found == nil then section(rows) end
        if pages_for == q and #pages > 0 then
            rows = { { head = true, label = tr(N("SETTINGS")) } }
            for i, pg in ipairs(pages) do if i <= 3 then rows[#rows + 1] = { label = pg.name, glyph = pg.icon, hint = pg.area_name, run = function() then_do(function() open.settings(pg.page) end) end } end end
            section(rows)
        end
        section({ { head = true, label = tr(N("WEB")) }, { label = (tr("Search for “{what}” on {engine}"):gsub("{what}", function() return q end):gsub("{engine}", function() return engine().name end)), glyph = "world", hint = tr("Web"), run = function() search_web(engine(), q) end } })
    end
    -- at the bottom edge the list reads upwards: nearest the line what comes first; room under it for the line itself
    local out = {}
    local top = shore_top()
    for i = 1, #sections do
        local s = sections[top and i or (#sections + 1 - i)]
        for j, r in ipairs(s) do if j == 1 and #out > 0 then r.line = true end out[#out + 1] = r end
    end
    if top then table.insert(out, 1, { gap = 34 }) else out[#out + 1] = { gap = 34 } end
    return out
end
shore_render = function(keep)
    shown = shore_rows()
    card.open(shown, { lens = true, id = "lens", width = WIDE / 1.2, keep = keep, first = shore_top() and true or "last",
                       again = shore.view == "find", fit = true, pane = 1 })
end
function M.shore_open()
    if not fact.lens_shore then return end
    if card.id() ~= "lens" then
        load_lists()
        read_context()
        fact.lens_fresh = false
        shore_render(false)
    end
    after(60, function() focus("lens_q") end)
end
function M.shore_toggle()
    if card.id() == "lens" then card.close() else M.shore_open() end
end
function M.shore_chats()
    run("latte-ai", { "chats" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        shore.chats = ok and type(list) == "table" and list or {}
        shore.view = "chats"
        if card.id() == "lens" then render(true) else M.shore_open() end
    end)
end
local function shore_start()
    local okst, st = pcall(sys.ask, "env", "XDG_STATE_HOME")
    local okh, h = pcall(sys.ask, "env", "HOME")
    shore.chats_dir = ((okst and type(st) == "string" and st ~= "") and st or ((okh and h or "") .. "/.local/state")) .. "/latteos/ai/chats"
    text.lens_hint, text.g_send = tr("Search or ask…"), icons["arrow-up"]
    text.g_ln_talk, text.g_ln_mic = icons["messages"], icons["microphone"]
    local function who() local p = provider() text.g_ln_who = icons[(p and p["local"]) and "home" or "cloud"] or "" end
    who()
    local pause
    on("text:lens_q", function()
        fact.lens_typed = (text.lens_q or "") ~= ""
        if pause then cancel(pause) end
        pause = after(140, function()
            pause = nil
            local t = (text.lens_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if t == typed then return end
            typed, confirm, found = t, nil, nil
            if t ~= "" then shore.view = "find" look_for_files() look_for_settings() look_for_amount() end
            if card.id() == "lens" then render(true) elseif t ~= "" then M.shore_open() end
        end)
    end)
    on("lens_press", M.shore_open)
    on("lens_enter", function() if card.id() == "lens" then card.enter() end end)
    on("lens_send", function()
        local q = (text.lens_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" or not MODES[4] then return end
        text.lens_q, fact.lens_typed, typed = "", false, ""
        if card.id() ~= "lens" then M.shore_open() end
        ask(q)
    end)
    on("lens_talk", function()
        if card.id() == "lens" and shore.view ~= "find" then return card.close() end
        fact.lens_fresh = false
        if #shore.talk > 0 then shore.view = "talk" if card.id() == "lens" then render(true) else M.shore_open() end
        else M.shore_chats() end
    end)
    on("lens_who", function()
        local rows = {}
        for _, p in ipairs(ai.providers) do
            rows[#rows + 1] = { label = p.name, glyph = p["local"] and "home" or "cloud", on = provider() == p, hint = p["local"] and tr("this computer") or "",
                                run = function() kept.ai.provider = p.id save() who() end }
        end
        if #rows > 0 then ctx.open(rows, { width = 260 }) end
    end)
    on("lens_mic", function()
        local on = not fact.lens_listening
        fact.lens_listening = on
        run("latte-ai", { "listen", on and "start" or "stop" }, function(out)
            if on then return end
            local ok, r = pcall(json.decode, out or "")
            if ok and type(r) == "table" and (r.text or "") ~= "" then
                text.lens_q = ((text.lens_q or "") ~= "" and (text.lens_q .. " ") or "") .. r.text
                fact.lens_typed = true
                focus("lens_q")
            end
        end)
    end)
    on("lens_right", function()
        local now = text.lens_q or ""
        local function changed() fact.lens_typed = (text.lens_q or "") ~= "" end
        card.field_menu("lens_q", changed)
    end)
    on("fact:sw", shore_place)
    pcall(sys.watch, "files:settings.json", function() shore_place() who() end)
end
function M.start(d)
    owner = d
    -- with LensShore the drop is not there: the capsule and its line are the launcher
    local function which()
        d:present(not fact.lens_shore)
        shore_place()
        if card.id() == "lens" then card.close() end
    end
    on("fact:lens_shore", which)
    shore_start()
    which()
    -- the words an amount is written in, in the user's language (lib/amount.luau)
    local okl, lang = pcall(sys.ask, "env", "LANG")
    local code = (okl and type(lang) == "string" and lang:match("^(%a%a)")) or "en"
    local okd, share = pcall(sys.ask, "env", "LATTE_SHARE")
    share = okd and type(share) == "string" and share ~= "" and share or "/usr/share/latteos"
    run("cat", { share .. "/goo/lang/" .. code .. "-amount.json" }, function(out)
        local ok, w = pcall(json.decode, out or "")
        if ok and type(w) == "table" then amount_words = w end
    end)
    local okh, user = pcall(sys.ask, "env", "USER")
    user = okh and type(user) == "string" and user or ""
    ai.me = user ~= "" and (user:sub(1, 1):upper() .. user:sub(2)) or ""
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
        kept.filter = type(saved.filter) == "string" and saved.filter or "all"
        if type(saved.ai) == "table" then kept.ai = saved.ai end
    end
    load_chat()
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
    -- the AI tab is there while the AI is on and somebody can answer: latte-ai lists nobody when it is turned off
    run("latte-ai", { "providers" }, function(out)
        local found_any, list = pcall(json.decode, out or "")
        if not found_any or type(list) ~= "table" or #list == 0 then return end
        ai.providers = list
        MODES[4] = { glyph = "sparkles", name = N("AI"), hint = HINTS.own, rows = rows_ai }
        if ai.pending then ai.pending = false M.open(4) end
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
