// A pegboard where a widget can go and none is yet: a faint board of glass with rows of holes, each a dark dot lit on
// its lower edge, so that it reads as drilled. Nothing moves, nothing is painted over what is behind but the board.
//   color the board's light, color2 the holes' dark.

const PITCH: f32 = 16.0;
const HOLE: f32 = 2.6;
const CORNER: f32 = 14.0;

fn shade(s: Shader) -> vec4<f32> {
    let half_size = s.size * 0.5;
    let q = abs(s.pos - half_size) - (half_size - vec2<f32>(CORNER));
    let edge = length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - CORNER;
    let inside = clamp(0.5 - edge, 0.0, 1.0);
    if (inside <= 0.0) { return vec4<f32>(0.0); }
    // whole holes only, the grid centred on the board, none at its border
    let at = (s.pos - half_size) / PITCH;
    let cell = (at - round(at)) * PITCH;
    let keep = abs(round(at)) * PITCH + vec2<f32>(PITCH * 0.75);
    let whole = step(keep.x, half_size.x) * step(keep.y, half_size.y);
    let d = length(cell) - HOLE;
    let hole = clamp(0.5 - d, 0.0, 1.0) * whole;
    let lit = clamp(0.5 - abs(length(cell - vec2<f32>(0.0, 0.8)) - HOLE), 0.0, 1.0) * step(0.0, cell.y) * whole * (1.0 - hole);
    let rim = clamp(1.0 - abs(edge + 0.5), 0.0, 1.0);
    let light = max(0.05, max(0.14 * rim, 0.22 * lit));
    let a = 1.0 - (1.0 - light) * (1.0 - 0.42 * hole);
    let colour = mix(s.color.rgb, s.color2.rgb, (0.42 * hole) / max(a, 0.001));
    return vec4<f32>(colour, a * inside);
}
