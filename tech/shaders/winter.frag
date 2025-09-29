uniform vec3 tint;
uniform float intensity;
uniform float darkness_factor;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    vec3 mixed_color = mix(it.rgb, tint, intensity) * darkness_factor;
    return vec4(mixed_color * color, it.a);
}
