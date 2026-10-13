-- The desktop's own menu: what the right button on the bare desktop offers (parts/desk.plm). A card like any
-- other, grown from where the press was. What each row opens is lib/open.luau's to know.
local card = require("lib/card")
local open = require("lib/open")

local M = {}

-- main: the scene of the monitor the desktop's icons are on; with them the bare desktop is theirs
function M.start(main)
    if main then run("latte-desktop", { "status" }, function(out) fact.desk_icons = (out or ""):match("^on") ~= nil end) end
    on("desk_menu", function()
        local ok, home = pcall(sys.ask, "env", "HOME")
        local rows = {
            { label = tr("Files"), glyph = "folder", run = function() open.path(ok and home or "/") end },
            { label = tr("Open in terminal"), glyph = "terminal-2", run = function() open.terminal() end },
            { label = tr("Display settings"), glyph = "device-desktop", line = true, run = function() open.settings("displays") end },
            { label = tr("Wallpaper"), glyph = "photo", run = function() open.settings("background") end },
            { label = tr("Personalize"), glyph = "palette", run = function() open.settings("coffee") end },
            { label = tr("Drops"), glyph = "droplet", run = function() open.settings("drops") end },
            { label = tr("Monitor"), glyph = "activity", line = true, hint = "Ctrl+Shift+Esc", run = function() open.monitor() end },
            { label = tr("All settings…"), glyph = "settings", hint = "Win+I", run = function() open.settings() end },
        }
        card.open(rows, { id = "desk", width = 290 })
    end)
end

return M
