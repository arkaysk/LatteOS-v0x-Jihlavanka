#version 440
// One picture gives way to the next along a living edge, as coffee does: `kind` 0 it rises from below,
// 1 it spreads from a drop, 2 it is swept in from the right. A line of crema runs along the edge.
// Built with tests/check.sh into reveal.frag.qsb, which is what Reveal.qml loads.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float kind;
    float ratio;                               // width over height, so that a circle is one
};
layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;

void main() {
    vec2 uv = qt_TexCoord0;
    float p = progress;
    float edge;                                // above zero where the next picture already is
    if (kind < 0.5) {
        float wave = 0.035 * sin(uv.x * 9.0 + p * 7.0) + 0.018 * sin(uv.x * 23.0 - p * 11.0);
        edge = uv.y + wave - (1.1 - p * 1.2);
    } else if (kind < 1.5) {
        vec2 d = (uv - vec2(0.07, 0.86)) * vec2(ratio, 1.0);
        float wave = 0.025 * sin(atan(d.y, d.x) * 7.0 + p * 9.0);
        edge = p * (length(vec2(ratio, 1.0)) + 0.1) - length(d) + wave;
    } else {
        float wave = 0.03 * sin(uv.y * 8.0 + p * 6.0) + 0.012 * sin(uv.y * 21.0 - p * 9.0);
        edge = uv.x + uv.y * 0.12 + wave - (1.15 - p * 1.35);
    }
    float there = smoothstep(-0.008, 0.008, edge);
    float moving = step(0.001, p) * step(p, 0.999);
    float rim = smoothstep(0.05, 0.0, abs(edge)) * moving;
    // just behind the edge the next picture is still bent, as through the liquid's lip
    vec2 bent = uv + vec2(0.0, 0.02) * smoothstep(0.12, 0.0, edge) * moving;
    vec4 c = mix(texture(from, uv), texture(to, bent), there);
    c.rgb += vec3(0.97, 0.78, 0.45) * rim * 0.3 * c.a;
    fragColor = c * qt_Opacity;
}
