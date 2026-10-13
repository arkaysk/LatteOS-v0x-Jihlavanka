// Light that goes into the coffee: shafts from the sun or the moon, slanted as the light comes, and the
// net of bright lines near the surface where the waves gather it. It paints below the surface only.
//   a.x how much of it there is (0 when no light, e.g. the sun is down), a.y where the light is, in x,
//   a.z how far the shafts lean per px of depth, a.w 0 sun · 1 moon;  color the sun's, color2 the moon's.
fn shade(s: Shader) -> vec4<f32> {
    let x = s.pos.x;
    let d = s.pos.y;
    let t = s.time;
    // the surface moves, so the light does: a slow sway of where each shaft starts
    let sway = 9.0 * sin(x * 0.006 + t * 0.45) + 5.0 * sin(x * 0.017 - t * 0.8);
    let u = x - s.a.z * d + sway * clamp(d / 160.0, 0.0, 1.0);
    let n1 = sin(u * 0.030 + 1.3 * sin(u * 0.0071 + t * 0.35) + t * 0.2);
    let n2 = sin(u * 0.071 - t * 0.27 + 2.0 * sin(u * 0.0137));
    let shaft = pow(clamp(0.5 + 0.5 * (n1 * 0.65 + n2 * 0.35), 0.0, 1.0), 3.0);
    // the light is strongest under its source and thins out sideways
    let reach = exp(-pow((x - s.a.y) / (s.size.x * 0.5), 2.0));
    let beams = shaft * exp(-d / 240.0) * (0.35 + 0.65 * reach);
    // caustics: two crossing nets that drift against each other, only near the surface
    let c1 = abs(sin(x * 0.045 + 1.6 * sin(d * 0.06 + t * 0.9)));
    let c2 = abs(sin(x * 0.031 - 2.0 * sin(d * 0.05 - t * 0.7) + d * 0.02));
    let net = pow(c1 * c2, 5.0) * exp(-d / 60.0);
    let a = s.a.x * (0.15 * beams + 0.3 * net) * smoothstep(0.0, 28.0, d);
    return vec4<f32>(mix(s.color.rgb, s.color2.rgb, s.a.w), clamp(a, 0.0, 0.5));
}
