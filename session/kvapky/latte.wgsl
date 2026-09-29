// latte.wgsl — latte art na povrchu kvapky (skupinový shader pleamaru, referencia §8.2).
// inside() vráti, čo kvapka nakreslila (farba + krytie = jej silueta); navrch sa kreslí mliečna pena,
// takže obrazec je len tam, kde je kvapka, a jej tvar ostane. Obrazce sa striedajú: vrstvené srdce →
// rozeta → tulipán → mramor (každých 16 s, prelínanie 3 s); pena sa pomaly vlní a kurzor ju mieša.
// V skupine shader nevidí kurzor ani farby (s.pointer, s.color sú prázdne), preto ide všetko cez čísla:
//   s.a = (stred obrazca x, y, výška kvapky, sila peny 0..1)   súradnice scény
//   s.b = (kurzor x, y, miešanie 0..1, pevný obrazec −1 = striedať / 0..3)

fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

fn fbm(p0: vec2<f32>) -> f32 {
    var p = p0;
    var v = 0.0;
    var a = 0.5;
    for (var i = 0; i < 4; i = i + 1) {
        v = v + a * vnoise(p);
        p = p * 2.03 + vec2<f32>(1.7, 9.2);
        a = a * 0.5;
    }
    return v;
}

fn dot2(v: vec2<f32>) -> f32 {
    return dot(v, v);
}

// srdce (Inigo Quilez), špička dole v (0, 0), hore po y = 1
fn sd_heart(p0: vec2<f32>) -> f32 {
    var p = vec2<f32>(abs(p0.x), p0.y);
    if (p.y + p.x > 1.0) {
        return sqrt(dot2(p - vec2<f32>(0.25, 0.75))) - 0.35355;
    }
    return sqrt(min(dot2(p - vec2<f32>(0.0, 1.0)), dot2(p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}

fn rot(p: vec2<f32>, a: f32) -> vec2<f32> {
    let c = cos(a);
    let s = sin(a);
    return vec2<f32>(c * p.x - s * p.y, s * p.x + c * p.y);
}

// vrstvené srdce: niekoľko vrstiev peny naliatych do seba (ako na fotke)
fn art_heart(q: vec2<f32>) -> f32 {
    let p = vec2<f32>(q.x, 0.55 - q.y) * 1.25;
    let d = sd_heart(p);
    let body = 1.0 - smoothstep(-0.02, 0.02, d);
    let layers = 0.55 + 0.45 * smoothstep(0.15, 0.55, abs(sin(d * 26.0)));
    // čiara naliatia prechádza špičkou dole
    let tail = (1.0 - smoothstep(0.0, 0.035, abs(q.x + 0.02 * sin(q.y * 9.0)))) * step(0.3, q.y) * step(q.y, 0.72);
    return max(body * layers, tail);
}

// rozeta položená pozdĺž kvapky: stonka a oblúky listov, ktoré sa zužujú
fn art_rosetta(q: vec2<f32>) -> f32 {
    let u = (q.x + 1.1) / 2.2;
    if (u < 0.0 || u > 1.0) { return 0.0; }
    let width = 0.62 * (1.0 - u) + 0.1;
    let uu = u + q.y * q.y * 0.9;
    let leaves = smoothstep(0.05, 0.35, 0.5 + 0.5 * sin(uu * 40.0 + 0.4 * sin(q.y * 7.0)));
    let inside_w = 1.0 - smoothstep(width - 0.03, width + 0.02, abs(q.y));
    let stem = (1.0 - smoothstep(0.012, 0.03, abs(q.y))) * step(0.05, u);
    return max(leaves * inside_w, stem);
}

// tulipán: tri polmesiace za sebou a malé srdiečko na konci
fn art_tulip(q: vec2<f32>) -> f32 {
    var m = 0.0;
    for (var k = 0; k < 3; k = k + 1) {
        let fk = f32(k);
        let c = vec2<f32>(-0.75 + fk * 0.5, 0.0);
        let r = 0.46 - fk * 0.09;
        let disk = 1.0 - smoothstep(r - 0.02, r + 0.02, length(q - c));
        let cut = 1.0 - smoothstep(r - 0.04, r, length(q - c - vec2<f32>(0.16, 0.0)));
        if (k < 2) { m = max(m, disk * (1.0 - cut)); } else { m = max(m, disk); }
    }
    let h = art_heart(rot(q - vec2<f32>(0.72, 0.02), 1.5708) * 1.5);
    return max(m, h);
}

// mramor: mlieko vliate a rozťahané (doména deformovaná šumom)
fn art_marble(q: vec2<f32>, t: f32) -> f32 {
    let w = q + 0.7 * vec2<f32>(fbm(q * 1.4 + vec2<f32>(t * 0.05, 0.0)), fbm(q * 1.4 + vec2<f32>(5.2, 1.3) - vec2<f32>(0.0, t * 0.04)));
    // tenké mliečne žilky, nie škvrny
    let bands = 0.5 + 0.5 * sin(w.x * 9.0 + w.y * 3.0 + fbm(w * 2.2) * 9.0);
    return smoothstep(0.86, 0.97, bands) * (1.0 - smoothstep(0.8, 1.3, length(q * vec2<f32>(0.55, 1.0))));
}

fn art(i: i32, q: vec2<f32>, t: f32) -> f32 {
    if (i == 0) { return art_heart(q); }
    if (i == 1) { return art_rosetta(q); }
    if (i == 2) { return art_tulip(q); }
    return art_marble(q, t);
}

// Obsah skupiny prichádza z inside() už v sRGB, no výsledok sa kóduje do sRGB ešte raz
// (pleamar 0.1: aj `return c;` kvapku zosvetlí 28 → 92). Počítame v sRGB a na výstupe späť na lineárne.
fn to_linear(c: vec3<f32>) -> vec3<f32> {
    return pow(max(c, vec3<f32>(0.0)), vec3<f32>(2.2));
}

const FOAM = vec3<f32>(0.953, 0.922, 0.867);
const CREMA = vec3<f32>(0.45, 0.27, 0.15);

fn shade(s: Shader) -> vec4<f32> {
    let c = inside(s, s.pos);
    if (c.a < 0.01) { return vec4<f32>(to_linear(c.rgb), c.a); }
    let t = s.time;
    let p = s.origin + s.pos;                     // bod v súradniciach scény
    let unit = max(s.a.z * 0.62, 1.0);
    var q = (p - s.a.xy) / unit;
    // vlnenie peny a pomalé natáčanie obrazca
    q = q + 0.05 * vec2<f32>(fbm(q * 2.0 + vec2<f32>(t * 0.12, 0.0)) - 0.5, fbm(q * 2.0 + vec2<f32>(3.1, t * 0.1)) - 0.5);
    q = rot(q, 0.08 * sin(t * 0.21));
    // kurzor mieša: vír okolo neho, slabne so vzdialenosťou
    let qp = (s.b.xy - s.a.xy) / unit;
    let stir = exp(-dot2(q - qp) * 2.5) * s.b.z;
    q = qp + rot(q - qp, stir * 1.8);
    // striedanie obrazcov (alebo jeden pevný)
    var m = 0.0;
    if (s.b.w >= 0.0) {
        m = art(i32(s.b.w), q, t);
    } else {
        let cyc = t / 16.0;
        let i0 = i32(floor(cyc)) % 4;
        let i1 = (i0 + 1) % 4;
        let blend = smoothstep(0.81, 1.0, fract(cyc));
        m = mix(art(i0, q, t), art(i1, q, t), blend);
    }
    // crema: jemné svetlejšie škvrnky, pena trochu nerovná
    let speck = smoothstep(0.62, 0.9, fbm(p * 0.09 + vec2<f32>(0.0, t * 0.03)));
    let base = mix(c.rgb, CREMA, speck * 0.28);
    let foam = FOAM * (0.93 + 0.07 * vnoise(p * 0.6));
    let amount = clamp(m, 0.0, 1.0) * s.a.w;
    return vec4<f32>(to_linear(mix(base, foam, amount)), c.a);
}
