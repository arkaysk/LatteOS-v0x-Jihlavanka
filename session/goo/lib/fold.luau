-- lib/fold.luau — text bez diakritiky a malými písmenami (hľadanie „kosit“ nájde „Košice“). Spoločné pre okno spúšťača LensGoo
-- (lib/spustac.luau) a núdzové rozhranie SAFE (safe.luau).
local BEZ = { ["á"] = "a", ["ä"] = "a", ["č"] = "c", ["ď"] = "d", ["é"] = "e", ["ě"] = "e", ["í"] = "i", ["ĺ"] = "l", ["ľ"] = "l",
              ["ň"] = "n", ["ó"] = "o", ["ô"] = "o", ["ö"] = "o", ["ŕ"] = "r", ["ř"] = "r", ["š"] = "s", ["ť"] = "t", ["ú"] = "u",
              ["ů"] = "u", ["ü"] = "u", ["ý"] = "y", ["ž"] = "z",
              ["Á"] = "a", ["Ä"] = "a", ["Č"] = "c", ["Ď"] = "d", ["É"] = "e", ["Ě"] = "e", ["Í"] = "i", ["Ĺ"] = "l", ["Ľ"] = "l",
              ["Ň"] = "n", ["Ó"] = "o", ["Ô"] = "o", ["Ö"] = "o", ["Ŕ"] = "r", ["Ř"] = "r", ["Š"] = "s", ["Ť"] = "t", ["Ú"] = "u",
              ["Ů"] = "u", ["Ü"] = "u", ["Ý"] = "y", ["Ž"] = "z" }
local function fold(s) return (tostring(s or ""):gsub("[\xC3-\xC5][\x80-\xBF]", BEZ):lower()) end

return fold
