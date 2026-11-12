//! goo-phys: where LatteOS's Goo is (docs/goo/GOOENGINE-2.md §5). Positions, speeds, collisions, flight, the
//! surface along the bottom edge, the threads between drops and the cursor as a drop. It knows nothing of
//! pleamar, Wayland, colours or files: `latte-goo` feeds it and writes what it works out into the scene's facts.
//!
//! Pixels, seconds, y downwards. One fixed step (`Config::hz`), so the result does not depend on the frame rate.

mod config;
pub use config::Config;

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct V {
    pub x: f32,
    pub y: f32,
}

pub const fn v(x: f32, y: f32) -> V {
    V { x, y }
}

impl V {
    pub fn len(self) -> f32 {
        self.x.hypot(self.y)
    }
    pub fn dot(self, o: V) -> f32 {
        self.x * o.x + self.y * o.y
    }
    /// Its direction, and (1, 0) for no length at all.
    pub fn unit(self) -> V {
        let l = self.len();
        if l > 1e-5 { self * (1.0 / l) } else { v(1.0, 0.0) }
    }
    fn capped(self, max: f32) -> V {
        let l = self.len();
        if l > max { self * (max / l) } else { self }
    }
}
impl std::ops::Add for V {
    type Output = V;
    fn add(self, o: V) -> V {
        v(self.x + o.x, self.y + o.y)
    }
}
impl std::ops::Sub for V {
    type Output = V;
    fn sub(self, o: V) -> V {
        v(self.x - o.x, self.y - o.y)
    }
}
impl std::ops::Mul<f32> for V {
    type Output = V;
    fn mul(self, k: f32) -> V {
        v(self.x * k, self.y * k)
    }
}
impl std::ops::AddAssign for V {
    fn add_assign(&mut self, o: V) {
        *self = *self + o;
    }
}

/// The edge of the screen a drop lives on.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Edge {
    Bottom,
    Top,
    Left,
    Right,
}

impl Edge {
    /// From the edge into the screen.
    pub fn inward(self) -> V {
        match self {
            Edge::Bottom => v(0.0, -1.0),
            Edge::Top => v(0.0, 1.0),
            Edge::Left => v(1.0, 0.0),
            Edge::Right => v(-1.0, 0.0),
        }
    }
    pub fn index(self) -> u32 {
        self as u32
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode {
    /// At home: pulled there, towards the cursor, away from its neighbours.
    Sits,
    /// In the hand: where the pointer is.
    Held,
    /// Thrown, dropped or jumping: gravity and air until the first edge.
    Flies,
}

#[derive(Clone, Debug)]
pub struct Drop {
    pub pos: V,
    pub vel: V,
    /// 0: the place is empty.
    pub r: f32,
    /// 1, or 2.5 for a heavy nature.
    pub weight: f32,
    /// How much speed a bump gives back; `None` is `Config::restitution`.
    pub bounce: Option<f32>,
    pub home: V,
    pub edge: Edge,
    pub mode: Mode,
    /// Whether a drop let go of comes home by its spring (BarGoo) instead of falling where it was left.
    pub returns: bool,
    /// Its own share of the cursor's pull, reach and lift: 1 is `Config`'s, 0 none (a pinned drop).
    pub pull: f32,
    pub reach: f32,
    pub lift: f32,
    /// Risen as if the cursor were at it: the one the keyboard is on.
    pub chosen: bool,
    /// Where the hand has it, while held: the pointer, or short of it for a drop that sticks to home.
    pub hand: V,
    /// A jump lands at the home it has; a throw makes its home where it lands.
    pub keeps_home: bool,
    /// Seconds a flight has stood still: come to rest on other drops, it has landed.
    slow_for: f32,
    // what the scene draws, beside `pos` and `r`
    pub stretch: f32,
    pub rot: f32,
    pub squash: f32,
    pub tip: f32,
    pub tip_angle: f32,
    squash_v: f32,
}

impl Drop {
    pub fn new(home: V, r: f32, edge: Edge) -> Drop {
        Drop { pos: home, vel: V::default(), r, weight: 1.0, bounce: None, home, edge, mode: Mode::Sits, returns: false, pull: 1.0, reach: 1.0, lift: 1.0, chosen: false, hand: home, keeps_home: false, slow_for: 0.0, stretch: 0.0, rot: 0.0, squash: 0.0, tip: 0.0, tip_angle: 0.0, squash_v: 0.0 }
    }
    pub fn flies(&self) -> bool {
        self.mode == Mode::Flies
    }
    pub fn mass(&self) -> f32 {
        (self.r / 26.0).powi(2).max(0.05) * self.weight
    }
    fn there(&self) -> bool {
        self.r > 0.0
    }
}

/// The level along the bottom edge: a row of columns, a damped wave equation.
#[derive(Clone, Debug, Default)]
pub struct Surface {
    pub h: Vec<f32>,
    vel: Vec<f32>,
    /// Columns under a plate stand still: a wave comes back from them.
    still: Vec<bool>,
}

/// The cursor as a drop: the tip is the pointer itself, the belly hangs behind it on a spring.
#[derive(Clone, Debug, Default)]
pub struct Cursor {
    pub tip: V,
    pub vel: V,
    pub belly: V,
    belly_v: V,
    pub stretch: f32,
    pub rot: f32,
    pub wobble: f32,
    wobble_v: f32,
    pub there: bool,
    pub down: bool,
}

/// A thread from drop `a` to drop `b`.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Joint {
    pub a: usize,
    pub b: usize,
    pub width: f32,
}

/// Something hard: a plate of a Shore, a dock, a window's title. A flying drop comes back from it, the surface
/// under it stands still.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Wall {
    pub x0: f32,
    pub y0: f32,
    pub x1: f32,
    pub y1: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Event {
    /// A flight ended on an edge, at this point.
    Landed(usize, Edge, V),
    Bumped(usize, usize),
    Joined(usize),
    Parted(usize),
    /// The cursor turned so fast that this many droplets came off it.
    Flicked(u32),
}

/// What comes from outside each frame.
#[derive(Clone, Copy, Debug, Default)]
pub struct Input {
    /// Where the pointer is, if it is on this screen.
    pub pointer: Option<V>,
    pub down: bool,
    /// −1…1: how hard the wind blows, and which way.
    pub gale: f32,
}

pub struct World {
    pub drops: Vec<Drop>,
    pub surface: Surface,
    pub cursor: Cursor,
    pub joints: Vec<Joint>,
    pub walls: Vec<Wall>,
    pub cfg: Config,
    pub size: V,
    /// 0…1: how much energy is left, smoothed. The scene's states hang on it.
    pub stir: f32,
    events: Vec<Event>,
    owed: f32,
    quiet_for: f32,
    clock: f32,
}

impl World {
    pub fn new(width: f32, height: f32, cfg: Config) -> World {
        let mut w = World { drops: Vec::new(), surface: Surface::default(), cursor: Cursor::default(), joints: Vec::new(), walls: Vec::new(), cfg, size: v(width, height), stir: 0.0, events: Vec::new(), owed: 0.0, quiet_for: 0.0, clock: 0.0 };
        w.resize(width, height);
        w
    }

    /// The screen's size, or the number of columns, changed.
    pub fn resize(&mut self, width: f32, height: f32) {
        self.size = v(width, height);
        let n = (self.cfg.columns as usize).clamp(2, 512);
        if self.surface.h.len() != n {
            self.surface = Surface { h: vec![0.0; n], vel: vec![0.0; n], still: vec![false; n] };
        }
        self.set_walls(self.walls.clone());
    }

    pub fn set_walls(&mut self, walls: Vec<Wall>) {
        self.walls = walls;
        let (n, dx) = (self.surface.h.len(), self.column_width());
        for i in 0..n {
            let x = (i as f32 + 0.5) * dx;
            // a plate that reaches the bottom edge stands in the water
            self.surface.still[i] = self.walls.iter().any(|w| w.y1 >= self.size.y - 1.0 && x >= w.x0 && x <= w.x1);
        }
    }

    fn column_width(&self) -> f32 {
        self.size.x / self.surface.h.len().max(1) as f32
    }

    /// The level's height above rest at `x`, between two columns.
    pub fn level(&self, x: f32) -> f32 {
        let n = self.surface.h.len();
        if n == 0 {
            return 0.0;
        }
        let f = (x / self.column_width() - 0.5).clamp(0.0, n as f32 - 1.0);
        let (i, t) = (f as usize, f.fract());
        self.surface.h[i] * (1.0 - t) + self.surface.h[(i + 1).min(n - 1)] * t
    }

    /// Something falls into the level at `x`, `width` wide, `push` px/s hard: it presses a hollow and throws up a
    /// rim around it, as much up as down (the coffee goes nowhere), and from there the rings run out, come back
    /// from the walls and die. A negative push lifts instead: a plate coming up out of the water.
    pub fn splash(&mut self, x: f32, width: f32, push: f32) {
        let dx = self.column_width();
        let half = (width * 0.5).max(dx * 1.5);
        // a hollow with a rim, the same volume in both, sampled so that a narrow one on wide columns keeps that
        let shape = |d: f32| (1.0 - 4.0 * d * d) * (-2.0 * d * d).exp();
        let near: Vec<(usize, f32)> = (0..self.surface.h.len()).map(|i| (i, ((i as f32 + 0.5) * dx - x) / half)).filter(|(i, d)| d.abs() < 2.4 && !self.surface.still[*i]).collect();
        let mean = near.iter().map(|(_, d)| shape(*d)).sum::<f32>() / near.len().max(1) as f32;
        for (i, d) in near {
            self.surface.vel[i] -= push * (shape(d) - mean);
        }
        self.wake();
    }

    /// A drop let go of, with the hand's speed. Gravity is down, always: it falls to the bottom edge. But goo
    /// sticks: let go slowly right by a side or the top it clings there, and one that flies into them stays.
    /// One that `returns` springs home.
    pub fn throw(&mut self, k: usize, speed: V) {
        let (cfg, size) = (&self.cfg, self.size);
        if let Some(d) = self.drops.get_mut(k) {
            d.vel = speed.capped(cfg.throw_max);
            if d.returns {
                d.mode = Mode::Sits;
            } else {
                let near = [(d.pos.x, Edge::Left), (size.x - d.pos.x, Edge::Right), (d.pos.y, Edge::Top)];
                let side = near.iter().filter(|e| e.0 < cfg.stick && d.vel.len() < cfg.stick_speed).min_by(|a, b| a.0.total_cmp(&b.0));
                match side {
                    Some(&(_, edge)) => {
                        // it clings: home is the nearest point of that edge, and its own spring takes it there
                        let seat = cfg.level + cfg.seat * d.r;
                        let at = match edge {
                            Edge::Left => v(seat, d.pos.y),
                            Edge::Right => v(size.x - seat, d.pos.y),
                            _ => v(d.pos.x, seat),
                        };
                        (d.mode, d.home, d.edge) = (Mode::Sits, at, edge);
                        self.events.push(Event::Landed(k, edge, at));
                    }
                    None => (d.mode, d.keeps_home) = (Mode::Flies, false),
                }
            }
        }
        self.wake();
    }

    /// A jump: from where it is, at this speed, and back home. From the bottom edge it is a flight, down again by
    /// gravity; a drop that clings to a side or the top is flung out and its own hold pulls it back.
    pub fn jump(&mut self, k: usize, speed: V) {
        let max = self.cfg.throw_max;
        if let Some(d) = self.drops.get_mut(k) {
            d.vel = speed.capped(max);
            if d.edge == Edge::Bottom {
                (d.mode, d.keeps_home) = (Mode::Flies, true);
            }
        }
        self.wake();
    }

    /// Flattened by this much of a kick: a press, a landing the logic knows of.
    pub fn squash(&mut self, k: usize, kick: f32) {
        if let Some(d) = self.drops.get_mut(k) {
            d.squash_v += kick;
        }
        self.wake();
    }

    pub fn hold(&mut self, k: usize) {
        if let Some(d) = self.drops.get_mut(k) {
            d.mode = Mode::Held;
        }
        self.wake();
    }

    /// A shove: a wince, a bump from a window.
    pub fn nudge(&mut self, k: usize, speed: V) {
        if let Some(d) = self.drops.get_mut(k) {
            d.vel += speed;
        }
        self.wake();
    }

    pub fn wake(&mut self) {
        self.quiet_for = 0.0;
        self.stir = self.stir.max(0.05);
    }

    pub fn drain_events(&mut self) -> std::vec::Drain<'_, Event> {
        self.events.drain(..)
    }

    /// Advances by `dt` in fixed steps. Returns the energy left, 0…1: 0 is rest, and then everything is exactly
    /// where it belongs.
    pub fn step(&mut self, dt: f32, input: &Input) -> f32 {
        // the cursor's speed is the frame's, not the step's: the pointer only moves between frames
        let c = &mut self.cursor;
        let was = (c.tip, c.there, c.down);
        c.there = input.pointer.is_some();
        c.down = input.down;
        if let Some(p) = input.pointer {
            let moved = if was.1 && dt > 1e-4 { (p - c.tip) * (1.0 / dt.max(1.0 / 240.0)) } else { V::default() };
            if !was.1 {
                c.belly = p;
            }
            // a turn back on itself at speed throws droplets off
            if moved.len() > 900.0 && c.vel.len() > 900.0 && moved.unit().dot(c.vel.unit()) < -0.3 {
                self.events.push(Event::Flicked(((moved.len() / 900.0) as u32).clamp(1, 3)));
            }
            c.vel = moved.capped(6000.0);
            c.tip = p;
        } else {
            c.vel = V::default();
        }
        // A pointer that moves stirs the world only where there is something to stir: its own body if it has one,
        // a drop within reach, the level under it. Over a window in the middle of the screen it wakes nothing.
        let moved = (c.tip, c.there, c.down) != was;
        let tip = c.tip;
        let near = self.cfg.cursor_body > 0.5
            || self.size.y - tip.y < 90.0
            || self.drops.iter().any(|d| d.there() && (d.mode != Mode::Sits || (d.pos - tip).len() < self.cfg.reach * d.reach.max(1.0) * self.cfg.liveliness.max(0.0).sqrt() + d.r));
        if (moved && near) || input.gale != 0.0 {
            self.quiet_for = 0.0;
        }
        if self.cfg.tier < 0.5 {
            // tier 0 (drawn by the processor, SAFE): nothing moves, everything is at home
            self.settle();
            return 0.0;
        }
        if self.quiet_for >= self.cfg.rest_time {
            return 0.0;
        }
        let h = 1.0 / self.cfg.hz.clamp(30.0, 1000.0);
        self.owed = (self.owed + dt.max(0.0)).min(h * self.cfg.max_steps.max(1.0));
        let mut energy = 0.0f32;
        while self.owed >= h {
            self.owed -= h;
            energy = self.tick(h, input);
        }
        self.quiet_for = if energy > self.cfg.rest_energy { 0.0 } else { self.quiet_for + dt };
        if self.quiet_for >= self.cfg.rest_time {
            self.settle();
            return 0.0;
        }
        let now = (energy / (self.cfg.rest_energy * 40.0)).clamp(0.02, 1.0);
        self.stir += (now - self.stir) * (dt * 8.0).min(1.0);
        self.stir
    }

    /// Everything exactly where it belongs, with no speed.
    fn settle(&mut self) {
        for d in &mut self.drops {
            if d.mode == Mode::Sits {
                d.pos = d.home;
            }
            d.vel = V::default();
            (d.stretch, d.squash, d.squash_v, d.tip) = (0.0, 0.0, 0.0, 0.0);
        }
        self.surface.h.iter_mut().for_each(|h| *h = 0.0);
        self.surface.vel.iter_mut().for_each(|h| *h = 0.0);
        let c = &mut self.cursor;
        (c.belly, c.belly_v, c.stretch, c.wobble, c.wobble_v) = (c.tip, V::default(), 0.0, 0.0, 0.0);
        self.stir = 0.0;
        self.owed = 0.0;
    }

    fn tick(&mut self, h: f32, input: &Input) -> f32 {
        self.clock += h;
        let cfg = self.cfg.clone();
        let live = cfg.liveliness.max(0.0);
        let (reach, cursor) = (cfg.reach * live.sqrt(), self.cursor.clone());
        let mut energy = 0.0f32;

        // ── the level ───────────────────────────────────────────────────────────────────────────────────────
        let (n, dx) = (self.surface.h.len(), self.column_width());
        let s = &mut self.surface;
        let k = (cfg.wave_speed / dx).powi(2);
        for i in 0..n {
            if s.still[i] {
                (s.h[i], s.vel[i]) = (0.0, 0.0);
                continue;
            }
            // at the screen's ends and at a plate the wave meets a wall: the neighbour there is itself, mirrored
            let side = |j: isize| if j < 0 || j >= n as isize || s.still[j as usize] { s.h[i] } else { s.h[j as usize] };
            let pull = k * (side(i as isize - 1) + side(i as isize + 1) - 2.0 * s.h[i]) - cfg.restore * s.h[i] - cfg.damp * s.vel[i];
            s.vel[i] += pull * h;
        }
        // thick as coffee: a column drags its neighbours' speed along, so ripples a column wide die first and
        // what is left is smooth
        let before = s.vel.clone();
        let visc = (cfg.thick * h / (dx * dx)).min(0.24);
        for i in 0..n {
            if !s.still[i] {
                let side = |j: isize| if j < 0 || j >= n as isize || s.still[j as usize] { before[i] } else { before[j as usize] };
                s.vel[i] += visc * (side(i as isize - 1) + side(i as isize + 1) - 2.0 * before[i]);
            }
        }
        for i in 0..n {
            s.h[i] = (s.h[i] + s.vel[i] * h).clamp(-cfg.wave_max, cfg.wave_max);
            energy += s.h[i].abs() * 0.5 + s.vel[i].abs() * 0.05;
        }
        // the cursor's wake on the level: a fast pointer close to the bottom drags the columns under it
        if cursor.there && self.size.y - cursor.tip.y < 90.0 && cursor.vel.len() > 500.0 {
            let i = ((cursor.tip.x / dx) as usize).min(n.saturating_sub(1));
            if n > 0 && !s.still[i] {
                s.vel[i] -= cursor.vel.len() * 0.02 * cfg.wake * live * h * 60.0 * (1.0 - (self.size.y - cursor.tip.y) / 90.0).clamp(0.0, 1.0);
            }
        }

        // ── each drop by itself ─────────────────────────────────────────────────────────────────────────────
        let mut landed: Vec<(usize, Edge, V, f32, f32)> = Vec::new();
        for i in 0..self.drops.len() {
            if !self.drops[i].there() {
                continue;
            }
            let level = if self.drops[i].edge == Edge::Bottom { self.level(self.drops[i].pos.x) } else { 0.0 };
            let d = &mut self.drops[i];
            let m = d.mass();
            match d.mode {
                Mode::Sits => {
                    let inward = d.edge.inward();
                    let along = v(-inward.y, inward.x);
                    let mut target = d.home + inward * (level / m.sqrt());
                    d.tip += (0.0 - d.tip) * (h * 14.0).min(1.0);
                    if d.chosen {
                        target += inward * (cfg.lift * d.lift * d.r * 0.5);
                    }
                    if cursor.there {
                        let to = cursor.tip - d.home;
                        let far = to.len();
                        if far < reach * d.reach && d.pull > 0.0 {
                            // only ever towards the cursor: lifted from its edge, leaning along it, a tip reaching out
                            let near = (1.0 - far / (reach * d.reach)).powi(2) * (cfg.pull * live * d.pull).min(1.2);
                            target += inward * (near * cfg.lift * d.lift * d.r) + along * (along.dot(to.unit()) * near * cfg.lean * d.r);
                            let want = (near * 2.0).min(1.0) * cfg.tip * d.r * if far > d.r { 1.0 } else { far / d.r };
                            d.tip += (want - d.tip) * (h * 30.0).min(1.0);
                            d.tip_angle = to.y.atan2(to.x);
                            // the wake: a pointer that flies past drags it along, the lighter the further
                            let fast = cursor.vel.len();
                            if fast > 400.0 {
                                d.vel += cursor.vel * (cfg.wake * near * h * 2.2 / m);
                            }
                            // a press on it flattens it from where it is touched
                            if cursor.down && far < d.r {
                                d.squash_v += 6.0 * h * 60.0 * (0.35 - d.squash);
                            }
                        }
                    }
                    if input.gale != 0.0 {
                        d.vel += along * (input.gale * cfg.wind * (self.clock * 1.3 + d.home.x * 0.011).sin() * h / m.sqrt());
                    }
                    let off = d.pos - target;
                    let (a, n) = (along.dot(off), inward.dot(off));
                    let (va, vn) = (along.dot(d.vel), inward.dot(d.vel));
                    // softer along the edge, stiffer and with an overshoot across it
                    let force = along * (-cfg.home_along * a - cfg.damp_along * va) + inward * (-cfg.home_across * n - cfg.damp_across * vn);
                    d.vel += force * h;
                    d.pos += d.vel * h;
                    energy += (d.vel.len() * 0.02 + off.len() * 0.25) * m.min(1.0).max(0.4);
                }
                Mode::Held => {
                    // where the hand has it; how fast the hand goes is what a throw starts with
                    let before = d.pos;
                    d.pos += (d.hand - d.pos) * (h * 60.0).min(1.0);
                    d.vel = d.vel * 0.8 + ((d.pos - before) * (1.0 / h)).capped(cfg.throw_max) * 0.2;
                    energy += 1.0 + cfg.rest_energy;
                }
                Mode::Flies => {
                    d.vel += v(0.0, cfg.gravity) * h;
                    d.vel = d.vel * (1.0 - (cfg.drag * h).min(0.9));
                    d.vel = d.vel.capped(cfg.throw_max);
                    d.pos += d.vel * h;
                    energy += 1.0 + cfg.rest_energy;
                    // a plate or a window's title: it comes back from the side it met
                    for w in &self.walls {
                        let (cx, cy) = (d.pos.x.clamp(w.x0, w.x1), d.pos.y.clamp(w.y0, w.y1));
                        let out = d.pos - v(cx, cy);
                        if out.len() < d.r && out.len() > 1e-3 {
                            let nrm = out.unit();
                            let into = d.vel.dot(nrm);
                            if into < 0.0 {
                                d.vel = d.vel - nrm * (into * (1.0 + d.bounce.unwrap_or(cfg.restitution)));
                                // on top of a plate nothing sticks: it hops off towards the open goo
                                if nrm.y < -0.7 {
                                    let left = w.x1 >= self.size.x - 1.0 || (w.x0 > 1.0 && d.pos.x - w.x0 < w.x1 - d.pos.x);
                                    d.vel = v(if left { -cfg.hop_off } else { cfg.hop_off }, d.vel.y.min(-cfg.hop_off * 0.8));
                                }
                            }
                            d.pos = v(cx, cy) + nrm * d.r;
                        }
                    }
                    let seat = cfg.level + cfg.seat * d.r;
                    let edges = [(Edge::Bottom, self.size.y - d.pos.y), (Edge::Left, d.pos.x), (Edge::Right, self.size.x - d.pos.x), (Edge::Top, d.pos.y)];
                    // an edge is met on the way into it: a drop that jumps off its own edge is not back at once
                    let mut hit = edges.iter().find(|e| e.1 <= seat && d.vel.dot(e.0.inward()) < 0.0).map(|e| e.0);
                    // held up by the drops it fell on, it has landed all the same: its home is the edge under it,
                    // and the others make room (the logic lays them out when it hears of the landing)
                    d.slow_for = if d.vel.len() < 60.0 { d.slow_for + h } else { 0.0 };
                    let rests = hit.is_none() && d.slow_for > 0.25;
                    if rests {
                        hit = Some(Edge::Bottom);
                    }
                    if let Some(edge) = hit {
                        let speed = d.vel.len();
                        d.slow_for = 0.0;
                        if rests {
                            d.pos.y = self.size.y - seat;
                        }
                        d.pos = v(d.pos.x.clamp(seat, self.size.x - seat), d.pos.y.clamp(seat, self.size.y - seat));
                        d.mode = Mode::Sits;
                        d.squash_v += (speed / cfg.throw_max).min(1.0) * 9.0;
                        if !d.keeps_home {
                            (d.home, d.edge) = (d.pos, edge);
                        }
                        // what is left of the speed along the edge stays: it slides to a stop, it does not freeze
                        let nrm = edge.inward();
                        d.vel = (d.vel - nrm * d.vel.dot(nrm)) * 0.35;
                        landed.push((i, edge, d.pos, (speed * m.sqrt() * cfg.splash).min(cfg.splash_max), d.r));
                    }
                }
            }
            // its shape: longer the way it goes (the area kept), flattened by what it met, both on springs
            let fast = d.vel.len();
            let want = if d.mode == Mode::Held { 0.0 } else { (fast / 1400.0).min(0.4) };
            d.stretch += (want - d.stretch) * (h * 18.0).min(1.0);
            if fast > 20.0 {
                d.rot = d.vel.y.atan2(d.vel.x);
            }
            d.squash_v += (-cfg.squash_k * d.squash - cfg.squash_c * d.squash_v) * h;
            d.squash = (d.squash + d.squash_v * h).clamp(-0.3, 0.5);
            energy += d.squash.abs() * 40.0 + d.tip * 0.02;
        }
        for (i, edge, at, push, r) in landed {
            if edge == Edge::Bottom {
                self.splash(at.x, 60.0 + r * 1.6, push);
            }
            self.events.push(Event::Landed(i, edge, at));
        }

        // ── drops against each other ────────────────────────────────────────────────────────────────────────
        let count = self.drops.len();
        for i in 0..count {
            for j in i + 1..count {
                let (a, b) = (&self.drops[i], &self.drops[j]);
                if !a.there() || !b.there() || (a.mode == Mode::Sits && b.mode == Mode::Sits && a.edge != b.edge) {
                    continue;
                }
                let (sum, apart) = (a.r + b.r, b.pos - a.pos);
                let far = apart.len();
                let nrm = apart.unit();
                let (ma, mb) = (a.mass(), b.mass());
                // what their homes overlap by is the layout's own (neighbours touch and melt): only more than that pushes
                let meant = if a.mode == Mode::Sits && b.mode == Mode::Sits { (sum - (b.home - a.home).len()).max(0.0) } else { 0.0 };
                let known = self.joints.iter().position(|t| t.a == i && t.b == j);
                // a thread: made when they press together, thinner the further apart, torn past its length
                match known {
                    None if far < cfg.join * sum && a.mode != Mode::Flies && b.mode != Mode::Flies => {
                        self.joints.push(Joint { a: i, b: j, width: cfg.thread * a.r.min(b.r) });
                        self.events.push(Event::Joined(i));
                    }
                    Some(t) if far > cfg.part * sum => {
                        self.joints.swap_remove(t);
                        self.events.push(Event::Parted(i));
                        // the recoil of a thread that snapped
                        self.drops[i].vel += nrm * (-cfg.recoil / ma);
                        self.drops[j].vel += nrm * (cfg.recoil / mb);
                    }
                    Some(t) => {
                        let stretched = ((far - sum) / sum).max(0.0);
                        self.joints[t].width = cfg.thread * self.drops[i].r.min(self.drops[j].r) / (1.0 + cfg.thin * stretched);
                        // and it pulls a little while it holds
                        let pull = nrm * (cfg.thread_pull * stretched * h);
                        if self.drops[i].mode == Mode::Sits {
                            self.drops[i].vel += pull * (1.0 / ma);
                        }
                        if self.drops[j].mode == Mode::Sits {
                            self.drops[j].vel += pull * (-1.0 / mb);
                        }
                    }
                    None => {}
                }
                let over = sum - far - meant;
                if over <= 0.0 {
                    continue;
                }
                // soft bodies: pushed apart by how far they overlap, each by the other's share of the mass
                let (a, b) = (&self.drops[i], &self.drops[j]);
                let closing = (a.vel - b.vel).dot(nrm);
                let bounce = a.bounce.unwrap_or(cfg.restitution).max(b.bounce.unwrap_or(cfg.restitution));
                let push = cfg.push * over * h + if closing > 0.0 { closing * (1.0 + bounce) * (h * 30.0).min(1.0) } else { 0.0 };
                let (ha, hb) = (a.mode == Mode::Held, b.mode == Mode::Held);
                let share = |own: f32, other: f32, held: bool, other_held: bool| if held { 0.0 } else if other_held { 1.0 } else { other / (own + other) };
                let (sa, sb) = (share(ma, mb, ha, hb), share(mb, ma, hb, ha));
                // told once, on the step they first touch: the overlap is then no deeper than a step of closing
                let hard = closing > cfg.bump_speed && over <= closing * h * 1.5;
                self.drops[i].vel += nrm * (-push * sa);
                self.drops[j].vel += nrm * (push * sb);
                if hard {
                    self.drops[i].squash_v += 2.5;
                    self.drops[j].squash_v += 2.5;
                    self.events.push(Event::Bumped(i, j));
                }
                energy += over * 0.3;
            }
        }
        // a thread whose end went away
        let drops = &self.drops;
        self.joints.retain(|t| drops.get(t.a).is_some_and(Drop::there) && drops.get(t.b).is_some_and(Drop::there));

        // ── the cursor's own body ───────────────────────────────────────────────────────────────────────────
        let c = &mut self.cursor;
        if c.there && cfg.cursor_body > 0.5 {
            let off = c.belly - c.tip;
            let before = c.belly_v;
            c.belly_v += (off * -cfg.cursor_k + c.belly_v * -cfg.cursor_c) * h;
            c.belly += c.belly_v * h;
            // the belly is never further behind than its neck is long: past that it is dragged along
            let behind = c.belly - c.tip;
            if behind.len() > cfg.cursor_tail {
                let out = behind.unit();
                c.belly = c.tip + out * cfg.cursor_tail;
                c.belly_v = c.belly_v - out * c.belly_v.dot(out).max(0.0);
            }
            // what is left when it brakes: the mass goes on and swings back, two swings and still
            let braking = (before - c.belly_v).len() / h;
            c.wobble_v += (-260.0 * c.wobble - 9.0 * c.wobble_v) * h + braking * 0.000_006;
            c.wobble = (c.wobble + c.wobble_v * h).clamp(-1.0, 1.0);
            let fast = c.vel.len();
            c.stretch += ((fast / 2000.0 * 0.35).min(0.5) - c.stretch) * (h * 20.0).min(1.0);
            if fast > 30.0 {
                c.rot = c.vel.y.atan2(c.vel.x);
            }
            energy += (c.belly - c.tip).len() * 0.2 + c.belly_v.len() * 0.02 + c.wobble.abs() * 20.0 + c.stretch * 20.0;
        }
        energy
    }
}

#[cfg(test)]
mod tests;
