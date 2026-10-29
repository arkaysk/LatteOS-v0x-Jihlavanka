#version 440
// The coffee at the foot of a window, in three velvet layers: a golden one behind, a caramel one, the coffee in front.
// Each is lit softly from under its edge, a satin band that slides along as the surface tilts towards or away from
// the light, never a hard line; slow waves of their own keep them alive. The swing (Surface.qml) tilts and bows
// them all, the back ones a little less, so they part and meet. Goo's cards draw the same (goo/shaders/velvet.wgsl).
// Built with tests/check.sh into velvet.frag.qsb, which is what Surface.qml loads.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float tilt;                                // px the surface stands higher at the left wall than in the middle
    float bow;                                 // px of the second wave across it, down at the walls
    float bob;                                 // px the whole level has gone down
    float rest;                                // where the front layer rests, px from the top
    float light;                               // how much light
    float lightX;                              // where it is, 0…1 of the width
    vec2 size;
    vec4 lightColor;
    vec4 coffee;
    vec4 back;
};

float hash(vec2 p) {
    vec2 q = fract(p * vec2(0.1031, 0.1030));
    q += dot(q, q.yx + 33.33);
    return fract((q.x + q.y) * q.x);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p), w = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), w.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), w.x), w.y);
}

// where layer k's edge stands at x, and how it slopes there
vec2 edge(float k, float x) {
    float w = size.x, u = x / w, pi = 3.14159265;
    float m = 1.0 - 0.18 * k;
    float swing = m * (-tilt * (1.0 - 2.0 * u) + bow * cos(2.0 * pi * u) + bob);
    float dswing = m * (2.0 * tilt - bow * 2.0 * pi * sin(2.0 * pi * u)) / w;
    float dirn = k == 1.0 ? -1.0 : 1.0;
    float f1 = 6.2831853 * (1.1 + 0.4 * k) / w, f2 = 6.2831853 * (2.7 + 0.9 * k) / w;
    float p1 = f1 * x + dirn * (0.55 + 0.1 * k) * time + 1.7 * k;
    float p2 = f2 * x - dirn * (0.9 + 0.2 * k) * time + 0.6 * k;
    float a1 = 3.2 - 0.6 * k, a2 = 1.3;
    return vec2(rest - 16.0 + 8.0 * k + swing + a1 * sin(p1) + a2 * sin(p2), dswing + a1 * f1 * cos(p1) + a2 * f2 * cos(p2));
}

void main() {
    float x = qt_TexCoord0.x * size.x, y = qt_TexCoord0.y * size.y;
    vec3 lc = lightColor.rgb * light;
    float lx = lightX * size.x;
    float reach = 0.3 + 0.7 * exp(-pow((x - lx) / (size.x * 0.4), 2.0));
    float toward = clamp((lx - x) / 90.0, -1.0, 1.0);
    vec3 tones[3];
    tones[0] = mix(back.rgb * 1.25, vec3(0.93, 0.70, 0.40), 0.35);
    tones[1] = mix(back.rgb, coffee.rgb, 0.55);
    tones[2] = coffee.rgb;

    vec3 rgb = vec3(0.0);
    float a = 0.0;
    float above = edge(0.0, x).x - y;
    if (above > 0.0) {                         // a glow in the air over the back layer
        vec3 g = lc * 0.35 * exp(-above / 7.0) * reach;
        a = clamp(max(g.r, max(g.g, g.b)), 0.0, 1.0);
        rgb = g / max(a, 0.001);
    }
    for (int i = 0; i < 3; i++) {
        float k = float(i);
        vec2 e = edge(k, x);
        float d = y - e.x;
        float cover = smoothstep(-0.8, 0.8, d);
        if (cover <= 0.0) continue;
        float facing = clamp(0.55 - toward * e.y * 4.0, 0.15, 1.0);
        vec3 c = tones[i] * (0.7 + 0.3 * exp(-d / 40.0)) * (0.92 + 0.08 * vnoise(vec2(x * 0.09 + k * 13.0, d * 0.5 - time * 0.2)));
        float rim = exp(-max(d, 0.0) / 1.6);
        float satin = exp(-pow((d - 7.0 - 2.0 * k) / (5.0 + 2.0 * k), 2.0));
        c += mix(lightColor.rgb, vec3(1.0, 0.95, 0.85), 0.4) * rim * 0.95 * reach * facing * light
           + lc * reach * facing * (1.0 - 0.25 * k) * satin * 0.5;
        if (i == 2) {                          // the front layer carries two ribbons of light, wide and soft
            float r1 = d - (24.0 + 7.0 * sin(x * 0.011 + time * 0.3));
            float r2 = d - (38.0 + 9.0 * sin(x * 0.008 - time * 0.21 + 1.7));
            c += lc * (0.22 * exp(-abs(r1) / 2.2) + 0.08 * exp(-abs(r1) / 9.0) + 0.14 * exp(-abs(r2) / 2.6)) * (0.5 + 0.5 * reach);
        }
        rgb = mix(rgb, c, cover);
        a = a + (1.0 - a) * cover;
    }
    fragColor = vec4(rgb * a, a) * qt_Opacity;
}
