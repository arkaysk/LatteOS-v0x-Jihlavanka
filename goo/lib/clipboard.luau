-- LensShore's Clipboard (6B.28, 6B.32), as Raycast's Clipboard History and Tinycast's clipboard: what was copied
-- (bin/latte-clip over cliphist: when, from what app, the kind of each, pictures' thumbs and their text), Pinned first,
-- a filter of kinds (Ctrl+P), search in the text and in the text of pictures, pages turned to the side; a press pastes
-- it where one was typing. The actions: paste as plain text, copy, the text of a picture or of a QR code, to the AI,
-- edit, rename, pin, open, delete, delete what was copied lately, delete all. Paste in turn: each press of
-- Win+Shift+V pastes the next older one. What a row does is given by LensShore (`env`).
local fold = require("lib/fold")
local ctx = require("lib/ctx")
local M = {}
local function N(s) return s end

local KINDS = {
    { "all", N("All"), "clipboard" }, { "pins", N("Pinned"), "pin" }, { "text", N("Text"), "align-left" },
    { "image", N("Pictures"), "photo" }, { "file", N("Files"), "file" }, { "link", N("Links"), "link" },
    { "email", N("E-mails"), "mail" }, { "color", N("Colours"), "palette" },
}
local GLYPH = { text = "align-left", image = "photo", file = "file", link = "link", email = "mail", color = "palette" }
local list = nil                             -- latte-clip's, newest first
local st = { kind = "all", page = 1, query = nil, edit = nil, sure = nil }
local seq = nil                              -- paste in turn: { items, at, last, since }

function M.load(done)
    run("latte-clip", { "list" }, function(out)
        local ok, l = pcall(json.decode, out or "")
        list = ok and type(l) == "table" and l or {}
        done()
    end)
end
function M.editing() return st.edit end

local function pins(env) env.kept.clip_pins = env.kept.clip_pins or {} return env.kept.clip_pins end
local function names(env) env.kept.clip_names = env.kept.clip_names or {} return env.kept.clip_names end
local function plain_of(c) return c.kind == "file" and (c.text:gsub("file://", ""):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) or c.text end
local function ago(t)
    local s = os.time() - (t or 0)
    if not t or t == 0 then return "" elseif s < 60 then return tr(N("just now")) elseif s < 3600 then return (tr("{n} min ago"):gsub("{n}", s // 60))
    elseif s < 86400 then return (tr("{n} h ago"):gsub("{n}", s // 3600)) elseif s < 172800 then return tr("yesterday") end
    return os.date("%-d. %-m.", t)
end
local function title(c, env)
    local named = names(env)[c.key or c.id]
    if named then return named end
    if c.kind == "image" then
        local k, w, h = c.text:match("(%w+) (%d+)x(%d+) %]%]$")
        return tr(N("Picture")) .. (w and (" · " .. w .. " × " .. h) or "")
    end
    return c.kind == "file" and (plain_of(c):match("([^/]+)/?$") or c.text) or c.text
end

-- onto the clipboard: from the history by its id, or a pinned one kept by LatteOS itself
local function put(c, plain)
    return function(done)
        if c.file then run("wl-copy", { "--type", "image/png" }, function() done() end, { stdin = c.file, output = false })
        elseif c.pinned then run("wl-copy", plain and { "--type", "text/plain", "--", c.text } or { "--", c.text }, function() done() end, { output = false })
        elseif plain then run("sh", { "-c", "cliphist decode " .. tonumber(c.id) .. " | wl-copy --type text/plain" }, function() done() end, { output = false })
        else run("sh", { "-c", "cliphist decode " .. tonumber(c.id) .. " | wl-copy" }, function() done() end, { output = false }) end
    end
end
local function paste(c, env, plain) env.paste_with(put(c, plain)) end
local function copy(c, env, plain) put(c, plain)(function() end) end
local function primary(c, env) if env.settings.lens_clip_enter == "copy" then copy(c, env) else paste(c, env) end end

local function pin(c, env)
    local p = pins(env)
    for i, x in ipairs(p) do if x.key == (c.key or c.text) then table.remove(p, i) env.save() return env.render(true) end end
    if c.kind == "image" then
        -- a pinned picture is kept by LatteOS, not by the history, which may forget it
        run("latte-clip", { "file", c.id }, function(out)
            local path = (out or ""):gsub("%s+$", "")
            if path == "" then return end
            local home = env.data_dir .. "/clipboard-pins"
            run("sh", { "-c", 'mkdir -p "$1" && cp "$2" "$1/$3.png"', "sh", home, path, c.id }, function()
                table.insert(p, 1, { key = c.text, kind = "image", text = c.text, file = home .. "/" .. c.id .. ".png", thumb = home .. "/" .. c.id .. ".png" })
                env.save() env.render(true)
            end)
        end)
    else
        table.insert(p, 1, { key = c.text, kind = c.kind, text = c.text, thumb = c.thumb })
        env.save() env.render(true)
    end
end
local function forget(ids, env, done) local args = { "delete" } for _, i in ipairs(ids) do args[#args + 1] = i end run("latte-clip", args, function() M.load(function() env.render(true) if done then done() end end) end) end

local function actions(c, env)
    local copying = env.settings.lens_clip_enter == "copy"
    local pinned = false
    for _, x in ipairs(pins(env)) do if x.key == (c.key or c.text) then pinned = true end end
    local rows = {
        { label = env.main, glyph = "clipboard", keys = not copying and "↵" or "Ctrl+↵", run = function() env.close() paste(c, env) end },
        { label = tr("Copy"), glyph = "copy", keys = copying and "↵" or "Ctrl+↵", run = function() env.close() copy(c, env) end },
    }
    if c.kind ~= "image" then rows[#rows + 1] = { label = tr(N("Paste as plain text")), glyph = "align-left", run = function() env.close() paste(c, env, true) end } end
    if c.kind == "image" and not c.pinned then
        rows[#rows + 1] = { label = tr(N("Copy the text from the picture")), glyph = "text-scan-2", line = true, run = function()
            env.close() run("latte-clip", { "ocr", c.id }, function(out) local t = (out or ""):gsub("%s+$", "") if t ~= "" then env.copy(t) end end) end }
        rows[#rows + 1] = { label = tr(N("Copy the text of the QR code")), glyph = "qrcode", run = function()
            env.close() run("latte-clip", { "qr", c.id }, function(out) local t = (out or ""):gsub("%s+$", "") if t ~= "" then env.copy(t) end end) end }
    end
    if c.kind == "link" then rows[#rows + 1] = { label = tr("Open the link"), glyph = "world", line = true, run = function() env.close() env.open_url(c.text:match("^%s*(.-)%s*$")) end } end
    if c.kind == "file" then rows[#rows + 1] = { label = tr("Open"), glyph = "external-link", line = true, run = function() env.close() env.open_path(plain_of(c)) end } end
    if c.kind == "email" then rows[#rows + 1] = { label = tr(N("Write an e-mail")), glyph = "mail", line = true, run = function() env.close() env.open_url("mailto:" .. c.text:match("^%s*(.-)%s*$")) end } end
    rows[#rows + 1] = { label = tr(N("Send to the AI")), glyph = "sparkles", line = c.kind ~= "link" and c.kind ~= "file" and c.kind ~= "email",
                        run = function()
                            if c.kind == "image" then
                                if c.file then env.ask_ai("", c.file) else run("latte-clip", { "file", c.id }, function(out) env.ask_ai("", (out or ""):gsub("%s+$", "")) end) end
                            else env.ask_ai(c.text, nil) end
                        end }
    if c.kind ~= "image" and not c.pinned then
        rows[#rows + 1] = { label = tr(N("Edit the content…")), glyph = "pencil", line = true, run = function() st.edit = { what = "text", c = c } env.set_text(c.text) env.render(true) end }
    end
    rows[#rows + 1] = { label = tr(N("Rename…")), glyph = "cursor-text", keys = "Ctrl+E", line = c.kind == "image" or c.pinned,
                        run = function() st.edit = { what = "name", c = c } env.set_text(names(env)[c.key or c.id] or "") env.render(true) end }
    rows[#rows + 1] = { label = pinned and tr("Unpin") or tr("Pin"), glyph = "pin", keys = "Ctrl+.", run = function() pin(c, env) end }
    if not c.pinned then
        rows[#rows + 1] = { label = tr(N("Delete")), glyph = "trash", danger = true, keys = "Ctrl+X", line = true, run = function() forget({ c.id }, env) end }
        local sub = {}
        for _, m in ipairs({ { 5, N("The last 5 minutes") }, { 15, N("The last 15 minutes") }, { 30, N("The last 30 minutes") }, { 60, N("The last hour") }, { 1440, N("The last 24 hours") } }) do
            sub[#sub + 1] = { label = tr(m[2]), run = function() run("latte-clip", { "since", tostring(m[1]) }, function() M.load(function() env.render(true) end) end) end }
        end
        rows[#rows + 1] = { label = tr(N("Delete what was copied…")), glyph = "trash", danger = true, sub = sub }
        rows[#rows + 1] = { label = st.sure == "all" and tr(N("Really delete it all? Press again")) or tr(N("Delete it all")), glyph = "trash", danger = true, keys = "Ctrl+Shift+X",
                            run = function()
                                if st.sure ~= "all" then st.sure = "all" return ctx.open(actions(c, env), { width = 320 }) end
                                st.sure = nil
                                run("cliphist", { "wipe" }, function() M.load(function() env.render(true) end) end)
                            end }
    end
    return rows
end

-- Enter while editing: the text replaces the entry (it comes back as the newest), or the name is kept
function M.finish_edit(text, env)
    local e = st.edit
    st.edit = nil
    if not e then return end
    if e.what == "name" then
        names(env)[e.c.key or e.c.id] = text ~= "" and text or nil
        env.save()
    elseif text ~= "" then
        run("latte-clip", { "replace", e.c.id }, function() after(400, function() M.load(function() env.render(true) end) end) end, { input = text })
    end
    env.set_text("")
end

local function wanted(c, env, want)
    if st.kind ~= "all" and st.kind ~= "pins" and c.kind ~= st.kind then return false end
    if want == "" then return true end
    return fold(title(c, env) .. " " .. c.text .. " " .. (c.ocr or "")):find(want, 1, true) ~= nil
end
local function kind_label() for _, k in ipairs(KINDS) do if k[1] == st.kind then return tr(k[2]) end end return "" end

function M.sections(q, env)
    local out = {}
    if st.edit then
        out[#out + 1] = { { label = st.edit.what == "name" and tr(N("A name for it: type it and press Enter")) or tr(N("Change the text and press Enter: it goes back into the history")),
                            line2 = title(st.edit.c, env), glyph = "pencil", quiet = true } }
        return out
    end
    if not list then
        out[#out + 1] = { { label = tr(N("Searching…")), glyph = "clipboard", quiet = true } }
        return out
    end
    if q ~= st.query then st.query, st.page = q, 1 end
    local want = fold(q)
    local items = {}
    for _, p in ipairs(pins(env)) do
        local c = table.clone(p)
        c.pinned, c.id = true, "pin:" .. p.key
        if wanted(c, env, want) then items[#items + 1] = { c = c, section = tr(N("PINNED")) } end
    end
    if st.kind ~= "pins" then
        for _, c in ipairs(list) do
            local is_pin = false
            for _, p in ipairs(pins(env)) do if p.key == c.text then is_pin = true end end
            if not is_pin and wanted(c, env, want) then items[#items + 1] = { c = c, section = tr(N("CLIPBOARD")) } end
        end
    end
    local PER = 6
    local pages = math.max(1, math.ceil(#items / PER))
    st.page = math.clamp(st.page, 1, pages)
    local function turn(d) return function() st.page = math.clamp(st.page + d, 1, pages) env.render(true) end end
    out[#out + 1] = { { pills = {
        { label = "‹", keep = true, skip = true, off = st.page <= 1, run = turn(-1) },
        { label = kind_label() .. (pages > 1 and ("  " .. st.page .. "/" .. pages) or ""), glyph = "chevron-down", keep = true, skip = true, run = function() M.kinds(env) end },
        { label = "›", keep = true, skip = true, off = st.page >= pages, run = turn(1) },
    }, per = 3, line = true } }
    if #items == 0 then
        out[#out + 1] = { { label = tr(q ~= "" and N("Nothing like that was copied") or N("Nothing was copied yet")), glyph = "clipboard", quiet = true } }
        return out
    end
    -- the rows of this page, a heading where the section changes; at the bottom edge LensShore reads them upwards
    local section, rows = nil, nil
    for i = (st.page - 1) * PER + 1, math.min(#items, st.page * PER) do
        local it = items[i]
        local c = it.c
        if it.section ~= section then
            if rows then out[#out] = env.near_line(rows) end
            section = it.section
            rows = { { head = true, label = section } }
            out[#out + 1] = rows
        end
        local where = { tr(KINDS[({ text = 3, image = 4, file = 5, link = 6, email = 7, color = 8 })[c.kind] or 3][2]) }
        if (c.app or "") ~= "" then where[#where + 1] = c.app end
        if (c.time or 0) > 0 then where[#where + 1] = ago(c.time) end
        rows[#rows + 1] = { label = title(c, env), line2 = table.concat(where, " · "), icon = c.thumb or "", glyph = GLYPH[c.kind] or "clipboard",
                            main = env.settings.lens_clip_enter == "copy" and tr("Copy") or env.main, first = i == (st.page - 1) * PER + 1, clip = c,
                            run = function() primary(c, env) end, right = function() ctx.open(actions(c, env), { width = 320 }) end }
    end
    out[#out] = env.near_line(rows)          -- at the bottom edge the newest is nearest the line
    return out
end

function M.kinds(env)
    local rows = {}
    for _, k in ipairs(KINDS) do rows[#rows + 1] = { label = tr(k[2]), glyph = k[3], on = st.kind == k[1], line = k[1] == "text", run = function() st.kind, st.page = k[1], 1 env.render(true) end } end
    ctx.open(rows, { width = 220, keys = true })
end

-- the keys: 1 Ctrl+Enter the other of paste and copy, 2 Ctrl+. pin, 3 Ctrl+E rename, 7/8 the pages, 9 Ctrl+P the kinds,
-- 10 Ctrl+X delete, 11 Ctrl+Shift+X delete it all (asked twice)
function M.combo(n, it, env)
    local c = it and it.clip
    if n == 1 and c then env.close() if env.settings.lens_clip_enter == "copy" then paste(c, env) else copy(c, env) end
    elseif n == 2 and c then pin(c, env)
    elseif n == 3 and c then st.edit = { what = "name", c = c } env.set_text(names(env)[c.key or c.id] or "") env.render(true)
    elseif n == 7 or n == 8 then st.page = math.max(1, st.page + (n == 7 and 1 or -1)) env.render(true)
    elseif n == 9 then M.kinds(env)
    elseif n == 10 and c and not c.pinned then forget({ c.id }, env)
    elseif n == 11 and c then ctx.open(actions(c, env), { width = 320, keys = true }) end
end

-- Paste in turn (Win+Shift+V): the newest first, then each press the one older; it starts over after 30 seconds, or
-- when something new was copied that was not pasted by it. A line after each text when the Settings say so.
function M.paste_next(env)
    M.load(function()
        local now = os.time()
        local newest = list[1]
        if not seq or now - seq.since > 30 or (newest and seq.last and newest.text ~= seq.last.text) then
            seq = { items = table.clone(list), at = 0, since = now }
        end
        seq.at += 1
        seq.since = now
        local c = seq.items[seq.at]
        if not c then seq = nil return end
        seq.last = c
        if env.settings.lens_clip_newline and c.kind ~= "image" then
            env.paste_with(function(done) run("sh", { "-c", 'cliphist decode "$1" | { cat; printf "\\n"; } | wl-copy', "sh", c.id }, function() done() end, { output = false }) end)
        else env.paste_with(put(c)) end
    end)
end
function M.reset_sequence() seq = nil end

return M
