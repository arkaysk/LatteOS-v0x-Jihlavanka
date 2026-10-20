-- The lock screen's logic (parts/lock.plm): it locks the session and opens it again when the password is the
-- user's. The scene only draws; whether the session is locked is the compositor's word (`lock.held`), and
-- whether the password is right is the system's (`auth.check`), which also counts a wrong one as a failed login.
--
-- A shell that dies while it holds the lock leaves the session locked, on purpose. So that the shell that is
-- started in its place locks again instead of leaving a dead screen, the lock is noted in lock.json.
local icons = require("lib/icons")
local card = require("lib/card")
local M = {}

local FILE = "lock.json"

local function note(locked) pcall(sys.call, "files.write", FILE, { locked = locked }) end
local function show_date()
    run("date", { "+" .. tr("%A, %-d %B") }, function(out) text.lock_date = (out or ""):gsub("%s+$", "") end)
end

-- The lock screen is the login screen, a scene of its own (bin/latte-lock, goo/lockscreen.plm). This one locks only
-- when that one is not there: a session is never left open because a lock screen was missing.
local function lock_here()
    if fact.locked then return end
    text.lock_password = ""
    fact.lock_wrong, fact.lock_checking = false, false
    show_date()
    fact.locked = true
    note(true)
    after(100, function() focus("lock_password") end)      -- what is typed goes to the password without a press
end
function M.lock()
    if fact.locked then return end
    card.close()
    run("latte-lock", {}, function(_, code) if code ~= 0 then lock_here() end end)
end

on("lock_now", M.lock)
on("lock_try", function()
    local typed = text.lock_password or ""
    if typed == "" or fact.lock_checking or not fact.locked then return end
    fact.lock_checking = true
    -- The answer to a wrong password takes a couple of seconds; the renderer does not wait for the logic.
    local ok, right = pcall(sys.ask, "auth.check", typed)
    text.lock_password = ""
    fact.lock_checking = false
    if ok and right == true then
        fact.locked = false
        note(false)
    else
        fact.lock_wrong = true
        if not ok then log("lock · the password could not be checked: " .. tostring(right)) end
    end
end)

function M.start()
    local ok, user = pcall(sys.ask, "env", "USER")
    text.lock_user = ok and type(user) == "string" and user or ""
    text.g_lock, text.g_go = icons["lock"], icons["arrow-right"]
    every(30000, function() if fact.locked then show_date() end end)
    local found, kept = pcall(sys.ask, "files.read", FILE, "json")
    if found and type(kept) == "table" and kept.locked == true then lock_here() end
end

return M
