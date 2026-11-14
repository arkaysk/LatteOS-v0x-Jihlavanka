-- LensShore's Files view (ROADMAP 6B.50): Raycast's Search Files — the files on the left (what was opened lately, or what the line
-- finds by name, by kind), and on the right a preview of the one chosen with what is known of it. The choice is told by the card
-- (card.luau `on_choose`), by the keys and by the pointer alike. The work is done by what LatteOS has already: `latte-files recent`
-- and `latte-files thumb`, `latte-props info` for the metadata, `fd` for the finding.
local icons = require("lib/icons")

local M = {}
local function N(s) return s end

local FILTERS = {
    { id = "any", name = N("Any") },
    { id = "docs", name = N("Documents"), ext = { "pdf", "doc", "docx", "odt", "txt", "md", "rtf", "xls", "xlsx", "ods", "ppt", "pptx", "odp", "csv" } },
    { id = "images", name = N("Images"), ext = { "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tif", "tiff", "heic", "avif" } },
    { id = "video", name = N("Videos"), ext = { "mp4", "mkv", "webm", "avi", "mov", "m4v" } },
    { id = "audio", name = N("Audio"), ext = { "mp3", "flac", "ogg", "wav", "m4a", "opus" } },
    { id = "folders", name = N("Folders"), dirs = true },
}
local GLYPH = { images = "photo", video = "movie", audio = "music", docs = "file-text", folders = "folder" }

local state = { filter = "any", recent = nil, found = nil, asked = 0, cur = nil, shown = nil }
local cache = {}                                  -- what is known of a path: { info, pic } (kept while it is unchanged)
local home = ""

local function filter() for _, f in ipairs(FILTERS) do if f.id == state.filter then return f end end return FILTERS[1] end
local function ext_of(path) return (path:match("%.([%w]+)$") or ""):lower() end
local function kind_of(path)
    local e = ext_of(path)
    for _, f in ipairs(FILTERS) do for _, x in ipairs(f.ext or {}) do if x == e then return f.id end end end
    return nil
end
local function fits(path, dir)
    local f = filter()
    if f.id == "any" then return true end
    if f.dirs then return dir end
    return (not dir) and kind_of(path) == f.id
end
local function human(n)
    n = tonumber(n) or 0
    if n < 1024 then return string.format("%d B", n) end
    local u = { "KB", "MB", "GB", "TB" }
    local i = 0
    repeat n, i = n / 1024, i + 1 until n < 1024 or i == #u
    return string.format(n < 10 and "%.1f %s" or "%.0f %s", n, u[i])
end
local function when(t) t = tonumber(t) if not t or t <= 0 then return "" end return os.date("%d. %m. %Y %H:%M", t) end
local function middle(s, n)                         -- a long value shortened in the middle: the start and the end both tell
    if #s <= n then return s end
    local k = (n - 1) // 2
    return s:sub(1, k) .. "…" .. s:sub(-k)
end

-- ── the left: lately opened files, or what the line finds ────────────────────────────────────────────────────────────
function M.load(again, home_dir)
    home = home_dir or ""
    run("latte-files", { "recent" }, function(out)
        state.recent = {}
        for line in (out or ""):gmatch("[^\n]+") do
            local path = line:match("^(.-)\t")
            if path then state.recent[#state.recent + 1] = path end
        end
        again()
    end)
end
function M.reset() state.found, state.asked, state.cur, state.shown = nil, 0, nil, nil end
function M.filter_id() return state.filter end

-- what the line finds by name, in the home folder and in `roots` (Goo's `lens_files_roots`, more folders to look in): fd looks for the longest
-- word, the others are asked of the name here; ranked as a launcher ranks (the name starts as typed, words start words, lately opened first).
-- Not hidden by .gitignore (a file is not lost to a project's rules); what is only noise is left out.
local NOISE = { "node_modules", "target", ".git", ".cache", "__pycache__", "Trash", ".var", ".npm", ".cargo", ".rustup", ".mozilla" }
local function score(path, words, query, lately)
    local name = (path:match("([^/]+)/?$") or path):lower()
    local bare = name:gsub("%.[%w]+$", "")
    local s = 0
    if bare == query or name == query then s = 1000
    elseif name:sub(1, #query) == query then s = 800
    else
        local all_start, all_in = true, true
        for _, w in ipairs(words) do
            if not (name:sub(1, #w) == w or name:find("[%s_%-%.]" .. w:gsub("%p", "%%%0"))) then all_start = false end
            if not name:find(w, 1, true) then all_in = false end
        end
        s = (all_start and 600) or (name:find(query, 1, true) and 500) or (all_in and 400) or 200
    end
    return s + (lately and (150 - math.min(lately, 100)) or 0) - #name / 10
end
function M.search(text, again, roots)
    state.asked += 1
    local mine = state.asked
    state.found = nil
    state.roots = roots or state.roots
    roots = state.roots
    if text == "" or home == "" then again() return end
    local query = text:lower()
    local words = {}
    for w in query:gmatch("%S+") do words[#words + 1] = w end
    local longest = words[1] or query
    for _, w in ipairs(words) do if #w > #longest then longest = w end end
    local args = { "--no-ignore-vcs", "--max-results", "400", "--absolute-path", "--ignore-case", "--fixed-strings" }
    for _, n in ipairs(NOISE) do args[#args + 1] = "-E" args[#args + 1] = n end
    local f = filter()
    if f.dirs then args[#args + 1] = "--type" args[#args + 1] = "d" end
    for _, e in ipairs(f.ext or {}) do args[#args + 1] = "-e" args[#args + 1] = e end
    args[#args + 1] = "--" args[#args + 1] = longest
    args[#args + 1] = home
    for _, r in ipairs(roots or {}) do if r ~= home then args[#args + 1] = r end end
    local lately = {}
    for i, p in ipairs(state.recent or {}) do lately[p] = i end
    local function finish(list)
        table.sort(list, function(a, b) return a.score > b.score end)
        state.found = {}
        for i = 1, math.min(#list, 36) do state.found[i] = list[i].path end
        again()
    end
    run("fd", args, function(out)
        if mine ~= state.asked then return end             -- something else has been typed since
        local list = {}
        for path in (out or ""):gmatch("[^\n]+") do
            local lower, ok = path:lower(), true
            for _, w in ipairs(words) do if not lower:find(w, 1, true) then ok = false break end end      -- every word, in the name or the folders
            if ok then list[#list + 1] = { path = path, score = score(path, words, query, lately[path:gsub("/$", "")]) } end
        end
        if #list >= 3 or #longest < 4 then return finish(list) end
        -- hardly anything: a slip of the finger? the letters of the longest word in their order, with anything between (fzf's way), asked once more
        local pattern = {}
        for ch in longest:gmatch(".") do pattern[#pattern + 1] = ch:gsub("%p", "\\%0") end
        local loose = {}
        for _, a in ipairs(args) do if a ~= "--fixed-strings" then loose[#loose + 1] = a end end
        for i, a in ipairs(loose) do if a == longest then loose[i] = table.concat(pattern, ".*") end end
        run("fd", loose, function(out2)
            if mine ~= state.asked then return end
            local seen = {}
            for _, e in ipairs(list) do seen[e.path] = true end
            for path in (out2 or ""):gmatch("[^\n]+") do
                local name = (path:match("([^/]+)/?$") or ""):lower()
                -- the letters must lie in the name, not only in the folders; the nearer together, the better
                local at, first, ok = 1, nil, true
                for ch in longest:gmatch(".") do
                    local f = name:find(ch, at, true)
                    if not f then ok = false break end
                    first = first or f
                    at = f + 1
                end
                -- close together: the letters lie within three more than their number (a slip, not a scatter over a long name)
                if ok and (at - first) <= #longest + 3 and not seen[path] then list[#list + 1] = { path = path, score = 100 - #name / 5 } end
            end
            finish(list)
        end)
    end)
end

-- the rows of the left column; `env` brings what lives in lens.luau: then_do, open_path(path), menu(path, parent, folder)
function M.rows(typed, env, again)
    local rows = {}
    -- the kind of file, as Raycast's "Any": one button that goes through them (the panel is narrow, and never wider than LensShore)
    local at = 1
    for i, f in ipairs(FILTERS) do if f.id == state.filter then at = i end end
    local nextf = FILTERS[at % #FILTERS + 1]
    local pills = { { label = tr(filter().name), glyph = "adjustments-horizontal", keep = true, skip = true,
                      run = function() state.filter = nextf.id M.search(typed, again, state.roots) again() end } }
    rows[1] = { head = true, label = typed == "" and tr(N("RECENTLY OPENED")) or tr(N("FILES")) }
    local list = typed == "" and state.recent or state.found
    local n = 0
    state.shown = {}
    for _, path in ipairs(list or {}) do
        local dir = path:sub(-1) == "/"
        local clean = dir and path:sub(1, -2) or path
        -- ponytail: a recent path without an extension is taken for a folder; a stat would tell
        if typed ~= "" or fits(clean, dir or not clean:match("%.[%w]+$")) then
            local parent = clean:match("^(.*)/[^/]*$") or "/"
            local name = clean:match("([^/]+)$") or clean
            rows[#rows + 1] = { label = name, glyph = GLYPH[kind_of(clean) or ""] or (dir and "folder" or "file"), line2 = env.short(parent), path = clean,
                                main = tr("Open"), first = n == 0, run = function() env.then_do(function() env.open_path(clean) end) end,
                                right = function() env.menu(clean, parent, dir) end }
            n += 1
            state.shown[clean] = true
            if n >= 36 then break end
        end
    end
    if n == 0 then rows[#rows + 1] = { label = list == nil and typed ~= "" and tr("Searching…") or tr("Nothing found"), glyph = "search", quiet = true } end
    return rows, { pills = pills, per = #pills, line = true }
end

-- ── the right: the picture, and what is known of the file ──────────────────────────────────────────────────────────
-- the one chosen: asked for once, kept; `again` draws the card anew when its answer is there
function M.choose(row, again)
    local path = row and row.path
    if not path then return end
    state.cur = path
    if cache[path] then again() return end
    run("latte-props", { "info", path }, function(out)
        local ok, list = pcall(json.decode, out or "")
        local info = ok and type(list) == "table" and list[1] or nil
        if not info then return end
        local entry = { info = info }
        cache[path] = entry
        local mime = info.mime or ""
        if mime:find("^image/") then
            entry.pic = path
            again()
        elseif mime == "application/pdf" or mime:find("^video/") then
            again()
            run("latte-files", { "thumb", path }, function(thumb)
                thumb = (thumb or ""):gsub("%s+$", "")
                if thumb ~= "" then entry.pic = thumb if state.cur == path then again() end end
            end)
        else
            again()
        end
    end)
end

function M.right()
    local entry = state.cur and state.shown and state.shown[state.cur] and cache[state.cur]       -- only one of the files in the list
    local rows = {}
    if not entry then
        rows[1] = { label = tr("Choose a file"), glyph = "search", quiet = true, col = 2 }
        model.card_pic = {}
        return rows
    end
    local i = entry.info
    if entry.pic then
        model.card_pic = { { pic = entry.pic } }
        rows[1] = { pic = true, col = 2 }
    else
        model.card_pic = {}
        rows[1] = { profile = true, glyph = i.dir and "folder" or "file", label = i.name or "", line2 = i.kind or "", quiet = true, col = 2 }
    end
    local function add(key, value) if value and value ~= "" then rows[#rows + 1] = { label = tr(key), hint = middle(tostring(value), 24), quiet = true, col = 2 } end end
    add(N("Where"), home ~= "" and (i.where or ""):gsub("^" .. home:gsub("%p", "%%%0"), "~") or i.where)
    add(N("Type"), i.kind)
    add(N("Size"), not i.dir and human(i.size) or nil)
    add(N("Modified"), when(i.modified))
    return rows
end

return M
