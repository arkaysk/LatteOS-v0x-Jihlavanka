-- The Goo desktop's logic. What a drop is and how drops are laid out is lib/engine.luau; what each one does
-- is its own module in drops/. Here they are only named, in the order they come to be: a drop that stays
-- beside another is named after it.
require("lib/engine").start({ drops = { "bargoo", "lensgoo", "powergoo" } })
