-- The logic of What the AI changed (journal.plm): reads `latte-ai journal full [AT]` (LATTE_JOURNAL_AT: the one entry
-- of a task, else all), lays it out as lines — an entry's head, where and the task, then each item — and sends the
-- slice that is on screen. Export writes Markdown into Documents and opens it; Clear history needs two presses.
local STEP, WINDOW = 28, 24
-- {n} in a translated text: a function, so that a path with % in it stays as it is
local function sub(s, t) for k, v in pairs(t) do s = s:gsub("{" .. k .. "}", function() return tostring(v) end) end; return s end
local lines = {}
local at = -1
local only = ""

local function show(from)
    from = math.max(0, math.min(from, math.max(0, #lines - WINDOW)))
    at = from
    local slice = {}
    for k = 1, WINDOW do slice[k] = lines[from + k] end
    fact.first = from
    model.rows = slice
end

local function clock(t)        -- 2026-11-18T17:27:21 → 18. 11. 2026 17:27
    local y, m, d, hh, mm = string.match(t or "", "(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    return y and (tonumber(d) .. ". " .. tonumber(m) .. ". " .. y .. " " .. hh .. ":" .. mm) or ""
end

local function load()
    run("latte-ai", only ~= "" and { "journal", "full", only } or { "journal", "full" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        lines = {}
        for _, e in ipairs(ok and type(list) == "table" and list or {}) do
            local items = e.items or {}
            local n = #items + (e.more or 0)
            lines[#lines + 1] = { a = (e.did or "") .. (n > 0 and (" · " .. sub(tr("{n} items"), { n = n })) or ""),
                                  b = table.concat({ e.app or "", e.ai or "", clock(e.at) }, " · "), kind = 0, pair = false }
            local where = {}
            if e.where and e.where ~= "" then where[#where + 1] = e.where end
            if e.task and e.task ~= "" then where[#where + 1] = e.task end
            if #where > 0 then lines[#lines + 1] = { a = table.concat(where, " · "), b = "", kind = 2, pair = false } end
            for _, it in ipairs(items) do
                if type(it) == "table" then
                    lines[#lines + 1] = { a = tostring(it[1] or ""), b = tostring(it[2] or ""), kind = 1, pair = it[2] ~= nil }
                else
                    lines[#lines + 1] = { a = tostring(it), b = "", kind = 1, pair = false }
                end
            end
            if (e.more or 0) > 0 then
                lines[#lines + 1] = { a = sub(tr("…and {n} more"), { n = e.more }), b = "", kind = 2, pair = false }
            end
        end
        fact.total = #lines
        fact.any = #lines > 0
        show(0)
    end)
end

on("slid", function(scroll) show(math.floor(scroll / STEP)) end)

on("export", function()
    run("latte-ai", only ~= "" and { "journal", "export", "auto", only } or { "journal", "export", "auto" }, function(out)
        local ok, r = pcall(json.decode, out or "")
        if ok and type(r) == "table" and r.path then
            text.said = sub(tr("Exported to {p}"), { p = r.path })
            run("xdg-open", { r.path }, function() end)
        else
            text.said = tr("It could not be exported.")
        end
    end)
end)

on("clear", function()
    if not fact.armed then
        fact.armed = true
        after(5000, function() fact.armed = false end)
        return
    end
    fact.armed = false
    run("latte-ai", { "journal", "clear" }, function()
        text.said = tr("The history is cleared.")
        load()
    end)
end)

-- the colours of the windows' cup, as every LatteOS window made with pleamar takes them
require("lib/cup").start()
text.o_title = tr("What the AI changed")
text.empty = tr("Nothing is written here yet.")
local ok, got = pcall(sys.ask, "env", "LATTE_JOURNAL_AT")
only = ok and got or ""
load()
