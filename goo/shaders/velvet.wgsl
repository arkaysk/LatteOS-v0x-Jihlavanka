// The coffee under a card's divider, in three velvet layers: a golden one behind, a caramel one, the coffee in front.
// Each is lit softly from under its edge, a satin band that slides along as the surface tilts towards or away from
// the light, never a hard line; slow waves of their own keep them alive. A card that opens swings them once
// (parts/rows.plm), the back ones a little less, so they part and meet. App windows draw the same
// (apps/common/shaders/velvet.frag: change both).
//   a.x px the surface stands higher at the left wall than in the middle, a.y px of a second wave across it (down at
//   the walls), a.z px the level has gone down, a.w how much light;  b.x where the front layer rests, px from the
//   box's top (its bottom when b.z is 1: the coffee hangs from a card's top), b.y where the light is (0…1).
//   color the light's, color2 the coffee's.

const BACK = vec3<f32>(0.722, 0.525, 0.180);                    // #b8862e, the golden coffee behind

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

// where layer k's edge stands at x, and how it slopes there
fn edge(k: f32, x: f32, s: Shader) -> vec2<f32> {
    let w = s.size.x;
    let u = x / w;
    let pi = 3.14159265;
    let m = 1.0 - 0.18 * k;
    let swing = m * (-s.a.x * (1.0 - 2.0 * u) + s.a.y * cos(2.0 * pi * u) + s.a.z);
    let dswing = m * (2.0 * s.a.x - s.a.y * 2.0 * pi * sin(2.0 * pi * u)) / w;
    let dirn = select(1.0, -1.0, k == 1.0);
    let f1 = 6.2831853 * (1.1 + 0.4 * k) / w;
    let f2 = 6.2831853 * (2.7 + 0.9 * k) / w;
    let p1 = f1 * x + dirn * (0.55 + 0.1 * k) * s.time + 1.7 * k;
    let p2 = f2 * x - dirn * (0.9 + 0.2 * k) * s.time + 0.6 * k;
    let a1 = 3.2 - 0.6 * k;
    let a2 = 1.3;
    return vec2<f32>(s.b.x - 16.0 + 8.0 * k + swing + a1 * sin(p1) + a2 * sin(p2), dswing + a1 * f1 * cos(p1) + a2 * f2 * cos(p2));
}

fn shade(s: Shader) -> vec4<f32> {
    let x = s.pos.x;
    let y = select(s.pos.y, s.size.y - s.pos.y, s.b.z > 0.5);
    let t = s.time;
    let light = s.a.w;
    let lc = s.color.rgb * light;
    let lx = s.b.y * s.size.x;
    let reach = 0.3 + 0.7 * exp(-pow((x - lx) / (s.size.x * 0.4), 2.0));
    let toward = clamp((lx - x) / 90.0, -1.0, 1.0);
    let coffee = s.color2.rgb;
    let tones = array<vec3<f32>, 3>(mix(BACK * 1.25, vec3<f32>(0.93, 0.70, 0.40), 0.35), mix(BACK, coffee, 0.55), coffee);

    var rgb = vec3<f32>(0.0);
    var a = 0.0;
    let above = edge(0.0, x, s).x - y;
    if (above > 0.0) {                                           // a glow in the air over the back layer
        let g = lc * 0.35 * exp(-above / 7.0) * reach;
        a = clamp(max(g.r, max(g.g, g.b)), 0.0, 1.0);
        rgb = g / max(a, 0.001);
    }
    for (var i = 0; i < 3; i = i + 1) {
        let k = f32(i);
        let e = edge(k, x, s);
        let d = y - e.x;
        let cover = smoothstep(-0.8, 0.8, d);
        if (cover <= 0.0) { continue; }
        let facing = clamp(0.55 - toward * e.y * 4.0, 0.15, 1.0);
        var c = tones[i] * (0.7 + 0.3 * exp(-d / 40.0)) * (0.92 + 0.08 * vnoise(vec2<f32>(x * 0.09 + k * 13.0, d * 0.5 - t * 0.2)));
        let rim = exp(-max(d, 0.0) / 1.6);
        let satin = exp(-pow((d - 7.0 - 2.0 * k) / (5.0 + 2.0 * k), 2.0));
        c = c + mix(s.color.rgb, vec3<f32>(1.0, 0.95, 0.85), 0.4) * rim * 0.95 * reach * facing * light
              + lc * reach * facing * (1.0 - 0.25 * k) * satin * 0.5;
        if (i == 2) {                                            // the front layer carries two ribbons of light, wide and soft
            let r1 = d - (24.0 + 7.0 * sin(x * 0.011 + t * 0.3));
            let r2 = d - (38.0 + 9.0 * sin(x * 0.008 - t * 0.21 + 1.7));
            c = c + lc * (0.22 * exp(-abs(r1) / 2.2) + 0.08 * exp(-abs(r1) / 9.0) + 0.14 * exp(-abs(r2) / 2.6)) * (0.5 + 0.5 * reach);
        }
        rgb = mix(rgb, c, cover);
        a = a + (1.0 - a) * cover;
    }
    return vec4<f32>(rgb, a);
}
