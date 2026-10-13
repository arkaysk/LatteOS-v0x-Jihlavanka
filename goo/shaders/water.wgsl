// What the coffee does with light and with what settled in it.
//   Light that goes in: each ray is bent once at the surface, by the same waves that draw it (the table is
//   the one in goo/gen.py: change both), plus ripples too small to be drawn. Where neighbouring rays meet,
//   the light gathers into bright lines; where they part, it thins. The liquid is thick: it takes the
//   blue first, then the green, so the light goes from amber to deep red as it sinks.
//   The grounds: dark shapes that drift over the bottom, and ripple marks in the sand under them.
//   a.x how much light there is, a.y where it is, in x, a.z how far it leans per px of depth,
//   a.w 0 sun · 1 moon or sky;  b.x how far the bottom of the screen is below this box's top, b.y the wind (0…1.6).
//   color the sun's, color2 the moon's.

// noise that is not a pattern: a hash on a grid, smoothly joined
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
fn fbm(p: vec2<f32>) -> f32 {
    return 0.5 * vnoise(p) + 0.3 * vnoise(p * 2.13 + 7.1) + 0.2 * vnoise(p * 4.37 + 3.7);
}
// the surface at x: its slope (x) and how it curves (y)
fn surface(x: f32, t: f32, gale: f32) -> vec2<f32> {
    let wl = array<f32, 8>(820.0, 430.0, 250.0, 150.0, 70.0, 1300.0, 96.0, 57.0);
    let am = array<f32, 8>(7.0, 4.2, 2.6, 1.5, 1.8 * gale, 6.0 * gale, 0.9, 0.5);
    let om = array<f32, 8>(22.0, 31.0, 44.0, 63.0, 90.0, 17.0, 74.0, 118.0);
    let ph = array<f32, 8>(0.0, 70.0, 200.0, 310.0, 40.0, 120.0, 150.0, 260.0);
    var out = vec2<f32>(0.0, 0.0);
    for (var j = 0; j < 8; j = j + 1) {
        let k = 6.2831853 / wl[j];
        let th = k * x - radians(om[j]) * t + radians(ph[j]);
        out = out + vec2<f32>(am[j] * k * sin(th), am[j] * k * k * cos(th));
    }
    return out;
}

fn shade(s: Shader) -> vec4<f32> {
    let x = s.pos.x;
    let d = s.pos.y;
    let t = s.time;
    let gale = s.b.y;
    // Which point of the surface sent its ray here: the ray leaves it leaning as the light does, turned by the
    // slope there. Three rounds of guessing find it wherever the rays have not crossed yet.
    let bend = 1.5;
    let lean = s.a.z * 0.75;
    var xs = x - lean * d;
    for (var n = 0; n < 3; n = n + 1) {
        xs = x - d * (lean + bend * surface(xs, t, gale).x);
    }
    let here = surface(xs, t, gale);
    // how far apart neighbouring rays have come: close together is bright
    let spread = abs(1.0 + d * bend * here.y);
    let gather = 1.0 / max(spread, 0.14);
    let caustic = (1.0 - exp(-0.55 * gather)) * exp(-d / 210.0);
    // shafts of every width, fading in and out at their own pace, along the bent ray
    let sh = fbm(vec2<f32>(xs * 0.011, t * 0.07 + d * 0.0012));
    let shaft = pow(clamp((sh - 0.32) * 2.6, 0.0, 1.0), 1.6) * exp(-d / 260.0);
    // the light is strongest under its source and thins out sideways
    let reach = 0.35 + 0.65 * exp(-pow((x - s.a.y) / (s.size.x * 0.5), 2.0));
    let light = clamp(s.a.x * reach * (0.05 * shaft + 0.13 * caustic * (0.45 + 0.55 * sh)) * smoothstep(0.0, 26.0, d), 0.0, 0.3);
    // a thick liquid keeps the red longest
    let sunk = vec3<f32>(exp(-d / 520.0), exp(-d / 230.0), exp(-d / 120.0));
    let tint = mix(s.color.rgb, s.color2.rgb, s.a.w) * sunk;

    // the bed: ripple marks whose crests catch what light there is, in the last 90 px
    let up = s.b.x - d;
    let near = smoothstep(90.0, 0.0, up);
    let crest = x * 0.052 + 2.0 * sin(x * 0.0113 + up * 0.03) - t * 0.05;
    let ridge = pow(0.5 + 0.5 * sin(crest + 0.7 * sin(crest)), 2.0);
    let grain = 0.8 + 0.4 * vnoise(vec2<f32>(x * 0.08, up * 0.2));
    let bed = near * (0.18 + 0.32 * ridge) * grain;
    let sand = mix(vec3<f32>(0.03, 0.015, 0.01), vec3<f32>(0.55, 0.36, 0.2), ridge);
    // the grounds: dark shapes that crawl over the bed and now and then lift off it, stirred more by a wind
    let drift = t * (0.012 + 0.02 * gale);
    let fold = fbm(vec2<f32>(x * 0.0035 - drift, up * 0.011 + drift * 0.6));
    let lump = fbm(vec2<f32>(x * 0.0052 + 3.0 * fold + drift * 0.7, up * 0.016 - 1.7 * fold));
    let grounds = smoothstep(0.50, 0.58, lump) * smoothstep(210.0 + 60.0 * gale, 30.0, up) * 0.62;

    // the light, over the grounds, over the bed
    let under = grounds + bed * (1.0 - grounds);
    let under_rgb = (vec3<f32>(0.035, 0.016, 0.008) * grounds + sand * bed * (1.0 - grounds)) / max(under, 0.001);
    let lit = light * (1.0 - 0.7 * grounds);
    let a = lit + under * (1.0 - lit);
    return vec4<f32>((tint * lit + under_rgb * under * (1.0 - lit)) / max(a, 0.001), a);
}
