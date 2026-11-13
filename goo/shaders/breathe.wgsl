// Goo alive at rest (the user, 13. 11.: "the sea does not stop when nobody is looking"), worked out by the graphics card:
// the group's picture —the goo and its outline— is bent a little by slow waves, so the drops breathe and the level
// swells without the scene changing a single number: the processor only has the frames to hand over. The same field on every group that uses
// it, so the fill and the one outline move together.
//   a.x, a.y, a.z, a.w the open card's box (x, y, w, h; w 0 when there is none) · b.x, b.y the pointer
//   b.z LensShore's plate on the bottom edge, from × 4096 + to (px, 0 none) · b.w where TrayShore's plate begins
// Nothing bends at the open card (its frame does not), at the plates (they are hard) nor under the cursor (its tip
// is never late). ponytail: LensShore on the top edge is not left out; when it lives there, it bends with the goo.
const BREATH: f32 = 2.6;      // how far, px

fn field(p: vec2<f32>, t: f32) -> vec2<f32> {
    let dx = 0.6 * sin(p.y * 0.045 + t * 0.9) + 0.4 * sin((p.x + p.y) * 0.021 - t * 0.7);
    let dy = 0.6 * sin(p.x * 0.031 - t * 1.05) + 0.4 * sin((p.x - p.y) * 0.027 + t * 0.8);
    return vec2<f32>(dx, dy);
}

// 0 inside the box grown by `near`, 1 from `far` past it
fn clear_of(p: vec2<f32>, lo: vec2<f32>, hi: vec2<f32>, near: f32, far: f32) -> f32 {
    let out = max(max(lo - p, p - hi), vec2<f32>(0.0));
    return smoothstep(near, far, length(out));
}

fn shade(s: Shader) -> vec4<f32> {
    let p = s.pos;
    let h = s.size.y;
    var amp = BREATH;
    if (s.a.z > 0.5) {
        amp *= clear_of(p, s.a.xy, s.a.xy + s.a.zw, 10.0, 60.0);
    }
    let la = floor(s.b.z / 4096.0);
    let lb = s.b.z - la * 4096.0;
    if (lb > la + 0.5) {
        amp *= clear_of(p, vec2<f32>(la, h - 46.0), vec2<f32>(lb, h), 4.0, 30.0);
    }
    if (s.b.w < s.size.x - 0.5) {
        amp *= clear_of(p, vec2<f32>(s.b.w, h - 46.0), vec2<f32>(s.size.x, h), 4.0, 30.0);
    }
    amp *= smoothstep(14.0, 48.0, distance(p, s.b.xy));
    // the bottom edge: nothing comes in from below the screen
    amp *= clamp((h - p.y) / 6.0, 0.0, 1.0);
    return inside(s, p + amp * field(p, s.time));
}
