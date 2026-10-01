-- Plachá: kurzor ju odpudzuje (záporná gravitácia); keď ju predsa chytíš, roztrasie sa
return {
    id = "placha", nazov = "Plachá", ikona = "ghost", povaha = "placha", farba = "levandula",
    popis = "Plachá: uhýba kurzoru",
    tahanie = function(d) d:efekt("tras", 1) end,
    pustenie = function(d) d:efekt("kmit", 0.6) end,
}
