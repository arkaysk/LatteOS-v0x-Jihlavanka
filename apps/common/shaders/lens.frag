#version 440
// A magnifying glass with no frame and no handle: only the glass, thicker in the middle, so that what is seen through
// it is bigger towards the centre and drawn in at the rim, where the colours part a little. A soft light from the top
// left, the rim catching it. Outside the circle nothing. Built with tests/check.sh into lens.frag.qsb (Lens.qml).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float zoom;                                // how much bigger the middle is
    float light;                               // how bright its highlight and rim, 0 to 1
    float turn;                                // where the light comes from, turned this much (radians): it drifts
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 p = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(p);
    float aa = fwidth(r) * 1.5;
    float inside = 1.0 - smoothstep(1.0 - aa, 1.0, r);
    if (inside <= 0.0) { fragColor = vec4(0.0); return; }
    float h = sqrt(max(0.0, 1.0 - r * r));     // the dome's height over this point
    vec2 q = p * mix(1.0, 1.0 / zoom, h);      // bigger where the glass is thick
    vec2 dir = r > 0.0001 ? p / r : vec2(0.0);
    float part = 0.014 * pow(r, 4.0);          // red and blue bent apart near the rim
    vec3 c = vec3(texture(source, (q + dir * part) * 0.5 + 0.5).r,
                  texture(source, q * 0.5 + 0.5).g,
                  texture(source, (q - dir * part) * 0.5 + 0.5).b);
    vec2 from = normalize(vec2(-0.6, -0.8));
    from = vec2(from.x * cos(turn) - from.y * sin(turn), from.x * sin(turn) + from.y * cos(turn));
    float facing = max(0.0, dot(dir, from));
    float spec = pow(max(0.0, dot(normalize(vec3(p, h + 0.0001)), normalize(vec3(from * 0.55, 1.0)))), 38.0);
    float rim = smoothstep(0.84, 1.0, r);
    c += vec3(spec * 0.5 * light);
    c += vec3(rim * (0.12 + 0.38 * facing) * light);
    c *= 1.0 - rim * 0.28 * (1.0 - facing);
    fragColor = vec4(c, 1.0) * inside * qt_Opacity;
}
