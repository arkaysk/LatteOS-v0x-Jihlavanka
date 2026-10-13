// What the coffee does with light and with what settled in it.
//   Light that goes in: shafts from the sun or the moon, bent by the same waves that make the surface (the
//   table below is the one in goo/gen.py: change both), and the net of bright lines near the surface.
//   The bed: ripple marks in the sand on the bottom, drifting slowly the way the waves go.
//   a.x how much light there is (0 when none), a.y where it is, in x, a.z how far the shafts lean per px of
//   depth, a.w 0 sun · 1 moon;  b.x how far the bottom of the screen is below this box's top.
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

fn shade(s: Shader) -> vec4<f32> {
    let x = s.pos.x;
    let d = s.pos.y;
    let t = s.time;
    let tau = 6.2831853;
    // the surface above this x: its slope bends the light, a convex crest gathers it
    var slope = 0.0;
    var bulge = 0.0;
    let wl = array<f32, 4>(820.0, 430.0, 250.0, 150.0);
    let am = array<f32, 4>(7.0, 4.2, 2.6, 1.5);
    let om = array<f32, 4>(22.0, 31.0, 44.0, 63.0);
    let ph = array<f32, 4>(0.0, 70.0, 200.0, 310.0);
    for (var j = 0; j < 4; j = j + 1) {
        let k = tau / wl[j];
        let th = k * x - radians(om[j]) * t + radians(ph[j]);
        slope = slope + am[j] * k * sin(th);
        bulge = bulge + am[j] * k * k * cos(th);
    }
    let u = x - s.a.z * d + slope * min(d, 220.0) * 1.2;
    // shafts of every width, fading in and out at their own pace: noise along the ray, not a regular wave
    let sh = fbm(vec2<f32>(u * 0.011, t * 0.07 + d * 0.0012));
    let shaft = pow(clamp((sh - 0.32) * 2.6, 0.0, 1.0), 1.6);
    // the light is strongest under its source and thins out sideways
    let reach = exp(-pow((x - s.a.y) / (s.size.x * 0.5), 2.0));
    let focus = clamp(1.0 + 150.0 * bulge, 0.5, 2.0);
    let beams = shaft * exp(-d / 240.0) * (0.35 + 0.65 * reach) * focus;
    // caustics: two crossing nets that drift against each other, only near the surface
    let warp = 5.0 * (fbm(vec2<f32>(u * 0.009 + t * 0.05, d * 0.03 - t * 0.2)) - 0.5);
    let c1 = abs(sin(u * 0.045 + warp + 1.6 * sin(d * 0.06 + t * 0.9)));
    let c2 = abs(sin(u * 0.031 - 1.4 * warp - 2.0 * sin(d * 0.05 - t * 0.7) + d * 0.02));
    let clear_water = smoothstep(0.25, 0.7, fbm(vec2<f32>(u * 0.006, d * 0.02 + t * 0.03)));
    let net = pow(c1 * c2, 5.0) * exp(-d / 60.0) * focus * clear_water;
    let light = clamp(s.a.x * (0.15 * beams + 0.3 * net) * smoothstep(0.0, 28.0, d), 0.0, 0.5);

    // the bed: asymmetric ripple marks, steeper on the side the waves come from, in the last 70 px
    let up = s.b.x - d;
    let near = smoothstep(70.0, 0.0, up);
    let crest = x * 0.052 + 2.0 * sin(x * 0.0113 + up * 0.03) - t * 0.05;
    let ridge = pow(0.5 + 0.5 * sin(crest + 0.7 * sin(crest)), 2.0);
    let bed = near * (0.12 + 0.2 * ridge) * 0.9;

    let a = light + bed * (1.0 - light);
    let tint = mix(s.color.rgb, s.color2.rgb, s.a.w);
    let rgb = (tint * light + vec3<f32>(0.05, 0.025, 0.015) * bed * (1.0 - light)) / max(a, 0.001);
    return vec4<f32>(rgb, a);
}
