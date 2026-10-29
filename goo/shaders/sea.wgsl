// "Seascape" by Alexander Alekseev aka TDM - 2014: https://www.shadertoy.com/view/Ms2SD1
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. This file keeps that licence
// (TRETIE-STRANY.md); the rest of LatteOS is MIT.
//
// Changed for LatteOS: the sea is coffee, seen from just above it by a camera that looks straight at the horizon,
// so the horizon is a level line PAD px under this box's top. The light is the sun or the moon where it stands on the
// login screen, and it lays a path of glints across the coffee towards whoever looks; the sky the coffee mirrors is
// the dark room with a glow round that light, which also rises a little above the horizon.
//   a.x how much light, a.y the light's x, a.z how far above the horizon it stands (px), a.w how rough (chop, 1…);
//   b.x 0 sun · 1 moon.  color the sun's, color2 the coffee's (the user's own drink): the sea is made of it.

const NUM_STEPS: i32 = 8;
const PI: f32 = 3.141592;
const ITER_GEOMETRY: i32 = 3;
const ITER_FRAGMENT: i32 = 4;                                 // a thick liquid: no ripples finer than these
const SEA_HEIGHT: f32 = 0.6;
const SEA_CHOPPY: f32 = 3.2;                                   // coffee is thick: rounder crests than the sea's 4
const SEA_SPEED: f32 = 0.45;                                   // and slower
const SEA_FREQ: f32 = 0.11;                                   // longer waves than the sea's 0.16
const MOON = vec3<f32>(0.81, 0.85, 1.0);
const ROOM = vec3<f32>(0.102, 0.078, 0.063);                   // espresso, the screen behind (parts/greet.plm)
const PAD: f32 = 60.0;                                          // px of sky above the horizon in this box
const FOCAL: f32 = 640.0;                                       // px: how wide the camera sees
const EYE: f32 = 2.4;                                           // how high it stands above the coffee

fn hash(p: vec2<f32>) -> f32 {
    let h = dot(p, vec2<f32>(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}
fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * mix(mix(hash(i + vec2<f32>(0.0, 0.0)), hash(i + vec2<f32>(1.0, 0.0)), u.x),
                            mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

fn diffuse(n: vec3<f32>, l: vec3<f32>, p: f32) -> f32 {
    return pow(dot(n, l) * 0.4 + 0.6, p);
}
fn specular(n: vec3<f32>, l: vec3<f32>, e: vec3<f32>, s: f32) -> f32 {
    let nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

// the room: dark, with a glow round the light and a brighter band along the horizon under it
fn sky(e0: vec3<f32>, l: vec3<f32>, lc: vec3<f32>) -> vec3<f32> {
    let e = vec3<f32>(e0.x, max(e0.y, 0.0), e0.z);
    let toward = max(dot(normalize(e), l), 0.0);
    let haze = pow(1.0 - e.y, 12.0) * (0.25 + 0.75 * pow(toward, 4.0));
    return ROOM + lc * (0.35 * pow(toward, 10.0) + 2.5 * pow(toward, 900.0) + 0.22 * haze);
}

fn sea_octave(uv0: vec2<f32>, choppy: f32) -> f32 {
    let uv = uv0 + noise(uv0);
    var wv = 1.0 - abs(sin(uv));
    let swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

fn sea(p: vec3<f32>, st: f32, height: f32, iters: i32) -> f32 {
    let octave_m = mat2x2<f32>(vec2<f32>(1.6, 1.2), vec2<f32>(-1.2, 1.6));
    var freq = SEA_FREQ;
    var amp = height;
    var choppy = SEA_CHOPPY;
    var uv = p.xz;
    uv.x = uv.x * 0.75;
    var h = 0.0;
    for (var i = 0; i < iters; i = i + 1) {
        var d = sea_octave((uv + st) * freq, choppy);
        d = d + sea_octave((uv - st) * freq, choppy);
        h = h + d * amp;
        uv = uv * octave_m;
        freq = freq * 1.9;
        amp = amp * 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

// the coffee: in its depth the drink darkened, through a crest the light comes out as crema
fn sea_color(p: vec3<f32>, n: vec3<f32>, l: vec3<f32>, lc: vec3<f32>, eye: vec3<f32>, dist: vec3<f32>, height: f32, coffee: vec3<f32>) -> vec3<f32> {
    let base = coffee * 0.2;
    let crema = mix(coffee * 2.2, vec3<f32>(0.85, 0.6, 0.35), 0.5);
    var fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
    fresnel = pow(fresnel, 3.0) * 0.65;
    let reflected = sky(reflect(eye, n), l, lc);
    let refracted = base + diffuse(n, l, 80.0) * crema * lc * 0.12;
    var color = mix(refracted, reflected, fresnel);
    let atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);
    color = color + crema * (p.y - height) * 0.18 * atten * (0.4 + 0.6 * length(lc));
    color = color + lc * specular(n, l, eye, 60.0);
    return color;
}

fn normal(p: vec3<f32>, eps: f32, st: f32, height: f32) -> vec3<f32> {
    let y = sea(p, st, height, ITER_FRAGMENT);
    let nx = sea(vec3<f32>(p.x + eps, p.y, p.z), st, height, ITER_FRAGMENT) - y;
    let nz = sea(vec3<f32>(p.x, p.y, p.z + eps), st, height, ITER_FRAGMENT) - y;
    return normalize(vec3<f32>(nx, eps, nz));
}

fn trace(ori: vec3<f32>, dir: vec3<f32>, st: f32, height: f32) -> vec3<f32> {
    var tm = 0.0;
    var tx = 1000.0;
    var hx = sea(ori + dir * tx, st, height, ITER_GEOMETRY);
    if (hx > 0.0) { return ori + dir * tx; }
    var hm = sea(ori + dir * tm, st, height, ITER_GEOMETRY);
    var p = ori;
    for (var i = 0; i < NUM_STEPS; i = i + 1) {
        let tmid = mix(tm, tx, hm / (hm - hx));
        p = ori + dir * tmid;
        let hmid = sea(p, st, height, ITER_GEOMETRY);
        if (hmid < 0.0) { tx = tmid; hx = hmid; } else { tm = tmid; hm = hmid; }
    }
    return p;
}

fn shade(s: Shader) -> vec4<f32> {
    let v = s.pos.y - PAD;                                       // px below the horizon
    let dir = normalize(vec3<f32>((s.pos.x - s.size.x * 0.5) / FOCAL, -v / FOCAL, 1.0));
    let l = normalize(vec3<f32>((s.a.y - s.size.x * 0.5) / FOCAL, s.a.z / FOCAL, 1.0));
    let lc = mix(s.color.rgb, MOON, s.b.x) * s.a.x;
    let st = 1.0 + s.time * SEA_SPEED;
    let height = SEA_HEIGHT * (0.55 + 0.45 * s.a.w);

    // above the horizon only the glow: light added to the room, fading upwards
    if (v < 0.0) {
        let c = (sky(dir, l, lc) - ROOM) * smoothstep(-PAD, 0.0, v);
        let a = clamp(max(c.r, max(c.g, c.b)), 0.0, 1.0);
        return vec4<f32>(c / max(a, 0.001), a);
    }
    let ori = vec3<f32>(0.0, EYE, 0.0);
    let p = trace(ori, dir, st, height);
    let dist = p - ori;
    let n = normal(p, dot(dist, dist) * (0.3 / s.size.x), st, height);
    let color = mix(sky(dir, l, lc), sea_color(p, n, l, lc, dir, dist, height, s.color2.rgb), pow(smoothstep(0.0, -0.05, dir.y), 0.3));
    return vec4<f32>(color, smoothstep(0.0, 1.5, v + 0.75));
}
