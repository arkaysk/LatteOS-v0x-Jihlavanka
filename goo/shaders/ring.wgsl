// A press of the mouse: the ring of light pleamar sends through glass that is pressed (`ripple:`, its shape.wgsl:
// BSD-3, k4ditano), the same sums, for where there is no glass to carry it: the desktop, a drop, a solid window.
// It spreads to 150 px in 0.9 s, fast at first, and fades as it goes; inside it a faint fill.
//   a.x 0…1 how far it has run; it was pressed in the middle of the box
fn shade(s: Shader) -> vec4<f32> {
    let progress = clamp(s.a.x, 0.0, 1.0);
    let dist = distance(s.uv * s.size, s.size * 0.5);
    let reach = 150.0 * (1.0 - pow(1.0 - progress, 3.0));
    let fade = pow(1.0 - progress, 2.0);
    let ring = exp(-pow((dist - reach) / 16.0, 2.0));
    let fill = exp(-pow(dist / (reach * 0.6 + 1.0), 2.0)) * 0.5;
    return vec4<f32>(1.0, 1.0, 1.0, (ring + fill) * fade * 0.3);
}
