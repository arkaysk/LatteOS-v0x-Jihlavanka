-- Zvedavka: kurzor ju priťahuje (gravitácia), dýcha; pri prechode myšou sa rozžiari (rezerva e4 = žiara okraja)
return {
    id = "zvedavka", nazov = "Zvedavka", ikona = "eye", povaha = "zvedava", farba = "kava",
    popis = "Zvedavá: ide za kurzorom",
    nad = function(d) d:rezerva(4, 1) end,
    prec = function(d) d:rezerva(4, 0) end,
}
