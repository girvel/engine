uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float scalar_offset = time;
    vec2 offset = vec2(cos(scalar_offset), sin(scalar_offset));
    texture_coords = mod(texture_coords + offset, 1);
    vec4 it = Texel(tex, texture_coords);
    vec3 mixed_color = mix(vec3(.5), it.rgb, 4);
    return vec4(mixed_color, it.a) * color;
}
