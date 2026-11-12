//! Every number of the world, by name: the defaults here, the user's in `~/.config/latteos/gooengine.json`
//! (`physics`), set without building anything. `Config::NAMES` is what Settings and the documentation list.

macro_rules! config {
    ($($name:ident = $value:expr, $what:literal;)*) => {
        #[derive(Clone, Debug, PartialEq)]
        pub struct Config { $(#[doc = $what] pub $name: f32,)* }
        impl Default for Config {
            fn default() -> Self { Config { $($name: $value,)* } }
        }
        impl Config {
            /// Each number: its name, its default and what it is.
            pub const NAMES: &'static [(&'static str, f32, &'static str)] = &[$((stringify!($name), $value, $what),)*];
            /// Sets one by its name; `false` for a name there is none of, or a value that is no number.
            pub fn set(&mut self, name: &str, value: f32) -> bool {
                if !value.is_finite() { return false; }
                match name { $(stringify!($name) => self.$name = value,)* _ => return false }
                true
            }
            pub fn get(&self, name: &str) -> Option<f32> {
                match name { $(stringify!($name) => Some(self.$name),)* _ => None }
            }
        }
    };
}

config! {
    // the machine
    tier = 2.0, "0 drawn by the processor or SAFE (nothing moves), 1 saving, 2 standard, 3 full";
    hz = 240.0, "fixed steps a second";
    max_steps = 12.0, "steps a frame at most: a frame longer than this many is cut short";
    columns = 96.0, "columns of the level along the bottom edge";
    rest_energy = 0.6, "energy under which the world counts as still";
    rest_time = 0.5, "seconds under it before everything is put exactly in place and the scene sleeps";
    // a drop at home
    home_along = 150.0, "stiffness of the pull home along the edge";
    damp_along = 17.0, "its damping";
    home_across = 190.0, "stiffness across the edge";
    damp_across = 9.0, "its damping: low, so it overshoots";
    level = 6.0, "px inside each edge of the screen where the surface lies";
    seat = 0.8, "how far above the surface a landed drop's centre sits, in radii";
    squash_k = 420.0, "stiffness of a flattened drop coming back";
    squash_c = 16.0, "its damping";
    // the cursor
    liveliness = 1.0, "multiplies the reactions to the cursor (Settings: Liveliness)";
    reach = 300.0, "px from which a drop feels the cursor";
    pull = 0.55, "how much it is drawn";
    lift = 1.1, "how far it rises from its edge, in radii";
    lean = 1.2, "how far it leans along the edge, in radii";
    tip = 0.6, "the longest tip it reaches out, in radii";
    wake = 1.0, "how hard a fast cursor drags drops and the level along";
    cursor_body = 1.0, "1: the cursor is a drop with a belly that lags and swings; 0: it only attracts";
    cursor_tail = 22.0, "px its belly may lag behind its tip";
    cursor_k = 520.0, "stiffness between the cursor's tip and its belly";
    cursor_c = 26.0, "its damping";
    // drops against each other
    push = 900.0, "how hard two overlapping drops push apart";
    restitution = 0.25, "how much speed a bump gives back";
    bump_speed = 120.0, "px/s over which a bump is told to the logic";
    join = 1.0, "a thread is made when two drops touch: under this many sums of their radii";
    part = 2.3, "and torn over this many";
    thread = 0.5, "a thread's width at rest, in radii of the smaller drop";
    thin = 1.6, "how fast it thins as it stretches";
    thread_pull = 120.0, "how hard it pulls while it holds";
    recoil = 60.0, "the kick when it snaps";
    // flight
    gravity = 800.0, "px/s²";
    drag = 1.8, "air";
    throw_max = 1600.0, "px/s: a fall, not a shot";
    stick = 130.0, "let go within this many px of a side or the top, a drop clings to it";
    stick_speed = 500.0, "…unless it was thrown faster than this, px/s";
    hop_off = 300.0, "px/s sideways with which a drop leaves the top of a plate";
    splash = 0.5, "how hard a landing pushes the level: px/s of the level for each px/s of the drop";
    splash_max = 420.0, "…and no harder than this";
    // the level
    wave_speed = 430.0, "px/s";
    restore = 22.0, "pull of the level back to rest";
    damp = 1.5, "how fast waves die";
    thick = 900.0, "how thick the coffee is: px² a second by which neighbouring columns even out their speed";
    wave_max = 40.0, "px a wave may rise";
    wind = 500.0, "how hard the wind pushes drops";
}
