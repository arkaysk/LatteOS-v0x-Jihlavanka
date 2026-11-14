-- Secure attention screen (secure.plm): what each choice does. Nothing here is new: the same commands the lock
-- screen, PowerGoo and the Settings pages already use. A way out that does not undo asks a second press first.
require("lib/cup").start()

local armed = nil
local function N(s) return s end            -- marks a text for the translation table

local function app(...)                      -- detached: the app must outlive this screen
    run("setsid", { "-f", "latte-app", ... }, function() end)
    return true
end
local function leave(cmd)
    run("sh", { "-c", cmd }, function() end)
end
local function paint()
    text.lbl_out = armed == 2 and tr(N("Press again to sign out")) or tr(N("Sign out"))
    text.lbl_sleep = tr(N("Sleep"))
    text.lbl_restart = armed == 15 and tr(N("Press again to restart")) or tr(N("Restart"))
    text.lbl_off = armed == 16 and tr(N("Press again to shut down")) or tr(N("Shut down"))
    fact.armed = armed or -1
end
local function finish(f) after(250, function() f(); after(800, function() emit("done") end) end) end

local ACT = {
    [0] = function() finish(function() run("sh", { "-c", "latte-lock || loginctl lock-session" }, function() end) end) end,
    [3] = function() app("settings", "password"); after(800, function() emit("done") end) end,
    [4] = function() app("monitor"); after(800, function() emit("done") end) end,
    [5] = function() emit("done") end,
    [10] = function() app("settings", "network"); after(800, function() emit("done") end) end,
    [11] = function() app("settings", "accessibility"); after(800, function() emit("done") end) end,
    [14] = function() finish(function() leave("systemctl suspend") end) end,
}
-- ones that are asked twice; the same commands as PowerGoo (lib/wm.luau M.logout / M.machine)
local TWICE = {
    [2] = function() leave("exec pkill -TERM -x pleamar-wm") end,
    [15] = function() leave("systemctl reboot") end,
    [16] = function() leave("systemctl poweroff") end,
}

on("act", function(n)
    n = tonumber(n)
    if TWICE[n] then
        if armed ~= n then
            armed = n; paint()
            after(4000, function() if armed == n then armed = nil; paint() end end)
            return
        end
        armed = nil; paint()
        finish(TWICE[n])
    elseif ACT[n] then ACT[n]() end
end)

paint()
run("whoami", {}, function(u) text.who = (u or ""):gsub("%s+$", "") end)
