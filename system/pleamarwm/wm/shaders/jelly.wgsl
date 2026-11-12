// A window as jelly (ROADMAP 1D.27, docs/goo/GOOENGINE-2.md §10.1; the look of Hyprland 0.57's wobble): held by
// the point the hand has it by, the rest of it lags behind the further it is from there, and swings back when
// the hand stops. A group's shader: it reads what the group holds (the title bar and the window) with `inside`.
// The group is `pad` px larger all round than the window, so that what leans out is not cut.
//   a.xy how far the hand is ahead of where the jelly has got to, px · a.zw where the hand has it, 0…1 of the window
//   b.x pad

fn shade(s: Shader) -> vec4<f32> {
    let pad = s.b.x;
    let win = max(s.size - vec2<f32>(2.0 * pad), vec2<f32>(1.0));
    let uv = (s.pos - vec2<f32>(pad)) / win;
    // nothing at the hand, all of it at the far corner; measured in the window's own shape, so a wide one
    // bends along its width
    let away = length((uv - s.a.zw) * vec2<f32>(1.0, win.y / win.x)) / length(vec2<f32>(1.0, win.y / win.x));
    let k = smoothstep(0.0, 1.0, clamp(away * 1.25, 0.0, 1.0));
    let lag = clamp(s.a.xy, vec2<f32>(-pad), vec2<f32>(pad));
    return inside(s, s.pos + lag * k);
}
