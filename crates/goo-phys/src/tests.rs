use super::*;

const SCREEN: (f32, f32) = (1920.0, 1080.0);

fn world() -> World {
    World::new(SCREEN.0, SCREEN.1, Config::default())
}

fn seated(w: &mut World, x: f32, r: f32) -> usize {
    w.drops.push(Drop::new(v(x, SCREEN.1 - 6.0 - r * 0.8), r, Edge::Bottom));
    w.drops.len() - 1
}

fn run(w: &mut World, seconds: f32, fps: f32, input: &Input) -> f32 {
    let mut left = 0.0;
    for _ in 0..(seconds * fps).round() as usize {
        left = w.step(1.0 / fps, input);
    }
    left
}

#[test]
fn a_wave_comes_back_from_the_wall_and_dies() {
    let mut w = world();
    w.splash(60.0, 80.0, 200.0);
    run(&mut w, 0.3, 60.0, &Input::default());
    assert!(w.surface.h[2].abs() > 0.05, "the wave is there");
    assert!(w.level(700.0).abs() < 0.01, "and has not got far yet");
    let mut reached = 0.0f32;
    for _ in 0..180 {
        w.step(1.0 / 60.0, &Input::default());
        reached = reached.max(w.level(700.0).abs());
    }
    assert!(reached > 0.01, "it travels along the edge: {reached}");
    assert_eq!(run(&mut w, 20.0, 60.0, &Input::default()), 0.0, "and died");
    assert!(w.surface.h.iter().all(|h| *h == 0.0));
}

#[test]
fn a_plate_stands_in_the_water() {
    let mut w = world();
    w.set_walls(vec![Wall { x0: 800.0, y0: 1000.0, x1: 1100.0, y1: 1080.0 }]);
    w.splash(300.0, 80.0, 300.0);
    let mut beyond = 0.0f32;
    for _ in 0..300 {
        w.step(1.0 / 60.0, &Input::default());
        beyond = beyond.max(w.level(1500.0).abs()).max(w.level(950.0).abs());
    }
    assert_eq!(beyond, 0.0, "nothing passes a plate, nothing moves under it");
}

#[test]
fn two_drops_do_not_overlap() {
    let mut w = world();
    let (a, b) = (seated(&mut w, 500.0, 26.0), seated(&mut w, 510.0, 26.0));
    w.wake();
    // the logic gives them homes that do not overlap once one has landed; here it never does, and still
    w.drops[a].home.x = 480.0;
    w.drops[b].home.x = 540.0;
    run(&mut w, 2.0, 60.0, &Input::default());
    let far = (w.drops[a].pos - w.drops[b].pos).len();
    assert!(far >= 52.0 - 0.5, "{far}");
}

#[test]
fn a_bump_between_drops_is_told() {
    let mut w = world();
    let (a, b) = (seated(&mut w, 500.0, 26.0), seated(&mut w, 580.0, 26.0));
    w.nudge(a, v(1400.0, 0.0));
    run(&mut w, 0.5, 60.0, &Input::default());
    let told: Vec<Event> = w.drain_events().collect();
    assert_eq!(told.iter().filter(|e| **e == Event::Bumped(a, b)).count(), 1, "{told:?}");
    assert!(told.contains(&Event::Joined(a)), "pressed together, a thread: {told:?}");
}

#[test]
fn dropped_it_falls_straight_and_thrown_it_flies_an_arc() {
    let mut w = world();
    let k = seated(&mut w, 900.0, 26.0);
    w.drops[k].pos = v(900.0, 400.0);
    w.throw(k, V::default());
    run(&mut w, 3.0, 60.0, &Input::default());
    let told: Vec<Event> = w.drain_events().collect();
    assert!(matches!(told[..], [Event::Landed(0, Edge::Bottom, at)] if (at.x - 900.0).abs() < 0.01), "{told:?}");
    assert_eq!(w.drops[k].mode, Mode::Sits);

    w.drops[k].pos = v(900.0, 400.0);
    w.throw(k, v(700.0, -500.0));
    let mut top = 400.0f32;
    for _ in 0..240 {
        w.step(1.0 / 60.0, &Input::default());
        top = top.min(w.drops[k].pos.y);
    }
    let told: Vec<Event> = w.drain_events().collect();
    let Some(Event::Landed(_, edge, at)) = told.first().copied() else { panic!("it never landed: {told:?}") };
    assert!(top < 330.0, "it rose first: {top}");
    assert!(edge == Edge::Bottom && at.x > 1100.0, "and came down further on: {edge:?} {at:?}");
    assert!(w.surface.h.iter().any(|h| h.abs() > 0.2) || w.stir > 0.0, "the level felt it");
}

#[test]
fn a_thrown_drop_comes_back_from_a_plate() {
    let mut w = world();
    w.set_walls(vec![Wall { x0: 1200.0, y0: 0.0, x1: 1260.0, y1: 1080.0 }]);
    let k = seated(&mut w, 900.0, 26.0);
    w.drops[k].pos = v(900.0, 300.0);
    w.throw(k, v(1500.0, 0.0));
    run(&mut w, 4.0, 60.0, &Input::default());
    assert!(w.drops[k].pos.x < 1200.0, "{:?}", w.drops[k].pos);
}

#[test]
fn the_world_comes_to_rest() {
    let mut w = world();
    for i in 0..12 {
        seated(&mut w, 200.0 + 120.0 * i as f32, 22.0 + i as f32);
    }
    let over = Input { pointer: Some(v(700.0, 1000.0)), ..Input::default() };
    assert!(run(&mut w, 1.0, 60.0, &over) > 0.0, "a cursor that arrived stirs it");
    assert!(w.drops.iter().any(|d| (d.pos - d.home).len() > 4.0 && d.tip > 1.0), "and draws the drops near it");
    // the cursor leaves: within three seconds nothing moves and everything is exactly at home
    let mut frames = 0;
    while w.step(1.0 / 60.0, &Input::default()) > 0.0 {
        frames += 1;
        assert!(frames < 180, "still moving after three seconds");
    }
    assert!(w.drops.iter().all(|d| d.pos == d.home && d.vel == V::default()));
    assert_eq!(w.stir, 0.0);
    // and a cursor that stands still keeps nothing awake either
    assert!(run(&mut w, 0.2, 60.0, &over) > 0.0);
    assert_eq!(run(&mut w, 4.0, 60.0, &over), 0.0);
}

#[test]
fn the_frame_rate_does_not_change_the_result() {
    let at = |fps: f32| {
        let mut w = world();
        let k = seated(&mut w, 600.0, 26.0);
        seated(&mut w, 700.0, 30.0);
        w.drops[k].pos = v(600.0, 500.0);
        w.throw(k, v(300.0, -200.0));
        run(&mut w, 2.5, fps, &Input::default());
        w.drops[k].pos
    };
    let (slow, usual, fast) = (at(24.0), at(60.0), at(144.0));
    // a fixed step: the frames only decide how many steps each one takes, so it lands in the same place
    assert!((slow - usual).len() < 1.0 && (fast - usual).len() < 1.0, "{slow:?} {usual:?} {fast:?}");
}

#[test]
fn tier_zero_moves_nothing() {
    let mut w = world();
    w.cfg.tier = 0.0;
    let k = seated(&mut w, 600.0, 26.0);
    w.nudge(k, v(500.0, -500.0));
    let over = Input { pointer: Some(v(610.0, 1000.0)), down: true, gale: 1.0 };
    assert_eq!(run(&mut w, 1.0, 60.0, &over), 0.0);
    assert_eq!(w.drops[k].pos, w.drops[k].home);
}

#[test]
fn the_cursor_is_a_drop_with_a_tip() {
    let mut w = world();
    let rest = v(w.cfg.cursor_dx, w.cfg.cursor_dy);
    let mut x = 100.0;
    for _ in 0..30 {
        x += 30.0; // 1800 px/s to the right
        w.step(1.0 / 60.0, &Input { pointer: Some(v(x, 300.0)), ..Input::default() });
    }
    assert_eq!(w.cursor.tip, v(x, 300.0), "the tip is the pointer itself, never late");
    assert!(w.cursor.belly.x < w.cursor.tip.x - 8.0, "its belly is dragged behind, like a stick held by one end: {:?}", w.cursor.belly - w.cursor.tip);
    assert!(w.cursor.stretch > 0.2, "and its neck is longer at speed: {}", w.cursor.stretch);
    let stop = Input { pointer: Some(v(x, 300.0)), ..Input::default() };
    let mut swung = 0.0f32;
    for _ in 0..20 {
        w.step(1.0 / 60.0, &stop);
        swung = swung.max(w.cursor.belly.x - w.cursor.tip.x - rest.x);
    }
    assert!(swung > 0.5, "it swings past its rest when the tip stops: {swung}");
    assert_eq!(run(&mut w, 3.0, 60.0, &stop), 0.0, "and is still");
    assert_eq!(w.cursor.belly, w.cursor.tip + rest, "hanging down and to the right, as an arrow lies");
}

#[test]
fn a_shaken_cursor_grows_to_be_found() {
    let mut w = world();
    let mut x = 500.0f32;
    for i in 0..40 {
        x += if (i / 5) % 2 == 0 { 30.0 } else { -30.0 }; // back and forth, five frames each way
        w.step(1.0 / 60.0, &Input { pointer: Some(v(x, 300.0)), ..Input::default() });
    }
    assert!(w.cursor.big > 0.5, "{}", w.cursor.big);
    assert_eq!(run(&mut w, 4.0, 60.0, &Input { pointer: Some(v(x, 300.0)), ..Input::default() }), 0.0);
    assert_eq!(w.cursor.big, 0.0, "and is its own size again");
}

#[test]
fn every_number_has_a_name() {
    let mut c = Config::default();
    for (name, value, what) in Config::NAMES {
        assert_eq!(c.get(name), Some(*value));
        assert!(!what.is_empty());
    }
    assert!(c.set("gravity", 400.0) && c.gravity == 400.0);
    assert!(!c.set("gravity", f32::NAN) && !c.set("no such", 1.0));
}

#[test]
fn gravity_is_down_but_goo_clings_to_a_side() {
    let mut w = world();
    let k = seated(&mut w, 900.0, 26.0);
    // let go slowly by the left side: it clings where it is, it does not slide down
    w.drops[k].pos = v(60.0, 500.0);
    w.throw(k, V::default());
    run(&mut w, 2.0, 60.0, &Input::default());
    let told: Vec<Event> = w.drain_events().collect();
    assert!(matches!(told[..], [Event::Landed(0, Edge::Left, at)] if at.y == 500.0), "{told:?}");
    assert!((w.drops[k].edge, w.drops[k].pos.y) == (Edge::Left, 500.0) && w.drops[k].pos.x < 30.0, "{:?}", w.drops[k].pos);
    // further in, nothing pulls it sideways: it falls straight down
    w.drops[k].pos = v(200.0, 500.0);
    w.throw(k, V::default());
    run(&mut w, 3.0, 60.0, &Input::default());
    let told: Vec<Event> = w.drain_events().collect();
    assert!(matches!(told[..], [Event::Landed(0, Edge::Bottom, at)] if (at.x - 200.0).abs() < 0.01), "{told:?}");
    // thrown hard at the side it flies into it and stays
    w.drops[k].pos = v(300.0, 400.0);
    w.throw(k, v(-1500.0, -300.0));
    run(&mut w, 3.0, 60.0, &Input::default());
    assert!(matches!(w.drain_events().next(), Some(Event::Landed(0, Edge::Left, _))));
}

#[test]
fn a_jump_from_a_side_is_pulled_back_by_its_hold() {
    let mut w = world();
    w.drops.push(Drop::new(v(26.8, 500.0), 26.0, Edge::Left));
    w.jump(0, v(500.0, 0.0));
    let mut out = 0.0f32;
    for _ in 0..120 {
        w.step(1.0 / 60.0, &Input::default());
        out = out.max(w.drops[0].pos.x);
        assert!((w.drops[0].pos.y - 500.0).abs() < 1.0, "it does not fall: {:?}", w.drops[0].pos);
    }
    assert!(out > 40.0, "it went out: {out}");
    assert_eq!(run(&mut w, 3.0, 60.0, &Input::default()), 0.0);
    assert_eq!(w.drops[0].pos, v(26.8, 500.0));
}

#[test]
fn a_jump_leaves_its_edge_and_lands_at_home() {
    let mut w = world();
    let k = seated(&mut w, 900.0, 26.0);
    let home = w.drops[k].home;
    w.jump(k, v(120.0, -500.0));
    let mut top = home.y;
    for _ in 0..180 {
        w.step(1.0 / 60.0, &Input::default());
        top = top.min(w.drops[k].pos.y);
    }
    assert!(top < home.y - 80.0, "it went up: {top}");
    run(&mut w, 10.0, 60.0, &Input::default());       // the wave it made dies too
    assert_eq!((w.drops[k].home, w.drops[k].pos), (home, home));
}

#[test]
fn a_held_drop_is_where_the_hand_is_and_one_that_returns_comes_home() {
    let mut w = world();
    let k = seated(&mut w, 900.0, 26.0);
    let home = w.drops[k].home;
    w.drops[k].returns = true;
    w.hold(k);
    for i in 0..30 {
        w.drops[k].hand = v(900.0 + 10.0 * i as f32, 700.0);
        w.step(1.0 / 60.0, &Input::default());
    }
    assert!((w.drops[k].pos - v(1190.0, 700.0)).len() < 12.0, "{:?}", w.drops[k].pos);
    assert!(w.drops[k].vel.x > 300.0, "it has the hand's speed: {:?}", w.drops[k].vel);
    let speed = w.drops[k].vel;
    w.throw(k, speed);
    assert_eq!(run(&mut w, 4.0, 60.0, &Input::default()), 0.0);
    assert_eq!(w.drops[k].pos, home);
}

#[test]
fn a_thread_comes_of_sticking_not_of_coming_near() {
    let mut w = world();
    let (a, b) = (seated(&mut w, 500.0, 26.0), seated(&mut w, 580.0, 26.0));
    // one falls past the other, a hand's width away: near, never touching, no thread
    w.drops[a].pos = v(520.0, 300.0);
    w.throw(a, V::default());
    run(&mut w, 3.0, 60.0, &Input::default());
    assert!(w.joints.is_empty(), "{:?}", w.joints);
    // touching, they stick; pulled apart the thread thins, and past its length it tears
    w.drops[a].home = v(535.0, w.drops[b].home.y);
    run(&mut w, 2.0, 60.0, &Input::default());
    assert_eq!(w.joints.len(), 1, "they touched");
    let thick = w.joints[0].width;
    w.hold(a);
    w.drops[a].hand = w.drops[b].pos - v(100.0, 0.0);
    run(&mut w, 0.5, 60.0, &Input::default());
    assert!(w.joints.len() == 1 && w.joints[0].width < thick * 0.6, "thinner as they part: {:?}", w.joints);
    w.drops[a].hand = w.drops[b].pos - v(200.0, 0.0);
    run(&mut w, 0.5, 60.0, &Input::default());
    assert!(w.joints.is_empty(), "torn");
    let _ = b;
}

#[test]
fn a_drop_that_falls_on_others_lands_too() {
    let mut w = world();
    let (a, b) = (seated(&mut w, 500.0, 30.0), seated(&mut w, 556.0, 30.0));
    let k = seated(&mut w, 900.0, 26.0);
    w.drops[k].pos = v(528.0, 600.0);
    w.throw(k, V::default());
    run(&mut w, 4.0, 60.0, &Input::default());
    assert!(w.drain_events().any(|e| matches!(e, Event::Landed(2, Edge::Bottom, _))), "held up by the two, it still lands");
    assert_eq!(w.drops[k].mode, Mode::Sits);
    assert_eq!(run(&mut w, 8.0, 60.0, &Input::default()), 0.0, "and the world comes to rest");
    let _ = (a, b);
}

#[test]
fn what_falls_in_makes_a_hollow_with_a_rim_and_spills_nothing() {
    let mut w = world();
    w.splash(960.0, 120.0, 300.0);
    run(&mut w, 0.05, 240.0, &Input::default());
    let (mid, rim) = (w.level(960.0), w.level(960.0 + 55.0));
    assert!(mid < -0.5 && rim > 0.2, "down in the middle, up around it: {mid} {rim}");
    let sum: f32 = w.surface.h.iter().sum();
    assert!(sum.abs() < 0.05 * w.surface.h.iter().map(|h| h.abs()).sum::<f32>(), "as much up as down: {sum}");
    // a big drop makes a bigger wave than a small one, and neither a wall: the level is never cut flat at its top
    let wave = |r: f32| {
        let mut w = world();
        let k = seated(&mut w, 900.0, r);
        w.drops[k].pos = v(900.0, 300.0);
        w.throw(k, V::default());
        let mut high = 0.0f32;
        for _ in 0..240 {
            w.step(1.0 / 60.0, &Input::default());
            high = w.surface.h.iter().fold(high, |a, h| a.max(h.abs()));
        }
        high
    };
    let (small, big) = (wave(20.0), wave(57.0));
    assert!(big > small * 1.3 && big < w.cfg.wave_max * 0.9, "{small} {big}");
}

#[test]
fn a_pointer_far_from_everything_wakes_nothing() {
    let mut w = world();
    w.cfg.cursor_body = 0.0;
    seated(&mut w, 300.0, 26.0);
    let mut x = 900.0;
    let mut left = 1.0;
    for _ in 0..120 {
        x += 5.0;
        left = w.step(1.0 / 60.0, &Input { pointer: Some(v(x, 300.0)), ..Input::default() });
    }
    assert_eq!(left, 0.0, "over a window in the middle of the screen the world sleeps on");
    assert!(run(&mut w, 0.2, 60.0, &Input { pointer: Some(v(320.0, 1000.0)), ..Input::default() }) > 0.0, "by a drop it wakes");
}
