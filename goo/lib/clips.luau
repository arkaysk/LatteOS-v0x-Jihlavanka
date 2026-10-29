-- What was copied lately, as cliphist keeps it (wl-paste --watch cliphist store, started with the session): the
-- TrayShore panel and LensShore's clipboard both read it. What a password manager marks as secret is not kept.
local M = {}

-- answer(list), the newest first: { id, text (one line, `cut` letters at most), picture ("png 1920x1080") }
function M.read(n, cut, answer)
    run("cliphist", { "list" }, function(out, code)
        local list = {}
        for id, what in (code == 0 and out or ""):gmatch("(%d+)\t([^\n]*)") do
            if #list >= n then break end
            local kind, dims = what:match("^%[%[ binary data .- (%a+) (%d+x%d+) %]%]$")
            what = what:gsub("%s+", " ")
            local ok, at = pcall(utf8.offset, what, cut + 1)             -- letters, not bytes
            list[#list + 1] = { id = id, text = (ok and at) and (what:sub(1, at - 1) .. "…") or what,
                                picture = kind and (kind .. " " .. dims:gsub("x", " × ")) or nil }
        end
        answer(list)
    end)
end
-- back onto the clipboard, as it was copied (a picture as a picture); done() once it is there
function M.copy(id, done) run("sh", { "-c", "cliphist decode " .. tonumber(id) .. " | wl-copy" }, function() if done then done() end end, { output = false }) end
function M.wipe(done) run("cliphist", { "wipe" }, function() if done then done() end end) end

return M
