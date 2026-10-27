-- BarGoo: the window bar. Its head, the largest drop, shows how windows are arranged; the windows hang beside
-- it as berries where they float, and are a number on it elsewhere, until the pointer rests on it (lib/bar.luau). A press goes to the next way of arranging them, the wheel slides the tape or
-- brings the next window forward, the right button shows the desktop and, pressed again, the windows. With the
-- arrangement fixed in Settings › Windows a press only brings the windows out. It can be hidden: Alt+Tab stays.
-- Dragged, the whole bar moves to another edge; let go in mid-air it goes back.
local bar = require("lib/bar")
return {
    id = "bargoo", name = "BarGoo", returns = true, glyph = "layout-columns", nature = "calm", size = 44, seat = 22,
    team = 2, home = { edge = 0, at = 0.42 }, pull = 0.25, lift = 0.7, zoomable = false,
    about = function() return tr(fact.bar_fixed and "left: the windows · wheel: next window · right: show desktop" or "left: window mode · wheel: next window · right: show desktop") .. (bar.berries_out() and "" or (" · " .. tr("stay here: the windows"))) end,
    start = function() bar.start() end,
    click = function() if fact.bar_fixed then bar.peek() else bar.next_mode() end end,
    wheel = function(_, dir) bar.wheel(dir) end,
    right = function(d) bar.show_desktop() d:ripple(3) end,
    placed = function() bar.band() bar.refresh() end,
    enter = function() bar.rest(true) end,
    leave = function() bar.rest(false) end,
}
