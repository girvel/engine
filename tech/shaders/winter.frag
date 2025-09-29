uniform vec3 tint;
uniform float intensity;
uniform float brightness;
uniform float contrast_factor;
uniform vec3 contrast_midpoint;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    vec3 mixed_color = mix(it.rgb, tint, intensity) * brightness;
    mixed_color = mix(contrast_midpoint, mixed_color, contrast_factor);
    return vec4(mixed_color, it.a) * color;
}
