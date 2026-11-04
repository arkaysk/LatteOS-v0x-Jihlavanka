-- Properties (props.plm): reads what the files are from `latte-props`, shows the one chosen, keeps what the user
-- changes until OK or Apply, then writes it — the name through `latte-files`, so Ctrl+Z in DualBrew takes it back.
-- Several files are tabs: "All (N)" first, where what is changed is changed for all of them and what differs says so
-- (as Windows does), then each file, then "Compare", their properties side by side (ROADMAP 10L.01).
local COLOURS = { "red", "orange", "yellow", "green", "blue", "purple" }

local paths = {}
local files = {}                               -- what latte-props said, one a path
local edits = {}                               -- path → { what changed }
local tab = 0                                  -- the tab shown: with several files 0 is All, then the files, then Compare
local dates = {}                               -- seconds → as the user's language writes them (by `date`)

local function bytes(n)
    n = tonumber(n) or 0
    local units, v, i = { "B", "KB", "MB", "GB", "TB" }, n, 1
    while v >= 1024 and i < 5 do v /= 1024; i += 1 end
    local grouped = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
    local short = i == 1 and string.format("%d %s", n, units[1]) or string.format("%.1f %s", v, units[i]):gsub("%.", ",")
    return short, grouped
end
local function sub(s, t) for k, v in pairs(t) do s = s:gsub("{" .. k .. "}", tostring(v)) end; return s end

local function mode_text(m)
    local bits, out = tonumber(m, 8) or 0, ""
    for i = 8, 0, -1 do out ..= (bit32.band(bits, 2 ^ i) ~= 0) and ("rwx"):sub(3 - i % 3, 3 - i % 3) or "-" end
    return out
end

-- what is shown is the file as it is, with what the user changed on top
local function val(f, k)
    local e = edits[f.path]
    if e and e[k] ~= nil then return e[k] end
    return f[k]
end

local function several() return #files > 1 end
local function mode() if not several() then return "file" elseif tab == 0 then return "all" elseif tab > #files then return "cmp" end return "file" end
local function file() return files[several() and tab or 1] end
-- the files a change goes to: the one shown, or all of them on All
local function targets() if mode() == "all" then return files end local f = file(); return f and { f } or {} end
-- the value all of them share, or nil when they differ
local function common(k) local v; for i, f in ipairs(files) do local x = val(f, k); if i == 1 then v = x elseif x ~= v then return nil end end; return v end

-- the times, written in the user's language; asked once each, then the view is drawn again
local function when(t) if not t or t == 0 then return "—" end return dates[t] or "…" end
local function ask_dates(then_)
    local want = {}
    for _, f in ipairs(files) do for _, k in ipairs({ "created", "modified", "accessed" }) do
        local t = f[k] or 0
        if t > 0 and not dates[t] then want[t] = true end
    end end
    local left = 0
    for _ in pairs(want) do left += 1 end
    if left == 0 then return then_() end
    for t in pairs(want) do
        run("date", { "-d", "@" .. t, "+%A %-d. %-m. %Y, %H:%M" }, function(out)
            dates[t] = (out or ""):match("[^\n]*")
            left -= 1
            if left == 0 then then_() end
        end)
    end
end

local function opener_name(f)
    local id = val(f, "opener")
    for _, a in ipairs(f.openers or {}) do if a.id == id then return a.name end end
    return f.opener_name ~= "" and f.opener_name or tr("Nothing chosen")
end
local function tag_of(tags) for i, c in ipairs(COLOURS) do if (tags or ""):find(c) then return i end end return 0 end

local function size_text(n) local short, long = bytes(n); return short .. "  (" .. sub(tr("{n} bytes"), { n = long }) .. ")" end

-- ACL: the file's list with the user's changes on top; the changes are commands kept for OK or Apply
local function acl_now(f)
    local list = {}
    for _, a in ipairs(f.acl or {}) do list[#list + 1] = { kind = a.kind, who = a.who, perm = a.perm } end
    for _, op in ipairs(val(f, "acl_ops") or {}) do
        local kind, who, perm = op.v:match("^(%a):([^:]+):?(.*)$")
        if op.k == "acl+" then list[#list + 1] = { kind = "?", who = op.v, perm = "r--" }
        else
            for i, a in ipairs(list) do
                if a.who == (who or op.v) and (a.kind == kind or a.kind == "?") then
                    if op.k == "acl-" then table.remove(list, i) else a.perm = perm end
                    break
                end
            end
        end
    end
    return list
end
local function show_acl(f)
    local rows = {}
    for i, a in ipairs(acl_now(f)) do
        if i <= 12 then rows[i] = { who = a.kind == "g" and (a.who .. "  (" .. tr("group") .. ")") or a.who, group = a.kind == "g", r = a.perm:sub(1, 1) == "r", w = a.perm:sub(2, 2) == "w", x = a.perm:sub(3, 3) == "x" } end
    end
    model.aclm = rows
end
local function acl_op(k, v)
    local f = file()
    if not f then return end
    local ops = table.clone(val(f, "acl_ops") or {})
    ops[#ops + 1] = { k = k, v = v }
    edit("acl_ops", function() return ops end)
end
on("acl_bit", function(n)
    local f = file(); if not f then return end
    local a = acl_now(f)[math.floor(n / 3) + 1]
    if not a or a.kind == "?" then return end
    local i = n % 3 + 1
    local letters = { "r", "w", "x" }
    local perm = a.perm:sub(1, i - 1) .. (a.perm:sub(i, i) == "-" and letters[i] or "-") .. a.perm:sub(i + 1)
    acl_op("acl", a.kind .. ":" .. a.who .. ":" .. perm)
end)
on("acl_del", function(i)
    local f = file(); if not f then return end
    local a = acl_now(f)[i + 1]
    if not a then return end
    if a.kind ~= "?" then acl_op("acl-", a.kind .. ":" .. a.who); return end
    -- one added a moment ago and not written yet: its adding is taken back
    local ops = {}
    for _, op in ipairs(val(f, "acl_ops") or {}) do if not (op.k == "acl+" and op.v == a.who) then ops[#ops + 1] = op end end
    edit("acl_ops", function() return ops end)
end)
on("acl_add", function()
    local who = (text.acl_new or ""):match("^%s*([%w._-]+)%s*$")
    if not who then return end
    text.acl_new = ""
    acl_op("acl+", who)
end)

local function show_file(f)
    text.p_title = sub(tr("{name} — Properties"), { name = f.name })
    text.p_name = val(f, "name")
    text.p_kind = tr(f.kind) .. "  ·  " .. f.mime
    text.p_icon = f.icon or ""
    text.p_where = f.where
    fact.p_dir = f.dir
    fact.p_launcher = f.mime == "application/x-desktop"
    if f.dir then
        text.p_size = sub(tr("{n} items ({f} files, {d} folders)"), { n = f.files + f.dirs, f = f.files, d = f.dirs }) .. " · " .. (bytes(f.size)) .. (f.partial and " +" or "")
        text.p_disk = (bytes(f.disk))
        if f.fs_size then
            text.p_fs = sub(tr("{used} of {size} used"), { used = (bytes(f.fs_used)), size = (bytes(f.fs_size)) }) .. "  ·  " .. (f.fs_at or "")
            fact.p_fs_frac = f.fs_used / math.max(f.fs_size, 1)
        end
    else
        text.p_size = size_text(f.size)
        text.p_disk = size_text(f.disk)
    end
    text.p_opener = opener_name(f)
    model.openers = (function() local o = {}; for i, a in ipairs(f.openers or {}) do if i <= 12 then o[i] = { name = a.name } end end; return o end)()
    local m = tonumber(val(f, "mode"), 8) or 0
    fact.p_readonly = bit32.band(m, 0x92) == 0         -- 0o222: nobody may write
    fact.p_exec = bit32.band(m, 0x49) ~= 0             -- 0o111
    fact.p_hidden = val(f, "hidden")
    for i = 0, 8 do fact["pb." .. i] = bit32.band(m, 2 ^ (8 - i)) ~= 0 end
    text.p_permtext = mode_text(val(f, "mode")) .. "  ·  " .. val(f, "mode")
    text.p_owner = f.owner .. (f.mine and ("  (" .. tr("you") .. ")") or "")
    text.p_group = f.group
    text.p_selinux = f.selinux ~= "" and f.selinux or "—"
    fact.p_has_origin = val(f, "origin") ~= ""
    text.p_origin = val(f, "origin")
    text.p_comment = val(f, "comment")
    show_acl(f)
    text.p_touch = (edits[f.path] or {}).touch or ""
    text.p_sum = ""
    fact.p_rating = math.floor((tonumber(val(f, "rating")) or 0) / 2)
    fact.p_tag = tag_of(val(f, "tags"))
    text.p_created, text.p_modified, text.p_accessed = when(f.created), when(f.modified), when(f.accessed)
end

local function show_all()
    local various = tr("various")
    text.p_title = sub(tr("{n} items — Properties"), { n = #files })
    text.p_allname = sub(tr("{n} items"), { n = #files })
    local kind = common("kind")
    text.p_kind = kind and tr(kind) or tr("various kinds")
    text.p_icon = files[1].icon or ""
    text.p_where = common("where") or various
    fact.p_dir = false
    -- one app opens them all only if they are of one kind
    local mime = common("mime")
    fact.p_launcher = not mime or mime == "application/x-desktop" or mime == "inode/directory"
    if mime then text.p_opener = opener_name(files[1]); model.openers = (function() local o = {}; for i, a in ipairs(files[1].openers or {}) do if i <= 12 then o[i] = { name = a.name } end end; return o end)() end
    local size, disk = 0, 0
    for _, f in ipairs(files) do size += f.size or 0; disk += f.disk or 0 end
    text.p_size, text.p_disk = size_text(size), size_text(disk)
    local function shared_time(k) local t = common(k); return t and when(t) or various end
    text.p_created, text.p_modified, text.p_accessed = shared_time("created"), shared_time("modified"), shared_time("accessed")
    -- a switch is on only when it is on for all of them; pressed, it is set for all of them
    local ro, ex, hid = true, true, true
    for _, f in ipairs(files) do
        local m = tonumber(val(f, "mode"), 8) or 0
        ro = ro and bit32.band(m, 0x92) == 0
        ex = ex and bit32.band(m, 0x49) ~= 0
        hid = hid and val(f, "hidden") == true
    end
    fact.p_readonly, fact.p_exec, fact.p_hidden = ro, ex, hid
    fact.p_has_origin = false
    text.p_comment = common("comment") or ""
    local r = common("rating")
    fact.p_rating = r and math.floor((tonumber(r) or 0) / 2) or 0
    local t = common("tags")
    fact.p_tag = t and tag_of(t) or 0
end

-- Compare: a row a property, a column a file (four at most), what differs in gold
local function show_cmp()
    text.p_title = sub(tr("Comparing {n} items"), { n = #files })
    local rows = {
        { tr("Type"), function(f) return tr(f.kind) end },
        { tr("Size"), function(f) return (bytes(f.size)) end },
        { tr("On disk"), function(f) return (bytes(f.disk)) end },
        { tr("Created"), function(f) return when(f.created) end },
        { tr("Modified"), function(f) return when(f.modified) end },
        { tr("Opened"), function(f) return when(f.accessed) end },
        { tr("Opens with"), function(f) return f.dir and "—" or opener_name(f) end },
        { tr("Owner"), function(f) return f.owner end },
        { tr("Rights"), function(f) return mode_text(val(f, "mode")) end },
        { tr("Rating"), function(f) local k = math.floor((tonumber(val(f, "rating")) or 0) / 2); return k > 0 and string.rep("★", k) or "—" end },
        { tr("Location"), function(f) return f.where end },
        { tr("Comment"), function(f) local c = val(f, "comment"); return c ~= "" and c or "—" end },
    }
    local out = {}
    for i, r in ipairs(rows) do
        local cells, diff = {}, false
        for j = 1, math.min(#files, 4) do cells[j] = r[2](files[j]) or ""; if j > 1 and cells[j] ~= cells[1] then diff = true end end
        out[i] = { label = r[1], a = cells[1] or "", b = cells[2] or "", c = cells[3] or "", d = cells[4] or "", diff = diff }
    end
    model.cmp = out
    fact.p_cols = math.min(#files, 4)
    fact.p_two_files = #files == 2 and not files[1].dir and not files[2].dir
    local heads = {}
    for j = 1, math.min(#files, 4) do heads[j] = { name = files[j].name } end
    model.cmp_heads = heads
end

local function show()
    if #files == 0 then return end
    local m = mode()
    fact.p_mode = m == "file" and 0 or (m == "all" and 1 or 2)
    if m ~= "file" then fact.sec = 0 end
    if m == "all" then show_all() elseif m == "cmp" then show_cmp() else show_file(file()) end
    local dirty = false
    for _ in pairs(edits) do dirty = true end
    fact.p_dirty = dirty
    fact.p_ready = true
end

local function load(after_)
    run("latte-props", { "info", table.unpack(paths) }, function(out)
        local ok, list = pcall(json.decode, out or "")
        if not ok or type(list) ~= "table" then return end
        files = list
        local tabs = {}
        if several() then
            tabs[1] = { name = sub(tr("All ({n})"), { n = #files }) }
            for i, f in ipairs(files) do if #tabs < 7 then tabs[#tabs + 1] = { name = f.name } end end
            tabs[#tabs + 1] = { name = tr("Compare") }
        end
        model.ftabs = tabs
        fact.p_count = #files
        tab = math.clamp(tab, 0, several() and #files + 1 or 0)
        fact.p_file = tab
        show()
        ask_dates(show)
        if after_ then after_() end
    end)
end

-- a change to the files shown (one, or all of them on All): `how(f)` gives the new value for each
local function edit(k, how)
    for _, f in ipairs(targets()) do
        edits[f.path] = edits[f.path] or {}
        edits[f.path][k] = how(f)
    end
    show()
end

-- writes everything changed, one command after another, then reads the files again
local function write(done)
    local steps = {}
    for p, e in pairs(edits) do
        for k, v in pairs(e) do
            if k == "touch" then steps[#steps + 1] = { "latte-files", { "touch", tostring(v), p } }
            elseif k == "acl_ops" then for _, op in ipairs(v) do steps[#steps + 1] = { "latte-props", { "set", p, op.k, op.v } } end
            elseif k ~= "name" then steps[#steps + 1] = { "latte-props", { "set", p, k, tostring(v) } } end
        end
        if e.name and e.name ~= p:match("[^/]*$") then
            steps[#steps + 1] = { "latte-files", { "rename", p, e.name } }
            for i, q in ipairs(paths) do if q == p then paths[i] = p:match("^(.*)/") .. "/" .. e.name end end
        end
    end
    edits = {}
    local function go(i)
        local s = steps[i]
        if not s then load(done); return end
        run(s[1], s[2], function() go(i + 1) end)
    end
    go(1)
end

-- Details: asked of latte-props once a file, when the section is opened; short or full as the switch says
local details = {}                             -- path → { short, groups }
local function show_details()
    local f = file()
    if not f or mode() ~= "file" or fact.sec ~= 2 then return end
    local d = details[f.path]
    if not d then
        fact.det_ready = false
        model.det = {}
        run("latte-props", { "details", f.path }, function(out)
            local ok, got = pcall(json.decode, out or "")
            details[f.path] = ok and type(got) == "table" and got or { short = {}, groups = {} }
            show_details()
        end)
        return
    end
    local rows = {}
    if fact.det_full == 1 then
        for _, g in ipairs(d.groups or {}) do
            rows[#rows + 1] = { k = g.g, v = "", head = true }
            for _, r in ipairs(g.rows) do if #rows < 250 then rows[#rows + 1] = { k = r.k, v = r.v, head = false } end end
        end
    else
        for _, r in ipairs(d.short or {}) do rows[#rows + 1] = { k = r.k, v = r.v, head = false } end
    end
    model.det = rows
    fact.det_ready = true
end

-- Previous versions: the file in snapper's snapshots (latte-props versions), newest first
local vers = {}
local function when_text(d)   -- "2026-11-04 18:00:00" as the rest of the window writes a time
    local y, m, dd, hh, mi = (d or ""):match("^(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    return y and string.format("%d. %d. %s, %s:%s", tonumber(dd), tonumber(m), y, hh, mi) or (d or "")
end
local function show_versions()
    local f = file()
    if not f or mode() ~= "file" then return end
    fact.vers_ready, fact.ver_sel, fact.ver_armed = false, -1, false
    model.vers = {}
    run("latte-props", { "versions", f.path }, function(out)
        local ok, list = pcall(json.decode, out or "")
        vers = ok and type(list) == "table" and list or {}
        local rows = {}
        for i, v in ipairs(vers) do
            if i <= 40 then
                local what = v.what == "timeline" and tr("taken every hour") or (v.what == "" and tr("snapshot") or v.what)
                local state = v.state == "same" and tr("the same as now") or (v.state == "changed" and tr("different") or tr("not there yet"))
                rows[i] = { when = when_text(v.date), what = what, state = state, changed = v.state == "changed" }
            end
        end
        model.vers = rows
        fact.vers_ready = true
    end)
end
on("ver_open", function() local v = vers[(fact.ver_sel or -1) + 1]; if v and v.state ~= "absent" then run("xdg-open", { v.path }, nil, { output = false }) end end)
on("ver_compare", function()
    local v, f = vers[(fact.ver_sel or -1) + 1], file()
    if v and f and v.state ~= "absent" then run("foot", { "--", "sh", "-c", 'diff -u --color=always -- "$1" "$2" | less -R', "sh", v.path, f.path }, nil, { output = false }) end
end)
-- pressed once it asks; pressed again it puts that version back (what is there now goes to the Trash: Ctrl+Z)
on("ver_restore", function()
    local v, f = vers[(fact.ver_sel or -1) + 1], file()
    if not v or not f or v.state == "absent" then return end
    if not fact.ver_armed then
        fact.ver_armed = true
        after(4000, function() fact.ver_armed = false end)
        return
    end
    fact.ver_armed = false
    run("latte-props", { "restore", f.path, tostring(v.n) }, function() load(show_versions) end)
end)

-- Checksums: counted on request; one pasted is told whether it matches the one of its length
local function check_pasted()
    local want = (text.p_verify or ""):lower():match("^%s*(%x+)%s*$")
    if not want then fact.p_match = 0; text.p_verdict = ""; return end
    local have = ({ [64] = text.p_sum, [40] = text.p_sha1, [32] = text.p_md5 })[#want]
    if not have then fact.p_match = 2; text.p_verdict = tr("Not a checksum this window knows (SHA-256, SHA-1, MD5)"); return end
    if not have:match("^%x+$") then return end       -- still being counted: told when it is done
    fact.p_match = have == want and 1 or 2
    text.p_verdict = have == want and tr("✓ It matches: the file is the one that was published") or tr("✕ It does not match")
end
local function count(cmd, into)
    local f = file()
    if not f or f.dir then return end
    text[into] = tr("Counting…")
    run(cmd, { "--", f.path }, function(out) text[into] = (out or ""):match("^(%x+)") or "—"; check_pasted() end)
end
on("sum", function() count("sha256sum", "p_sum") end)
on("sum_sha1", function() count("sha1sum", "p_sha1") end)
on("sum_md5", function() count("md5sum", "p_md5") end)
on("text:p_verify", function(t)
    local n = #((t or ""):match("%x+") or "")
    -- the one it is compared with is counted at once, if it was not
    local into = ({ [64] = "p_sum", [40] = "p_sha1", [32] = "p_md5" })[n]
    if into and not (text[into] or ""):match("^%x+$") then
        count(({ p_sum = "sha256sum", p_sha1 = "sha1sum", p_md5 = "md5sum" })[into], into)
    end
    check_pasted()
end)

-- Shortcut: a launcher's own keys, changed as the rest is, on OK or Apply
local launcher = {}
local function show_launcher()
    local f = file()
    if not f or mode() ~= "file" or f.mime ~= "application/x-desktop" then return end
    run("latte-props", { "launcher", f.path }, function(out)
        local ok, l = pcall(json.decode, out or "")
        launcher = ok and type(l) == "table" and l or {}
        local e = edits[f.path] or {}
        local function pick(k, j) local v = e["desktop." .. k]; if v ~= nil then return v end return launcher[j] or "" end
        text.l_exec, text.l_path, text.l_comment, text.l_icon = pick("Exec", "exec"), pick("Path", "path"), pick("Comment", "comment"), pick("Icon", "icon")
        local t = e["desktop.Terminal"]
        if t ~= nil then fact.l_terminal = t == "true" else fact.l_terminal = launcher.terminal == true end
    end)
end
for k, j in pairs({ Exec = "l_exec", Path = "l_path", Comment = "l_comment", Icon = "l_icon" }) do
    on("text:" .. j, function(t)
        local f = file()
        if not f or launcher[k:lower()] == nil then return end
        local now = (edits[f.path] or {})["desktop." .. k]
        if now == nil then now = launcher[k:lower()] end
        if t ~= now then edit("desktop." .. k, function() return t end) end
    end)
end
on("flip_terminal", function() local v = not fact.l_terminal; fact.l_terminal = v; edit("desktop.Terminal", function() return v and "true" or "" end) end)

-- what a section shows is read when it is opened
local function show_section()
    if fact.sec == 2 then show_details() elseif fact.sec == 3 then show_versions() elseif fact.sec == 5 then show_launcher() end
end
on("fact:sec", show_section)
on("fact:det_full", show_details)

on("pick_file", function(i)
    tab = i or 0; fact.p_file = tab; launcher = {}
    text.p_sha1, text.p_md5, text.p_verify, text.p_verdict, fact.p_match = "", "", "", "", 0
    show(); show_section()
end)
on("text:p_name", function(t) local f = file(); if mode() == "file" and f and t ~= val(f, "name") then edit("name", function() return t end) end end)
on("text:p_comment", function(t)
    if mode() == "cmp" then return end
    local now = mode() == "all" and (common("comment") or "") or val(file(), "comment")
    if t ~= now then edit("comment", function() return t end) end
end)
-- read-only for all, or the owner writes again
on("flip_ro", function()
    local on_ = not fact.p_readonly
    edit("mode", function(f)
        local m = tonumber(val(f, "mode"), 8)
        return string.format("%o", on_ and bit32.band(m, bit32.bnot(0x92)) or bit32.bor(m, 0x80))
    end)
end)
-- runnable by whoever may read it (Nautilus's switch), or by nobody
on("flip_exec", function()
    local on_ = not fact.p_exec
    edit("mode", function(f)
        local m = tonumber(val(f, "mode"), 8)
        return string.format("%o", on_ and bit32.bor(m, bit32.rshift(bit32.band(m, 0x124), 2)) or bit32.band(m, bit32.bnot(0x49)))
    end)
end)
on("perm", function(b) edit("mode", function(f) return string.format("%o", bit32.bxor(tonumber(val(f, "mode"), 8), 2 ^ (8 - b))) end) end)
on("flip_hidden", function() local on_ = not fact.p_hidden; edit("hidden", function() return on_ end) end)
on("set_rating", function(k) local v = fact.p_rating == k and 0 or k * 2; edit("rating", function() return v end) end)   -- the same star again: none
on("set_tag", function(k) local v = fact.p_tag == k and "" or COLOURS[k]; edit("tags", function() return v end) end)
on("choose_opener", function(i)
    local f = mode() == "all" and files[1] or file()
    local a = f and f.openers[i + 1]
    if a then edit("opener", function() return a.id end) end
end)
on("forget_origin", function() edit("origin", function() return "" end) end)
-- a new time for the file(s), as DualBrew's Properties gave it (latte-files touch, `date -d` reads it)
on("touch_set", function() local t = (text.p_touch or ""):match("^%s*(.-)%s*$"); if t ~= "" then edit("touch", function() return t end) end end)
on("touch_now", function() edit("touch", function() return "now" end) end)
on("open_folder", function() local f = mode() == "all" and files[1] or file(); if f then run("xdg-open", { f.where }, nil, { output = false }) end end)
-- two files: their contents side by side, as DualBrew shows them (10A.41) until 10L.09 has its own window
on("compare_contents", function()
    if #files == 2 then run("foot", { "--", "sh", "-c", 'diff -u --color=always -- "$1" "$2" | less -R', "sh", files[1].path, files[2].path }, nil, { output = false }) end
end)
on("apply", function() write() end)
on("ok", function() write(function() emit("done") end) end)

-- the colours of the windows' cup (apps/common/Theme.qml's), as every LatteOS window made with pleamar takes them
require("lib/cup").start()

local ok, list = pcall(sys.ask, "env", "LATTE_PROPS")
for p in ((ok and list) or ""):gmatch("[^\n]+") do paths[#paths + 1] = p end
if #paths > 0 then load() end
