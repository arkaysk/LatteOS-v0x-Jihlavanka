-- BarGoo: the window bar. Its head, the largest drop, shows how windows are arranged; the windows hang beside
-- it as berries (lib/bar.luau). A press goes to the next way of arranging them, the wheel slides the tape or
-- brings the next window forward, the right button shows the desktop and, pressed again, the windows.
-- Dragged, the whole bar moves to another edge; let go in mid-air it goes back.
local bar = require("lib/bar")
return {
    id = "bargoo", name = "BarGoo", core = true, returns = true, glyph = "layout-columns", nature = "calm", size = 44, seat = 22,
    team = 2, home = { edge = 0, at = 0.42 }, pull = 0.25, lift = 0.7, zoomable = false,
    about = function() return tr("left: window mode · wheel: next window · right: show desktop") end,
    start = function() bar.start() end,
    click = function() bar.next_mode() end,
    wheel = function(_, dir) bar.wheel(dir) end,
    right = function(d) bar.show_desktop() d:ripple(3) end,
    placed = function() bar.band() bar.refresh() end,
}
