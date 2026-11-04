-- TEMPLATE — the logic of a secondary LatteOS window (okno.plm; docs/okna/SABLONY.md). What the user changes is kept
-- here until OK or Apply, then written; OK closes the window, Cancel and ✕ close it without writing (Properties,
-- goo/props.luau, is the whole example: several files as tabs, Apply, writing through a helper).
local changed = {}                             -- what the user changed, not written yet

local function show()
    local dirty = false
    for _ in pairs(changed) do dirty = true end
    fact.o_dirty = dirty
end

-- an example: a switch, changed at once on the screen, written at OK or Apply
on("flip", function() fact.o_switch = not fact.o_switch; changed.switch = fact.o_switch; show() end)

-- writes what changed (a helper of this window, `run("latte-…", …)`), then `done` if it should close
local function write(after_)
    changed = {}
    show()
    if after_ then after_() end
end
on("apply", function() write() end)
on("ok", function() write(function() emit("done") end) end)

-- the colours of the windows' cup, as every LatteOS window made with pleamar takes them
require("lib/cup").start()
text.o_title = tr("Settings")
