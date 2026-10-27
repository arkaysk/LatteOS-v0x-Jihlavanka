-- The goo under LensShore's island (apps/lensshore.qml): a drop stretched into a capsule exactly where the island lies,
-- so that the island at rest is one body with the other drops, joined to them by the same water, with no line between.
-- It never gives way (`fixed`): the drops keep off its stretch (lib/engine.luau, blocks). The island draws its line on it
-- and grows out of it; the press goes to the island, which lies over it.
local lens = require("lib/lens")
return {
    id = "lensbase", name = "LensShore", core = true, fixed = true, glyph = "", nature = "calm", size = 23, seat = 27,
    home = { edge = 0, at = 0.5 }, lift = 0, pull = 0, swell = 0.04, zoomable = false,
    start = function(d) lens.base_start(d) end,
}
