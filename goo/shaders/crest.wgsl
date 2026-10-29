// The light on the coffee's surface: a thin bright edge where the swell catches the sun, a soft glow around it that
// reaches a little into the air, a band of crema just under it, and two faint ribbons of light further down that
// follow the swell at their own pace. Drawn in a group with `mode: add`, so it is light added, never paint.
//   The surface is worked out here through the same points as the body in parts/surface.plm, from the same waves as
//   goo/gen.py (WAVES, SPAN: change both).
//   a.x how much light, a.y where it is strongest (x), a.z chop, a.w gale;  b.x where the coffee stands at rest,
//   from this box's top;  b.y 0 sun · 1 moon.  color the sun's, color2 the moon's.

fn hash(p: vec2<f32>) -> f32 {
    let q = fract(p * vec2<f32>(0.1031, 0.1030));
    let r = q + dot(q, q.yx + 33.33);
    return fract((r.x + r.y) * r.x);
}
fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let w = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2<f32>(1.0, 0.0)), w.x),
               mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), w.x), w.y);
}

// at the point x0 of the still surface: how far its crest leans along (x), how high it stands (y), how the
// height turns along x0 (z) and how the lean does (w)
fn swell(x0: f32, t: f32, gale: f32) -> vec4<f32> {
    let wl = array<f32, 6>(820.0, 430.0, 250.0, 150.0, 70.0, 1300.0);
    let am = array<f32, 6>(7.0, 4.2, 2.6, 1.5, 1.8 * gale, 6.0 * gale);
    let om = array<f32, 6>(22.0, 31.0, 44.0, 63.0, 90.0, 17.0);
    let ph = array<f32, 6>(0.0, 70.0, 200.0, 310.0, 40.0, 120.0);
    var out = vec4<f32>(0.0);
    for (var j = 0; j < 6; j = j + 1) {
        let k = 6.2831853 / wl[j];
        let th = k * x0 - radians(om[j]) * t + radians(ph[j]);
        out = out + am[j] * vec4<f32>(sin(th), cos(th), -k * sin(th), k * cos(th));
    }
    return out;
}

// light across a line d px away: a hair `w` wide and a glow `g` wide
fn streak(d: f32, w: f32, g: f32) -> vec2<f32> {
    return vec2<f32>(exp(-abs(d) / w), exp(-abs(d) / g));
}

// one of the points the coffee's body is drawn through (parts/surface.plm: SPAN lines over W + 160 px), as x, y
fn point(i: i32, w: f32, t: f32, chop: f32, gale: f32, lean: f32) -> vec2<f32> {
    let x0 = -80.0 + (w + 160.0) * f32(i) / 32.0;
    let v = swell(x0, t, gale);
    return vec2<f32>(x0 - lean * v.x, -chop * v.y);
}

fn shade(s: Shader) -> vec4<f32> {
    let x = s.pos.x;
    let t = s.time;
    let chop = s.a.z;
    let gale = s.a.w;
    let lean = (2.5 + 1.5 * gale) * chop;
    // The body is lines between points that its blend rounds: the light follows a smooth curve through the same
    // points, or it would draw the sharp crests the body does not have. Which segment holds x: from where the
    // still point would have leaned to, then a step either way.
    var x0 = x;
    for (var n = 0; n < 3; n = n + 1) {
        x0 = x + lean * swell(x0, t, gale).x;
    }
    let seg = (s.size.x + 160.0) / 32.0;
    var i = clamp(i32(floor((x0 + 80.0) / seg)), 1, 30);
    var p1 = point(i, s.size.x, t, chop, gale, lean);
    var p2 = point(i + 1, s.size.x, t, chop, gale, lean);
    if (x < p1.x && i > 1) { i = i - 1; p2 = p1; p1 = point(i, s.size.x, t, chop, gale, lean); }
    if (x >= p2.x && i < 30) { i = i + 1; p1 = p2; p2 = point(i + 1, s.size.x, t, chop, gale, lean); }
    let p0 = point(i - 1, s.size.x, t, chop, gale, lean);
    let p3 = point(i + 2, s.size.x, t, chop, gale, lean);
    let u = clamp((x - p1.x) / max(p2.x - p1.x, 1.0), 0.0, 1.0);
    let m1 = 0.5 * (p2.y - p0.y);
    let m2 = 0.5 * (p3.y - p1.y);
    let u2 = u * u;
    let u3 = u2 * u;
    let height = (2.0 * u3 - 3.0 * u2 + 1.0) * p1.y + (u3 - 2.0 * u2 + u) * m1 + (-2.0 * u3 + 3.0 * u2) * p2.y + (u3 - u2) * m2;
    let rise = ((6.0 * u2 - 6.0 * u) * p1.y + (3.0 * u2 - 4.0 * u + 1.0) * m1 + (-6.0 * u2 + 6.0 * u) * p2.y + (3.0 * u2 - 2.0 * u) * m2) / max(p2.x - p1.x, 1.0);
    let d = s.pos.y - (s.b.x + height);                          // below the surface, in px

    // strongest under the light, never quite gone at the sides; glints run along it, a steep side sends it elsewhere
    let reach = 0.16 + 0.84 * exp(-pow((x - s.a.y) / (s.size.x * 0.24), 2.0));
    let glint = 0.6 + 0.4 * vnoise(vec2<f32>(x * 0.03 - t * 0.6, t * 0.2));
    let tilt = clamp(1.0 - abs(rise) * 2.0, 0.4, 1.0);

    // the edge: the hair sits on the surface, the glow spills a little up into the air and further down
    let edge = streak(d - 1.0, 1.0, select(7.0, 22.0, d > 0.0));
    let hair = edge.x * glint * tilt;
    let glow = edge.y * (0.6 + 0.4 * glint) * tilt;
    // crema: a warm band just under the surface, thinning with depth
    let crema = smoothstep(0.0, 5.0, d) * exp(-d / 30.0);
    // two ribbons deeper down that cross each other: the swell reaches them only in part, each has its own lazy line
    let calm1 = d + 0.55 * height;
    let calm2 = d + 0.8 * height;
    let r1 = calm1 - (26.0 + 16.0 * sin(x * 0.0037 + t * 0.31) + 4.0 * sin(x * 0.011 - t * 0.47));
    let r2 = calm2 - (34.0 + 22.0 * sin(x * 0.0026 - t * 0.23 + 1.7) + 5.0 * sin(x * 0.0083 + t * 0.39));
    let f1 = smoothstep(0.3, 0.75, vnoise(vec2<f32>(x * 0.0026 + t * 0.05, 1.0)));
    let f2 = smoothstep(0.3, 0.75, vnoise(vec2<f32>(x * 0.0021 - t * 0.04, 7.0)));
    let s1 = streak(r1, 1.1, 10.0) * f1;
    let s2 = streak(r2, 1.3, 13.0) * f2;

    let sun = mix(s.color.rgb, s.color2.rgb, s.b.y);
    let white = mix(sun, vec3<f32>(1.0, 0.97, 0.9), 0.45);       // the hottest light is nearly white
    let deep = sun * vec3<f32>(0.9, 0.52, 0.16);                 // what the coffee leaves of it
    let rgb = white * hair * 1.2
            + sun * glow * 0.6
            + deep * crema * 0.4
            + white * 0.6 * s1.x + sun * 0.22 * s1.y
            + white * 0.45 * s2.x + sun * 0.18 * s2.y;
    // in `mode: add` only colour times coverage counts: hand the light over as its brightest channel
    let c = rgb * s.a.x * reach;
    let a = clamp(max(c.r, max(c.g, c.b)), 0.0, 1.0);
    return vec4<f32>(c / max(a, 0.001), a);
}
