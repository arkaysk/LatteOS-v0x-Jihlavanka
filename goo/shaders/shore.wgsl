// The light of the sun or the moon on the desktop's goo, as on the login screen's coffee (crest.wgsl), but along
// whatever the surface is right now: a group's shader over the goo's silhouette, which it reads with `inside`.
// A hair of light on the top edge, a glow that spills a little into the air above it and further down into the
// coffee, a band of crema just under the surface, and the flanks of the drops that face the light. Strongest
// on the side the light stands on, fading across the screen. Drawn with `mode: add`: light added, never paint.
//   a.x how much light · a.y where it stands (x, px) · a.z the scene's clock, for the glints (they rest with it)
//   a.w 0 sun, 1 moon · b.x 0…1 how low and warm the sun is

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
fn goo(s: Shader, at: vec2<f32>) -> f32 {
    return inside(s, at).a;
}

fn shade(s: Shader) -> vec4<f32> {
    let p = s.pos;
    let here = goo(s, p) > 0.5;
    // how far under the surface this point is (d > 0), or how far above it (d < 0): the first step that crosses
    // it going up or down, then halved four times
    var near = 0.0;
    var far = 0.0;
    var found = false;
    let dir = select(1.0, -1.0, here);
    let reach = select(10.0, 48.0, here);
    for (var step = 2.0; step <= reach; step = step * 2.0) {
        if ((goo(s, p + vec2<f32>(0.0, dir * step)) > 0.5) != here) {
            far = step;
            found = true;
            break;
        }
        near = step;
    }
    if (!found) {
        return vec4<f32>(0.0);
    }
    for (var n = 0; n < 4; n = n + 1) {
        let mid = 0.5 * (near + far);
        if ((goo(s, p + vec2<f32>(0.0, dir * mid)) > 0.5) != here) { far = mid; } else { near = mid; }
    }
    let d = select(-far, far, here);

    // strongest under the light, never quite gone at the far side; glints run along it
    let fade = 0.12 + 0.88 * exp(-pow((p.x - s.a.y) / (s.size.x * 0.3), 2.0));
    let glint = 0.65 + 0.35 * vnoise(vec2<f32>(p.x * 0.03 - s.a.z * 0.6, s.a.z * 0.2));
    // the hair sits on the surface, the glow spills up into the air and further down
    let hair = exp(-abs(d - 1.0) / 1.1) * glint;
    let glow = exp(-abs(d - 1.0) / select(6.0, 20.0, d > 0.0)) * (0.6 + 0.4 * glint);
    // crema: a warm band just under the surface, thinning with depth
    let crema = smoothstep(0.0, 4.0, d) * exp(-d / 22.0);
    // a flank that faces the light: goo here, air a few px towards it
    let side = sign(s.a.y - p.x);
    let flank = select(0.0, 1.0 - goo(s, p + vec2<f32>(side * 4.0, 0.0)), here) * exp(-d / 60.0);

    let sun = mix(mix(vec3<f32>(1.0, 0.93, 0.8), vec3<f32>(1.0, 0.62, 0.3), s.b.x), vec3<f32>(0.78, 0.85, 1.0), s.a.w);
    let white = mix(sun, vec3<f32>(1.0, 0.97, 0.9), 0.45);       // the hottest light is nearly white
    let deep = sun * mix(vec3<f32>(0.9, 0.52, 0.16), vec3<f32>(0.5, 0.6, 0.9), s.a.w);   // what the coffee leaves of it
    let rgb = white * hair * 1.2 + sun * glow * 0.55 + deep * crema * 0.5 + white * flank * 0.7;
    // in `mode: add` only colour times coverage counts: hand the light over as its brightest channel
    let c = rgb * s.a.x * fade;
    let a = clamp(max(c.r, max(c.g, c.b)), 0.0, 1.0);
    return vec4<f32>(c / max(a, 0.001), a);
}
