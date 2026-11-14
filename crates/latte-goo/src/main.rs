//! latte-goo: pleamar, with LatteOS's physics stepping inside it (docs/goo/GOOENGINE-2.md §4).
//!
//! It is `pleamar` in every way —the same options, the same scenes— plus one thing: once a frame, before the
//! scene's rules, `goo-phys` moves the matter and writes where it is into the scene's facts (`pleamar::provide_step`,
//! patches/pleamar-step-hook.patch). A scene that declares none of those facts runs exactly as under pleamar.
//!
//! The contract, all facts of the scene (k: a drop's place, i: a column, n: a wall):
//!   read    g.hx.k g.hy.k g.hr.k g.he.k   home, radius (0: empty), edge (0 bottom, 1 top, 2 left, 3 right)
//!           g.hw.k g.hb.k g.back.k        weight, bounce (0: the default), comes back home after a flight
//!           g.held.k                      1 while the hand has it; 1 → 0 is a throw with the hand's speed
//!           g.jump.k g.jvx.k g.jvy.k      a change of g.jump.k: fly from here at that speed
//!           g.poke.k g.pvx.k g.pvy.k      a change of g.poke.k: a shove
//!           splash.n splash.x splash.w splash.p   a change of splash.n: a push to the level
//!           wall.n.x0 wall.n.y0 wall.n.x1 wall.n.y1   something hard (x1 ≤ x0: none)
//!           gale, cursor.x cursor.y (or pointer.x pointer.y), cur.down, screen.width screen.height
//!   written g.x.k g.y.k g.r.k g.st.k g.rot.k g.sq.k g.tip.k g.tipa.k     where and what shape (rot in radians,
//!                                         for `rotate:`; tipa in degrees, for `sin()` and `cos()`)
//!           h.i                           the level's height in column i
//!           j.on.k j.w.k j.ax.k j.ay.k j.bx.k j.by.k    the thread from drop k
//!           cur.on cur.big cur.x cur.y cur.st cur.rot cur.wob cur.tailx cur.taily     the cursor as a drop: whether,
//!                                         grown to be found, its tip, its neck's stretch and angle, its belly from its tip
//!           cur.round cur.shape cur.down  …how far from an arrow to a round drop about the pointer (0…1), the shape the
//!                                         session would show (SHAPES) and whether a button is held
//!           click.n click.x click.y       a press of the mouse anywhere on the desktop: a count, and where
//!           click.win click.drop          …and whether it fell on a program's window, or on a drop
//!           covered                       the shells cannot be seen: locked, or a window has a whole monitor
//!           stir tier                     energy left 0…1; the tier 0…3
//!           ev.landed ev.bumped ev.joined ev.parted ev.flicked   one event each: a running number × 4096 + what
//!                                         (the drop; for a bump, drop × 64 + the other; for a flick, how many)
//!           hw.* fx.* look.* curs.*       gooengine.json's other sections, each number by its name
//!
//! The desktop's scene (goo/parts/drops.plm) is read as it is, so the drops' interface does not change: a drop's
//! record `goo.k.*` (a model's fields are facts by name) gives its home, size and nature, `held.k dx.k dy.k torn.k`
//! the hand, the counters `hop squash jump back` what it is told; `ripple.i.*` are pushes to the level, `gone_n` a
//! window put away that falls into the bar (`going.x going.y going.on`), `shore_w` and `lens_*` the plates.
//! A landing also says where: `ev.lx ev.ly ev.le` (the edge as the record numbers it).
//!
//! Settings: `/usr/share/latteos/gooengine.json` and over it `~/.config/latteos/gooengine.json`, read again when the
//! user's changes (docs/goo/GOOENGINE-2.md §18).

use goo_phys::{v, Config, Drop, Edge, Event, Input, Mode, Wall, World, V};
use std::collections::VecDeque;
use std::time::{Instant, SystemTime};

/// Where a fact is among the scene's, if it declares it.
type At = Option<usize>;

/// A drop's record in the desktop's scene, `goo.k.NAME`, and beside it the hand's facts, `NAME.k`.
const RECORD: [&str; 17] = ["on", "edge", "at", "shift", "rise", "r", "zoom", "pull", "reach", "lift", "sticky", "chosen", "returns", "hop", "squash", "jump", "back"];
const HAND: [&str; 4] = ["held", "dx", "dy", "torn"];

#[derive(Default)]
struct Slot {
    record: [At; 17],
    jump_v: At,
    jump_dx: At,
    hand: [At; 4],
    fly: At,
    /// The counters as last seen, and the home the record gave then.
    seen: [f32; 4],
    home: (f32, f32, f32),
    /// Landed where the logic has not yet said home is: the core's own home holds until the record changes.
    landed: bool,
    read: [At; 13],
    written: [At; 8],
    joint: [At; 6],
    jump: f32,
    poke: f32,
    held: bool,
}

const READ: [&str; 13] = ["hx", "hy", "hr", "he", "hw", "hb", "back", "held", "jump", "jvx", "jvy", "poke", "pvx"];
const WRITTEN: [&str; 8] = ["x", "y", "r", "st", "rot", "sq", "tip", "tipa"];
const JOINT: [&str; 6] = ["on", "w", "ax", "ay", "bx", "by"];
/// An effect and the first tier that carries it when the file says "auto" (GOOENGINE-2.md §18.3).
const EFFECTS: [(&str, f32); 15] = [("relief", 2.0), ("ao", 2.0), ("harmonics", 2.0), ("soft_shadow", 3.0), ("halo", 3.0), ("refraction", 2.0), ("crest_light", 2.0), ("spray", 2.0), ("bloom", 3.0), ("dispersion", 3.0), ("caustics", 3.0), ("fresnel", 3.0), ("shockwave", 3.0), ("trails", 3.0), ("light", 3.0)];

/// The scene's facts by name, found once for each scene read.
#[derive(Default)]
struct Map {
    of: (usize, usize),
    slots: Vec<Slot>,
    pvy: Vec<At>,
    columns: Vec<usize>,
    /// The desktop's scene: its drops are records.
    desktop: bool,
    ripples: Vec<[At; 5]>,
    walls: Vec<[At; 4]>,
    one: std::collections::HashMap<&'static str, usize>,
    /// (the fact, its value) for what gooengine.json says beside the physics.
    settings: Vec<(usize, f32)>,
}

struct Goo {
    world: World,
    map: Map,
    file: std::path::PathBuf,
    read_at: Option<SystemTime>,
    looked: Instant,
    extra: serde_json::Value,
    tier: f32,
    splash: f32,
    ripple_n: Vec<f32>,
    gone_n: f32,
    /// The drop a card carried last frame, and by how much: let go, it hops home.
    carried: (usize, f32),
    /// What the marker that hides the session's cursor says now, and the presses of the mouse seen so far.
    marker: Option<String>,
    /// The mouse is on DockShore's plate, whose icons pleamar-wm draws over this layer: the session's own arrow
    /// stands in there, above them, and the drop does not show under them.
    over_dock: bool,
    presses: f32,
    /// Events wait their turn: a fact holds one a frame. A landing with where it was: x, y, the edge.
    landings: VecDeque<(f32, f32, f32)>,
    told: [VecDeque<f32>; 5],
    count: [f32; 5],
}

/// Where the mouse is on the whole desktop, as pleamar-wm says it (`cursor.sock` beside the session's other
/// sockets: a line `x y` each time it moves), from this scene's monitor's corner. pleamar's own `cursor.x` places
/// the mouse in the plane of whichever of the scene's surfaces it finds first, and with the desktop's icons a
/// surface of their own that is theirs, 20 000 px away: the drops never knew a cursor that was not over a zone.
static MOUSE: std::sync::Mutex<Option<Mouse>> = std::sync::Mutex::new(None);

/// What pleamar-wm says of the mouse. The shape the session would show and the buttons come only from a
/// pleamar-wm that knows them (patches/pleamar-wm-shell-cursor.patch: asked for with `more`); `more` says so.
#[derive(Clone, Copy, Default, PartialEq)]
struct Mouse {
    at: (f32, f32),
    /// The shape, as `cur.shape` numbers it (SHAPES); 99: one the scene does not draw.
    shape: f32,
    presses: f32,
    held: bool,
    /// The last press fell on a program's window, which pleamar-wm draws in its scene.
    on_window: bool,
    /// The shells cannot be seen: locked, or a window has a whole monitor (a game, a film).
    covered: bool,
    more: bool,
}

/// The shapes the scene draws itself (goo/parts/cursor.plm), by their standard names, and `cur.shape` for each:
/// 0 the arrow, 1 over something to press, 2 a text, 3 a hand to carry with, 4 carrying, 5–8 an edge to stretch
/// (↔ ↕ ⤡ ⤢), 9 to move, 10 not allowed.
const SHAPES: [(&str, f32); 23] = [("default", 0.0), ("pointer", 1.0), ("text", 2.0), ("vertical-text", 2.0), ("grab", 3.0), ("grabbing", 4.0), ("ew-resize", 5.0), ("e-resize", 5.0), ("w-resize", 5.0), ("col-resize", 5.0),
    ("ns-resize", 6.0), ("n-resize", 6.0), ("s-resize", 6.0), ("row-resize", 6.0), ("nwse-resize", 7.0), ("nw-resize", 7.0), ("se-resize", 7.0), ("nesw-resize", 8.0), ("ne-resize", 8.0), ("sw-resize", 8.0),
    ("move", 9.0), ("all-scroll", 9.0), ("not-allowed", 10.0)];
/// The scene has the cursor's facts: it is woken for a press or a new shape under a mouse that stands still.
static WAKES: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

fn watch_mouse(screen: Option<String>) {
    let Some(dir) = std::env::var_os("PLEAMAR_SOCKETS").map(std::path::PathBuf::from) else { return };
    let _ = std::thread::Builder::new().name("mouse".into()).spawn(move || loop {
        use std::io::{BufRead, Write};
        if let Ok(mut stream) = std::os::unix::net::UnixStream::connect(dir.join("cursor.sock")) {
            let _ = stream.write_all(b"more\n");
            // the monitor's corner on the desktop: `monitor NAME w h x y …` in the file beside the socket
            let corner = |name: &Option<String>| {
                let file = std::fs::read_to_string(dir.join("desktop")).unwrap_or_default();
                let monitors: Vec<Vec<&str>> = file.lines().filter(|l| l.starts_with("monitor ")).map(|l| l.split_whitespace().collect()).collect();
                let m = monitors.iter().find(|m| name.as_deref() == m.get(1).copied()).or(monitors.first());
                m.and_then(|m| Some((m.get(4)?.parse::<f32>().ok()?, m.get(5)?.parse::<f32>().ok()?))).unwrap_or((0.0, 0.0))
            };
            let mut poke = 0.0;
            for line in std::io::BufReader::new(stream).lines().map_while(Result::ok) {
                let said: Vec<&str> = line.split_whitespace().collect();
                let number = |k: usize| said.get(k).and_then(|n| n.parse::<f32>().ok());
                if let (Some(x), Some(y)) = (number(0), number(1)) {
                    let c = corner(&screen);
                    let mut now = Mouse { at: (x - c.0, y - c.1), ..Mouse::default() };
                    if let (Some(shape), Some(presses), Some(held)) = (said.get(2), number(3), number(4)) {
                        (now.shape, now.presses, now.held, now.more) = (SHAPES.iter().find(|s| s.0 == *shape).map_or(99.0, |s| s.1), presses, held > 0.0, true);
                        now.on_window = number(5).is_some_and(|w| w > 0.0);
                        now.covered = number(6).is_some_and(|c| c > 0.0);
                    }
                    let was = MOUSE.lock().unwrap().replace(now);
                    // a press, or another shape, with the mouse where it was: nothing else would wake the scene
                    if WAKES.load(std::sync::atomic::Ordering::Relaxed) && was.is_some_and(|w| (w.shape, w.presses, w.held, w.covered) != (now.shape, now.presses, now.held, now.covered)) {
                        poke += 1.0;
                        pleamar::tell_fact("cur.poke", poke);
                    }
                }
            }
        }
        *MOUSE.lock().unwrap() = None;
        std::thread::sleep(std::time::Duration::from_secs(2));
    });
}

/// The speed across that makes a drop let go at `from`, `up` px/s upwards, come down at `to`: the flight as the
/// world will step it, gravity and air.
fn aim(cfg: &Config, from: V, to: V, up: f32) -> V {
    let (h, g, drag) = (1.0 / cfg.hz, cfg.gravity, cfg.drag);
    let (mut y, mut vy, mut reach, mut unit) = (from.y, -up, 0.0f32, 1.0f32);
    while (y < to.y || vy < 0.0) && reach < 1e6 {
        vy = (vy + g * h) * (1.0 - drag * h);
        unit *= 1.0 - drag * h;
        y += vy * h;
        reach += unit * h;
    }
    v(if reach > 0.0 { (to.x - from.x) / reach } else { 0.0 }, -up)
}

fn tier_of_session() -> f32 {
    match std::env::var("LATTE_TIER").unwrap_or_default().as_str() {
        "safe" | "software" => 0.0,
        "minimal" | "eco" => 1.0,
        "full" => 3.0,
        _ => 2.0,
    }
}

impl Goo {
    /// gooengine.json, if it changed: the physics' numbers by name, the tier, and the rest kept for the scene.
    /// A scene that draws the cursor as a drop stands in for the session's own: pleamar-wm hides its own while this
    /// process lives and says so (patches/pleamar-wm-shell-cursor.patch), for the shapes named after the process
    /// number, and never over a window that has the whole screen. A pleamar-wm that does not tell the shape gets
    /// the number alone, and hides the plain arrow. Another window manager never reads the file.
    fn marker(&mut self) {
        let Some(dir) = std::env::var_os("XDG_RUNTIME_DIR") else { return };
        let draws = !self.over_dock && self.map.one.contains_key("cur.on") && self.world.cfg.cursor_body > 0.5 && self.extra["cursor"]["hide_arrow"].as_bool() != Some(false);
        let shapes = MOUSE.lock().unwrap().is_some_and(|m| m.more) && self.map.one.contains_key("cur.shape");
        let says = draws.then(|| std::iter::once(std::process::id().to_string()).chain(SHAPES.iter().filter(|_| shapes).map(|s| s.0.to_owned())).collect::<Vec<_>>().join(" "));
        if says != self.marker {
            let file = std::path::Path::new(&dir).join("pleamar-wm-shell-cursor");
            let ours = std::process::id().to_string();
            match &says {
                Some(s) => drop(std::fs::write(&file, s)),
                None if std::fs::read_to_string(&file).is_ok_and(|s| s.split_whitespace().next() == Some(&ours)) => drop(std::fs::remove_file(&file)),
                None => {}
            }
            self.marker = says;
        }
    }

    fn settings(&mut self) {
        self.looked = Instant::now();
        self.marker();
        let at = std::fs::metadata(&self.file).and_then(|m| m.modified()).ok();
        if at == self.read_at && !self.extra.is_null() {
            return;
        }
        self.read_at = at;
        // LatteOS's own file first, the user's over it, section by section: a file with one line changes one thing
        let read = |p: &std::path::Path| std::fs::read_to_string(p).ok().and_then(|s| serde_json::from_str::<serde_json::Value>(&s).map_err(|e| eprintln!("latte-goo · {}: {e}", p.display())).ok());
        let mut json = read(std::path::Path::new("/usr/share/latteos/gooengine.json")).filter(|j| j.is_object()).unwrap_or(serde_json::json!({}));
        if let Some(serde_json::Value::Object(theirs)) = read(&self.file) {
            for (section, value) in theirs {
                match (json.get_mut(&section).and_then(|s| s.as_object_mut()), value) {
                    (Some(ours), serde_json::Value::Object(o)) => ours.extend(o),
                    (_, value) => json[section] = value,
                }
            }
        }
        let mut cfg = Config::default();
        let hw = &json["hardware"];
        self.tier = hw["tier"].as_f64().map_or_else(tier_of_session, |t| (t as f32).clamp(0.0, 3.0));
        cfg.tier = self.tier;
        // the level's columns by the tier, unless the file says how many
        cfg.columns = hw["columns"].as_f64().filter(|c| *c >= 2.0).map_or(match self.tier as u32 { 0 | 1 => 48.0, 2 => 96.0, _ => 128.0 }, |c| c as f32);
        if let Some(hz) = hw["physics_hz"].as_f64() {
            cfg.hz = hz as f32;
        }
        // the cursor as a drop: where the file says so, from the standard tier up (GOOENGINE-2.md §8)
        cfg.cursor_body = if json["cursor"]["live"].as_bool().unwrap_or(false) && json["cursor"]["mode"].as_str() != Some("off") && self.tier >= 2.0 { 1.0 } else { 0.0 };
        // Settings › Drops › Liveliness: one slider over the reactions to the cursor
        if let Some(l) = json["look"]["liveliness"].as_f64() {
            cfg.liveliness = l as f32;
        }
        if let Some(o) = json["physics"].as_object() {
            for (name, value) in o {
                if !value.as_f64().is_some_and(|x| cfg.set(name, x as f32)) {
                    eprintln!("latte-goo · gooengine.json: physics.{name} is not a number of the world (latte-goo --numbers lists them)");
                }
            }
        }
        if cfg != self.world.cfg {
            self.world.cfg = cfg;
            self.world.resize(self.world.size.x, self.world.size.y);
            self.world.wake();
        }
        self.extra = json;
        self.map.of = (0, 0); // the scene's copies of the settings are written again
    }

    fn find(&mut self, names: &[(&'static str, f32)]) {
        let at = |name: &str| names.iter().position(|n| n.0 == name);
        let mut m = Map { of: (names.as_ptr() as usize, names.len()), ..Map::default() };
        for k in 0..256 {
            if at(&format!("g.x.{k}")).is_none() {
                break;
            }
            let mut s = Slot::default();
            for (i, n) in READ.iter().enumerate() {
                s.read[i] = at(&format!("g.{n}.{k}"));
            }
            for (i, n) in WRITTEN.iter().enumerate() {
                s.written[i] = at(&format!("g.{n}.{k}"));
            }
            for (i, n) in JOINT.iter().enumerate() {
                s.joint[i] = at(&format!("j.{n}.{k}"));
            }
            m.pvy.push(at(&format!("g.pvy.{k}")));
            for (i, n) in RECORD.iter().enumerate() {
                s.record[i] = at(&format!("goo.{k}.{n}"));
            }
            for (i, n) in HAND.iter().enumerate() {
                s.hand[i] = at(&format!("{n}.{k}"));
            }
            (s.jump_v, s.jump_dx, s.fly) = (at(&format!("goo.{k}.jump_v")), at(&format!("goo.{k}.jump_dx")), at(&format!("g.fly.{k}")));
            s.seen = [f32::NAN; 4];
            m.slots.push(s);
        }
        m.columns = (0..512).map_while(|i| at(&format!("h.{i}"))).collect();
        m.desktop = m.slots.first().is_some_and(|s| s.record[0].is_some());
        m.ripples = (0..16).map_while(|i| at(&format!("ripple.{i}.n")).map(|n| [at(&format!("ripple.{i}.at")), at(&format!("ripple.{i}.shift")), at(&format!("ripple.{i}.force")), at(&format!("ripple.{i}.kind")), Some(n)])).collect();
        self.ripple_n = vec![f32::NAN; m.ripples.len()];
        self.gone_n = f32::NAN;
        m.walls = (0..32).map_while(|n| at(&format!("wall.{n}.x0")).map(|x0| [Some(x0), at(&format!("wall.{n}.y0")), at(&format!("wall.{n}.x1")), at(&format!("wall.{n}.y1"))])).collect();
        for n in ["screen.width", "screen.height", "cursor.x", "cursor.y", "pointer.x", "pointer.y", "cur.down", "gale", "splash.n", "splash.x", "splash.w", "splash.p", "stir", "tier", "cur.on", "cur.big", "cur.x", "cur.y", "cur.st", "cur.rot", "cur.wob", "cur.tailx", "cur.taily", "cur.round", "cur.shape", "cur.poke", "click.n", "click.x", "click.y", "click.win", "click.drop", "covered", "ev.landed", "ev.bumped", "ev.joined", "ev.parted", "ev.flicked", "ev.lx", "ev.ly", "ev.le",
            "card_owner", "ear.ox", "ear.oy", "gone_n", "gone.x0", "gone.y0", "gone.x1", "going.x", "going.y", "going.on", "shore_w", "lens_edge", "lens_a", "lens_b", "dock_edge", "dock_len", "dock_deep", "dock_grow", "tray_at"] {
            if let Some(k) = at(n) {
                m.one.insert(n, k);
            }
        }
        // the other sections of the file: `hardware.fps` is the fact `hw.fps`, and so on; an effect that says
        // "auto" is on from its tier up
        for (section, prefix) in [("hardware", "hw"), ("effects", "fx"), ("look", "look"), ("cursor", "curs")] {
            let o = self.extra[section].as_object();
            for (k, (name, _)) in names.iter().enumerate() {
                let Some(key) = name.strip_prefix(prefix).and_then(|r| r.strip_prefix('.')) else { continue };
                let value = o.and_then(|o| o.get(key));
                let by_tier = EFFECTS.iter().find(|e| section == "effects" && e.0 == key).map(|e| if self.tier >= e.1 { 1.0 } else { 0.0 });
                let x = match value {
                    Some(serde_json::Value::Bool(b)) => Some(if *b && self.tier >= 1.0 { 1.0 } else { 0.0 }),
                    Some(serde_json::Value::Number(n)) => n.as_f64().map(|x| x as f32),
                    _ => by_tier,
                };
                if let Some(x) = x {
                    m.settings.push((k, x));
                }
            }
        }
        WAKES.store(m.one.contains_key("cur.poke"), std::sync::atomic::Ordering::Relaxed);
        self.world.drops.resize_with(m.slots.len() + 1, || Drop::new(v(0.0, 0.0), 0.0, Edge::Bottom));
        self.map = m;
    }

    fn step(&mut self, dt: f32, names: &[(&'static str, f32)], facts: &mut [f32]) -> bool {
        if self.looked.elapsed().as_secs_f32() > 1.0 {
            self.settings();
        }
        if self.map.of != (names.as_ptr() as usize, names.len()) {
            self.find(names);
            for &(k, x) in &self.map.settings {
                facts[k] = x;
            }
        }
        if self.map.slots.is_empty() && self.map.columns.is_empty() && !self.map.one.contains_key("cur.x") && !self.map.one.contains_key("cur.st") {
            return false; // a scene that asks nothing of the physics
        }
        let one = |m: &Map, n: &str, facts: &[f32]| m.one.get(n).map(|k| facts[*k]);
        let get = |at: At, facts: &[f32]| at.map_or(0.0, |k| facts[k]);
        // DockShore (goo/parts/drops.plm `dock_*`, worked out as `dock_near` there)
        let over = {
            let f = |n: &str| one(&self.map, n, facts).unwrap_or(0.0);
            let (e, len, deep, grow) = (one(&self.map, "dock_edge", facts).unwrap_or(-1.0), f("dock_len"), f("dock_deep"), f("dock_grow"));
            let (sw, sh) = (self.world.size.x, self.world.size.y);
            // where the mouse really is, as pleamar-wm says it (the scene's own `cursor.*` are not that off its surface)
            MOUSE.lock().unwrap().is_some_and(|mo| {
                let (x, y) = mo.at;
                let (across, along) = if e < 0.5 { (sh - y, x - sw / 2.0) } else if e < 1.5 { (x, y - sh / 2.0) } else { (sw - x, y - sh / 2.0) };
                e >= 0.0 && len > 0.0 && across <= deep + 6.0 && along.abs() <= len / 2.0 + grow / 2.0 + 10.0
            })
        };
        if over != self.over_dock {
            self.over_dock = over;
            self.marker();
        }
        let m = &mut self.map;
        let w = &mut self.world;

        let (sw, sh) = (one(m, "screen.width", facts).unwrap_or(1920.0), one(m, "screen.height", facts).unwrap_or(1080.0));
        if (sw, sh) != (w.size.x, w.size.y) && sw > 0.0 && sh > 0.0 {
            w.resize(sw, sh);
        }
        let mut walls: Vec<Wall> = m.walls.iter().map(|a| Wall { x0: get(a[0], facts), y0: get(a[1], facts), x1: get(a[2], facts), y1: get(a[3], facts) }).filter(|a| a.x1 > a.x0).collect();
        if m.desktop {
            // the plates: TrayShore in the bottom right corner, LensShore's island on its edge (parts/shore.plm)
            const PLATE: f32 = 46.0;
            if let Some(wide) = one(m, "shore_w", facts).filter(|x| *x > 0.0) {
                // carried off the corner along the bottom (6.36: `tray_at`, its left end), or in the corner
                let x0 = one(m, "tray_at", facts).filter(|a| *a >= 0.0).unwrap_or(sw - wide);
                walls.push(Wall { x0, y0: sh - PLATE, x1: x0 + wide, y1: sh });
            }
            if let (Some(edge), Some(a), Some(b)) = (one(m, "lens_edge", facts), one(m, "lens_a", facts), one(m, "lens_b", facts)) {
                if b > a && edge >= 0.0 {
                    walls.push(if edge < 1.0 { Wall { x0: a, y0: sh - PLATE, x1: b, y1: sh } } else { Wall { x0: a, y0: 0.0, x1: b, y1: PLATE } });
                }
            }
        }
        if walls != w.walls {
            w.set_walls(walls);
            w.wake();
        }
        let level = w.cfg.level;
        let ear = (one(m, "card_owner", facts), v(one(m, "ear.ox", facts).unwrap_or(0.0), one(m, "ear.oy", facts).unwrap_or(0.0)));
        // let go by its card far from home, it hops back: a flight from the card's corner down to where it belongs
        let now = (ear.0.filter(|k| *k >= 0.0).map_or(usize::MAX, |k| k as usize), ear.1.len());
        let hops = Some(self.carried.0).filter(|k| self.carried.1 > 0.0 && (now.0 != *k || now.1 == 0.0) && w.drops.get(*k).is_some_and(|d| self.carried.1 > d.r && d.edge == Edge::Bottom && d.mode == Mode::Sits));
        self.carried = now;
        for (k, s) in m.slots.iter_mut().enumerate().filter(|_| m.desktop) {
            let r = |i: usize| get(s.record[i], facts);
            let hand = |i: usize| get(s.hand[i], facts);
            // home as the scene works it out (drops.plm): along its edge, `rise` above the surface
            let edge = [Edge::Bottom, Edge::Left, Edge::Top, Edge::Right][(r(1) as usize).min(3)];
            let inward = edge.inward();
            let along = r(2) * if inward.x != 0.0 { sh } else { sw } + r(3);
            let on_edge = match edge {
                Edge::Bottom => v(along, sh - level),
                Edge::Top => v(along, level),
                Edge::Left => v(level, along),
                Edge::Right => v(sw - level, along),
            };
            // the drop a card grows from goes where the card's corner is, and back when the card shuts (6.34)
            let carried = if ear.0 == Some(k as f32) { ear.1 } else { v(0.0, 0.0) };
            let home = on_edge + inward * r(4) + carried;
            let radius = if r(0) > 0.5 { r(5) * r(6) } else { 0.0 };
            let d = &mut w.drops[k];
            let appears = d.r == 0.0 && radius > 0.0;
            let moved = s.home != (home.x, home.y, r(1));
            if moved {
                (s.home, s.landed) = ((home.x, home.y, r(1)), false);
            }
            if !s.landed {
                (d.home, d.edge) = (home, edge);
            }
            let woke = moved || d.r != radius || d.chosen != (r(11) > 0.5);
            d.r = radius;
            // the record's pull, reach and lift are shares of the old defaults (0.3, 220 px, 1)
            (d.pull, d.reach, d.lift, d.chosen, d.returns) = (r(7) / 0.3, r(8) / 220.0, r(9), r(11) > 0.5, r(12) > 0.5);
            if appears {
                (d.pos, d.vel, d.mode) = (home, v(0.0, 0.0), Mode::Sits);
            }
            // the hand: a drop that sticks to home follows it part of the way until it tears off
            let held = hand(0) > 0.5;
            let follows = if hand(3) > 0.5 { 1.0 } else { 1.0 - r(10) * 0.75 };
            if held {
                w.drops[k].hand = home + v(hand(1), hand(2)) * follows;
            }
            if held && !s.held {
                w.hold(k);
            } else if !held && s.held {
                let speed = w.drops[k].vel;
                w.throw(k, speed);
            }
            s.held = held;
            // the counters: what the logic tells it, each change once (the first sight of them is no change)
            let now = [r(13), r(14), r(15), r(16)];
            if !s.seen[0].is_nan() {
                if now[0] != s.seen[0] {
                    w.nudge(k, inward * 520.0);
                }
                if now[1] != s.seen[1] {
                    w.squash(k, 9.0);
                }
                if now[2] != s.seen[2] {
                    // a throw to its new home: up at `jump_v`, and across what is left of the way in the time that takes
                    let (up, across) = (get(s.jump_v, facts), -get(s.jump_dx, facts));
                    let takes = (2.0 * up / w.cfg.gravity).max(0.1);
                    let side = v(-inward.y, inward.x) * if matches!(edge, Edge::Bottom | Edge::Left) { -1.0 } else { 1.0 };
                    w.jump(k, inward * up + side * (across / takes * (1.0 + w.cfg.drag * takes * 0.5)));
                }
                if now[3] != s.seen[3] {
                    // the logic took the drop back: wherever it is, it springs home
                    (w.drops[k].mode, s.landed) = (Mode::Sits, false);
                    (w.drops[k].home, w.drops[k].edge) = (home, edge);
                    w.wake();
                }
            }
            s.seen = now;
            if woke {
                w.wake();
            }
        }
        if let Some(k) = hops {
            let (from, to) = (w.drops[k].pos, w.drops[k].home);
            let speed = aim(&w.cfg, from, to, 330.0);
            w.jump(k, speed);
        }
        // the level: the logic's ripples are pushes (kind 1 a tremble on the spot: narrower, weaker)
        for (i, a) in m.ripples.iter().enumerate() {
            let n = get(a[4], facts);
            if n != self.ripple_n[i] && !self.ripple_n[i].is_nan() {
                let (x, force, tremble) = (get(a[0], facts) * sw + get(a[1], facts), get(a[2], facts), get(a[3], facts) > 0.5);
                w.splash(x, if tremble { 70.0 } else { 110.0 }, force * if tremble { 12.0 } else { 26.0 });
            }
            self.ripple_n[i] = n;
        }
        // a window put away: a drop of its own, thrown from where the window was so that it comes down at the bar
        let ghost = m.slots.len();
        if let Some(n) = one(m, "gone_n", facts) {
            if n != self.gone_n && !self.gone_n.is_nan() {
                let (x0, y0, x1) = (one(m, "gone.x0", facts).unwrap_or(0.0), one(m, "gone.y0", facts).unwrap_or(0.0), one(m, "gone.x1", facts).unwrap_or(0.0));
                let fall = aim(&w.cfg, v(x0, y0), v(x1, sh - level - 16.0 * w.cfg.seat), 0.0);
                let d = &mut w.drops[ghost];
                *d = Drop::new(v(x0, y0), 16.0, Edge::Bottom);
                w.throw(ghost, fall);
            }
            self.gone_n = n;
        }
        if w.drops[ghost].r > 0.0 && !w.drops[ghost].flies() {
            w.drops[ghost].r = 0.0; // it has landed: the splash is the level's, the drop is the bar's
        }
        for (k, s) in m.slots.iter_mut().enumerate().filter(|_| !m.desktop) {
            let r = |i: usize| get(s.read[i], facts);
            let d = &mut w.drops[k];
            let home = v(r(0), r(1));
            let edge = [Edge::Bottom, Edge::Top, Edge::Left, Edge::Right][(r(3) as usize).min(3)];
            let (was, appears) = (d.home != home || d.r != r(2) || d.edge != edge, d.r == 0.0 && r(2) > 0.0);
            (d.home, d.r, d.edge) = (home, r(2), edge);
            (d.weight, d.bounce, d.returns) = (if r(4) > 0.0 { r(4) } else { 1.0 }, Some(r(5)).filter(|b| *b > 0.0), r(6) > 0.5);
            if appears {
                (d.pos, d.vel, d.mode) = (home, v(0.0, 0.0), Mode::Sits);
            }
            let (held, jump, poke) = (r(7) > 0.5, r(8), r(11));
            let (jv, pv) = (v(r(9), r(10)), v(r(12), get(m.pvy[k], facts)));
            let woke = was || held != s.held || jump != s.jump || poke != s.poke;
            if held && !s.held {
                w.hold(k);
            } else if !held && s.held {
                let speed = w.drops[k].vel;
                w.throw(k, speed);
            }
            if jump != s.jump {
                w.throw(k, jv);
            }
            if poke != s.poke {
                w.nudge(k, pv);
            }
            (s.held, s.jump, s.poke) = (held, jump, poke);
            if woke {
                w.wake();
            }
        }
        if let Some(n) = one(m, "splash.n", facts).filter(|n| *n != self.splash) {
            self.splash = n;
            w.splash(one(m, "splash.x", facts).unwrap_or(0.0), one(m, "splash.w", facts).unwrap_or(80.0), one(m, "splash.p", facts).unwrap_or(0.0));
        }
        let mouse = *MOUSE.lock().unwrap();
        if let Some(mo) = mouse {
            let press = mo.more && mo.presses != self.presses && !self.presses.is_nan();
            // whether it fell on a drop: the scene leaves its own ring to the drop's glass, if it has one
            let on_drop = w.drops.iter().any(|d| d.r > 0.0 && (d.pos - v(mo.at.0, mo.at.1)).len() < d.r * 1.3);
            for (n, value, told) in [("click.win", mo.on_window as u32 as f32, press), ("covered", mo.covered as u32 as f32, mo.more), ("click.drop", on_drop as u32 as f32, press), ("cursor.x", mo.at.0, true), ("cursor.y", mo.at.1, true), ("cur.shape", mo.shape, mo.more), ("cur.down", mo.held as u32 as f32, mo.more),
                ("click.x", mo.at.0, press), ("click.y", mo.at.1, press), ("click.n", mo.presses, press)] {
                if let Some(k) = m.one.get(n).filter(|_| told) {
                    facts[*k] = value;
                }
            }
            if mo.more {
                self.presses = mo.presses;
            }
        }
        let pointer = match (one(m, "cursor.x", facts), one(m, "cursor.y", facts)) {
            (Some(x), Some(y)) => Some(v(x, y)),
            _ => one(m, "pointer.x", facts).zip(one(m, "pointer.y", facts)).map(|(x, y)| v(x, y)),
        };
        let input = Input { pointer: pointer.filter(|p| p.x != 0.0 || p.y != 0.0), down: one(m, "cur.down", facts).is_some_and(|d| d > 0.5), gale: one(m, "gale", facts).unwrap_or(0.0), centred: mouse.is_some_and(|mo| (2.0..=10.0).contains(&mo.shape)) };
        let stir = w.step(dt, &input);

        for (k, s) in m.slots.iter().enumerate() {
            let d = &w.drops[k];
            for (at, x) in s.written.iter().zip([d.pos.x, d.pos.y, d.r, d.stretch, d.rot, d.squash, d.tip, d.tip_angle.to_degrees()]) {
                if let Some(at) = at {
                    facts[*at] = x;
                }
            }
            if let Some(at) = s.fly {
                facts[at] = d.flies() as u32 as f32;
            }
        }
        // a thread is told at one of its ends' places: the first end's if that is free, else the other's
        let mut threads: Vec<Option<goo_phys::Joint>> = vec![None; m.slots.len()];
        for t in &w.joints {
            if let Some(free) = [t.a, t.b].into_iter().find(|k| threads.get(*k).is_some_and(Option::is_none)) {
                threads[free] = Some(*t);
            }
        }
        for (s, t) in m.slots.iter().zip(&threads) {
            // hidden while they still overlap: it shows as they part
            let (a, b) = t.map_or((v(0.0, 0.0), v(0.0, 0.0)), |t| (w.drops[t.a].pos, w.drops[t.b].pos));
            let apart = t.is_some_and(|t| (b - a).len() > w.drops[t.a].r + w.drops[t.b].r);
            for (at, x) in s.joint.iter().zip([apart as u32 as f32, t.map_or(0.0, |t| t.width), a.x, a.y, b.x, b.y]) {
                if let Some(at) = at {
                    facts[*at] = x;
                }
            }
        }
        // the scene may draw more or fewer columns than the world has: each gets the level where it stands
        let n = m.columns.len() as f32;
        for (i, at) in m.columns.iter().enumerate() {
            facts[*at] = w.level((i as f32 + 0.5) / n * w.size.x);
        }
        let c = &w.cursor;
        let g = &w.drops[ghost];
        for (n, x) in [("going.x", g.pos.x), ("going.y", g.pos.y), ("going.on", (g.r > 0.0) as u32 as f32), ("stir", stir), ("tier", self.tier), ("cur.on", if self.over_dock { 0.0 } else { w.cfg.cursor_body }), ("cur.big", c.big), ("cur.x", c.tip.x), ("cur.y", c.tip.y), ("cur.st", c.stretch), ("cur.rot", c.rot), ("cur.wob", c.wobble), ("cur.round", c.round), ("cur.tailx", c.belly.x - c.tip.x), ("cur.taily", c.belly.y - c.tip.y)] {
            if let Some(k) = m.one.get(n) {
                facts[*k] = x;
            }
        }
        // events: the scene has `on change ev.landed { emit goo_landed(mod(ev.landed, 4096)) }`; the running number
        // in front makes two landings of one drop two changes. One of each kind a frame.
        let w_keeps: Vec<bool> = w.drops.iter().map(|d| d.keeps_home).collect();
        for e in w.drain_events() {
            let (kind, k) = match e {
                Event::Landed(k, ..) if k == ghost => continue,
                Event::Landed(k, edge, at) => {
                    if let Some(s) = m.slots.get_mut(k) {
                        s.landed = !w_keeps[k];
                    }
                    self.landings.push_back((at.x, at.y, [0.0, 2.0, 1.0, 3.0][edge.index() as usize]));
                    (0, k as f32)
                }
                Event::Bumped(a, b) => (1, (a * 64 + b) as f32),
                Event::Joined(k) => (2, k as f32),
                Event::Parted(k) => (3, k as f32),
                Event::Flicked(n) => (4, n as f32),
            };
            self.told[kind].push_back(k);
        }
        let mut waiting = false;
        for (kind, n) in ["ev.landed", "ev.bumped", "ev.joined", "ev.parted", "ev.flicked"].iter().enumerate() {
            let Some(at) = m.one.get(n) else {
                self.told[kind].clear();
                continue;
            };
            if let Some(k) = self.told[kind].pop_front() {
                if kind == 0 {
                    let (x, y, edge) = self.landings.pop_front().unwrap_or_default();
                    for (n, value) in [("ev.lx", x), ("ev.ly", y), ("ev.le", edge)] {
                        if let Some(at) = m.one.get(n) {
                            facts[*at] = value;
                        }
                    }
                }
                self.count[kind] = (self.count[kind] + 1.0) % 1024.0;
                facts[*at] = self.count[kind] * 4096.0 + k;
            }
            waiting |= !self.told[kind].is_empty();
        }
        // over DockShore the drop is off and nothing may stir: keep stepping, to see the mouse leave it
        stir > 0.0 || waiting || self.over_dock
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().is_some_and(|a| a == "--numbers") {
        // every number of the world, for Settings and for whoever writes gooengine.json by hand
        for (name, value, what) in Config::NAMES {
            println!("{name}\t{value}\t{what}");
        }
        return;
    }
    let home = std::env::var_os("XDG_CONFIG_HOME").map(std::path::PathBuf::from).or_else(|| std::env::var_os("HOME").map(|h| std::path::PathBuf::from(h).join(".config"))).unwrap_or_default();
    let mut goo = Goo { world: World::new(1920.0, 1080.0, Config::default()), map: Map::default(), file: home.join("latteos/gooengine.json"), read_at: None, looked: Instant::now(), extra: serde_json::Value::Null, tier: 2.0, splash: 0.0, ripple_n: Vec::new(), gone_n: f32::NAN, carried: (usize::MAX, 0.0), marker: None, over_dock: false, presses: f32::NAN, landings: VecDeque::new(), told: Default::default(), count: [0.0; 5] };
    goo.settings();
    watch_mouse(args.iter().position(|a| a == "--screen").and_then(|k| args.get(k + 1)).cloned());
    pleamar::provide_step(Box::new(move |dt, names, facts| goo.step(dt, names, facts)));
    pleamar::run();
}
