shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_radius   : hint_range(0.0, 1.0) = 0.75;
uniform float softness          : hint_range(0.0, 1.0) = 0.45;

void fragment() {
    vec2 center = vec2(0.5, 0.35);
    float dist = length(UV - center) * 1.4;
    float vignette = smoothstep(vignette_radius, vignette_radius + softness, dist);
    COLOR = vec4(0.0, 0.0, 0.0, vignette * vignette_strength);
}
