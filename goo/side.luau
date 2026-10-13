-- The logic of side.plm: the engine with BarGoo alone. What the user chose for the Goo (the material, whether
-- it is lively) is the main scene's to keep; this one is told.
require("lib/engine").start({ drops = { "bargoo" }, side = true })
require("lib/desk").start()
