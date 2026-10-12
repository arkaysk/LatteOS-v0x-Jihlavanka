-- Text without accents and in lower case, so that typing "kosice" finds "Košice".
-- The table covers the Latin letters with accents of Slovak, Czech and German; add a language's letters here.
local PLAIN = { ["á"] = "a", ["ä"] = "a", ["č"] = "c", ["ď"] = "d", ["é"] = "e", ["ě"] = "e", ["í"] = "i", ["ĺ"] = "l", ["ľ"] = "l",
                ["ň"] = "n", ["ó"] = "o", ["ô"] = "o", ["ö"] = "o", ["ŕ"] = "r", ["ř"] = "r", ["š"] = "s", ["ť"] = "t", ["ú"] = "u",
                ["ů"] = "u", ["ü"] = "u", ["ý"] = "y", ["ž"] = "z",
                ["Á"] = "a", ["Ä"] = "a", ["Č"] = "c", ["Ď"] = "d", ["É"] = "e", ["Ě"] = "e", ["Í"] = "i", ["Ĺ"] = "l", ["Ľ"] = "l",
                ["Ň"] = "n", ["Ó"] = "o", ["Ô"] = "o", ["Ö"] = "o", ["Ŕ"] = "r", ["Ř"] = "r", ["Š"] = "s", ["Ť"] = "t", ["Ú"] = "u",
                ["Ů"] = "u", ["Ü"] = "u", ["Ý"] = "y", ["Ž"] = "z" }

-- These letters are all two bytes in UTF-8, the first of them C3, C4 or C5.
return function(s) return (tostring(s or ""):gsub("[\xC3-\xC5][\x80-\xBF]", PLAIN):lower()) end
