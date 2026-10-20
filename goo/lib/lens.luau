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
              layout = { most = true, fav = true, fresh = true, chips = true }, ai = {} }
local born = {}                      -- app id → when it was installed (the birth of its .desktop file)
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
local ai = { providers = {}, prefer = nil, msgs = {}, usage = {}, waiting = false, choices = {} }
local function load_lists()
    local ok, saved = pcall(sys.ask, "files.read", "lens-lists.json", "json")
    lists = ok and type(saved) == "table" and type(saved.lists) == "table" and #saved.lists > 0 and saved.lists or DEFAULT_LISTS
    ai.prefer = ok and type(saved) == "table" and type(saved.ai) == "table" and saved.ai or nil
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

-- ── AI: a conversation in a card of its own (parts/ai.plm). latte-ai knows who answers and keeps the conversations;
-- the one open stays until a new session, also when the card closes. Which services the choice offers is the
-- Settings' (Launcher › AI in LensGoo: `ai` in lens-lists.json); signing in to them is the Lens AI centre's.
local HINTS = { claude = N("How can I help you today?"), gemini = N("Ask Gemini"), grok = N("What do you want to know?"),
                chatgpt = N("Ask ChatGPT"), own = N("Ask anything…") }
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
local function percent(x) x = x or 0 return (x > 0 and x < 0.005) and "< 1 %" or (tostring(math.floor(x * 100 + 0.5)) .. " %") end
local function until_(t)
    local left = (t or 0) - os.time()
    if left <= 0 then return "" end
    -- when it starts again, short: it stands beside the share
    if left < 3600 then return "  ·  " .. math.ceil(left / 60) .. " min" end
    if left < 86400 then return "  ·  " .. math.floor(left / 3600) .. " h" end
    return "  ·  " .. math.floor(left / 86400) .. " d"
end
local function fill_ai()
    local p, m = provider(), nil
    m = model_of(p)
    fact.ai_style = p and p.style or "own"
    text.ai_hint = tr(HINTS[p and p.style or "own"] or HINTS.own)
    text.ai_model = m and m.name or ""
    local u = ai.usage
    local ctx = (u.window or 0) > 0 and u.context / u.window or 0
    text.ai_who = (p and p.name or "") .. ((u.window or 0) > 0 and ("  ·  " .. with_n("context {n}", percent(ctx))) or "")
    text.ai_empty = p and p.name or ""
    text.ai_empty2 = tr("The conversation stays here until you start a new session.")
    local lim = u.limits and next(u.limits) and u.limits or kept.ai.limits
    if lim and lim.five_hour then
        text.ai_lim1 = tr("Session (5 h)")
        text.ai_lim1p, fact.ai_l1 = percent(lim.five_hour.used) .. until_(lim.five_hour.resets), lim.five_hour.used
        local w = lim.seven_day or { used = 0, resets = 0 }
        text.ai_lim2 = tr("Week (7 days)")
        text.ai_lim2p, fact.ai_l2 = percent(w.used) .. until_(w.resets), w.used
    else
        text.ai_lim1, text.ai_lim1p, fact.ai_l1 = tr("Context"), percent(ctx), ctx
        text.ai_lim2, text.ai_lim2p, fact.ai_l2 = with_n("{n} tokens in this session", tostring(u.tokens or 0)), "", -1
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
            who = (q.name or msg.provider or "") .. (mm and (" · " .. mm.name) or "")
        end
        rows[#rows + 1] = { who = who, body = msg.content or "", mine = msg.role == "user", failed = msg.ok == false }
    end
    if ai.waiting then rows[#rows + 1] = { who = p and p.name or "", body = tr("Thinking…"), mine = false, failed = false } end
    while #rows > 40 do table.remove(rows, 1) end
    model.aimsg = rows
    fact.ai_wait = ai.waiting
    fact.ai_gen = fact.ai_gen + 1
    -- the models to choose from: each service a heading, its models under it
    local choices, list = {}, {}
    for _, q in ipairs(offered()) do
        if #list >= 9 then break end
        list[#list + 1] = { name = string.upper(q.name), hint = q["local"] and tr("on this computer") or "", on = false, head = true }
        choices[#list] = false
        for _, x in ipairs(q.models) do
            if #list >= 10 then break end
            list[#list + 1] = { name = x.name, hint = "", on = p ~= nil and q.id == p.id and m ~= nil and x.id == m.id, head = false }
            choices[#list] = { provider = q.id, model = x.id }
        end
    end
    ai.choices = choices
    model.aimodel = list
    text.ai_btn_center, text.ai_btn_settings, text.ai_btn_new = tr("Lens AI centre"), tr("Settings"), tr("New session")
    text.ic_ai_center, text.ic_ai_settings, text.ic_ai_new = icons["messages"], icons["settings"], icons["message-plus"]
    text.ic_ai_send, text.ic_ai_chev, text.ic_ai_spark, text.ic_ai_check = icons["arrow-up"], icons["chevron-down"], icons["sparkles"], icons["check"]
end
local function ai_send()
    local q = (text.ai_q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local p = provider()
    if q == "" or ai.waiting or not p then return end
    local m = model_of(p)
    text.ai_q, fact.ai_typed = "", false
    ai.msgs[#ai.msgs + 1] = { role = "user", content = q, provider = p.id, model = m.id }
    ai.waiting = true
    fill_ai()
    run("latte-ai", { "send", kept.ai.chat or "new", p.id, m.id, q }, function(out)
        ai.waiting = false
        local ok, r = pcall(json.decode, out or "")
        if ok and type(r) == "table" and r.chat then
            kept.ai.chat = r.chat
            ai.usage = r.usage or {}
            -- the account's limits are the account's, not the conversation's: kept for the next session too
            if ai.usage.limits and next(ai.usage.limits) then kept.ai.limits = ai.usage.limits end
            ai.msgs[#ai.msgs + 1] = { role = "assistant", content = r.answer or "", provider = p.id, model = m.id, ok = r.ok }
            save()
        else
            ai.msgs[#ai.msgs + 1] = { role = "assistant", content = tr("No answer came."), provider = p.id, model = m.id, ok = false }
        end
        fill_ai()
    end)
end
on("ai_send", ai_send)
on("text:ai_q", function() fact.ai_typed = (text.ai_q or "") ~= "" end)
on("ai_pick", function(i)
    local c = ai.choices[(i or 0) + 1]
    if not c then return end
    kept.ai.provider, kept.ai.model = c.provider, c.model
    save()
    fill_ai()
end)
on("ai_new", function()
    kept.ai.chat, ai.msgs, ai.usage = nil, {}, {}
    save()
    fill_ai()
    focus("ai_q")
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
render = function(keep)
    local tabs = {}
    for m = 0, #MODES do
        tabs[#tabs + 1] = { label = tr(MODES[m].name), glyph = MODES[m].glyph, on = kept.mode == m, run = function() set_mode(m) end }
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
    load_lists()
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
