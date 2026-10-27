-- LensShore: the launcher built around the AI, instead of LensGoo when Settings › Drops › Launcher says so (6B.12).
-- A drop of goo stretched into a long capsule at the top or the bottom edge, with a line to type into and a
-- send button on it (parts/lensline.plm). A press makes it grow: the line stays where it is and what was found
-- grows out of it, away from the edge. Enter or the send button ask the AI. Its place is locked; the right
-- button unlocks it, and dragged it sticks to the top or the bottom edge. The logic is LensGoo's (lib/lens.luau).
local lens = require("lib/lens")
return {
    id = "lensshore", name = "LensShore", core = true, glyph = "", nature = "calm", size = 22, seat = 26,
    home = { edge = 0, at = 0.33 }, lift = 0, pull = 0, zoomable = false,
    about = function() return tr("Search or ask…") end,
    start = function(d) lens.shore_start(d) end,
    click = function() lens.shore_open() end,
    right = function() lens.shore_menu() end,
    letgo = function(d, x, y) return lens.shore_letgo(d, x, y) end,
}
