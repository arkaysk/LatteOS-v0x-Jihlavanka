-- LensGoo: the drop with the magnifying glass, where the Start button would be: beside the window bar's head.
-- A press, or the Windows key, opens the launcher (lib/lens.luau); the right button the apps used last.
local lens = require("lib/lens")
return {
    id = "lensgoo", name = "LensGoo", core = true, glyph = "search", nature = "calm", size = 30, swell = 0.09, seat = 21,
    lift = 1, pull = 0.3, reach = 130, beside = "bargoo", gap = -88,
    about = function() return tr("left: search and apps · right: recent apps") end,
    start = function(d) lens.start(d) end,
    click = function() lens.toggle() end,
    right = function() lens.quick() end,
}
