-- The Goo desktop's logic. What a drop is and how drops are laid out is lib/engine.luau; what each one does
-- is its own module in drops/. Here they are only named, in the order they come to be: a drop that stays
-- beside another is named after it. The user's own drops are lib/own.luau, the hard corner beside them lib/shore.luau. The lock screen and the password dialog are no drops: lib/lock.luau, lib/polkit.luau.
require("lib/engine").start({ drops = { "bargoo", "lensgoo", "powergoo", "quickgoo", "clockgoo", "mediagoo" } })
require("lib/own").start()
require("lib/shore").start()
require("lib/lock").start()
require("lib/polkit").start()
