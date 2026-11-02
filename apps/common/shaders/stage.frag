#version 440
// The stage a thing stands on, as dioramas (github.com/blendi-remade/dioramas, MIT) light theirs: a warm cone of light
// from above onto `spot`, a glow round it, the edges going dark, and a fine grain that moves. What is under it shows
// where it is clear. Built with tests/check.sh into stage.frag.qsb.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 spot;                                // where the light falls, 0…1 of the stage
    float ratio;                               // width over height
    float time;                                // seconds; the grain moves with it
    vec4 warm;                                 // the light's colour
    vec2 ground;                               // where the thing's soft shadow lies, 0…1
    vec2 groundSize;                           // and how wide and tall it is, 0…1
};

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 a = vec2(ratio, 1.0);
    float d = length((uv - spot) * a);
    float glow = exp(-d * d * 9.0);
    // the cone: from a point above the top, widening down to the spot and fading past it
    vec2 top = vec2(spot.x, -0.35);
    float down = clamp((uv.y - top.y) / (spot.y - top.y), 0.0, 1.6);
    float across = abs(uv.x - spot.x) * ratio / max(0.05, down * 0.32);
    float beam = (1.0 - smoothstep(0.55, 1.0, across)) * smoothstep(0.0, 0.35, down) * (1.0 - smoothstep(1.0, 1.6, down));
    float shine = glow * 0.42 + beam * 0.13;
    float dark = smoothstep(0.35, 1.25, length((uv - 0.5) * a));
    float grain = (hash(floor(uv * 900.0) + floor(time * 24.0)) - 0.5) * 0.035;
    vec3 light = warm.rgb * shine + vec3(grain);
    vec2 g = (uv - ground) / max(groundSize, vec2(0.001));
    float shadow = exp(-dot(g, g) * 2.2) * 0.55;
    // the dark and the shadow are the black part of what is laid over: alpha without colour
    float alpha = clamp(shine + dark * 0.55 + shadow + abs(grain), 0.0, 1.0);
    fragColor = vec4(light * (1.0 - shadow), alpha) * qt_Opacity;
}
