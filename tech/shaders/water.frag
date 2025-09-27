uniform vec4 palette[%s];

vec4 match(vec4 color) {
    float min_distance = 1;
    vec4 closest_color;
    for (int i = 0; i < %s; i++) {
        vec4 current_color = palette[i];
        float distance = (
            pow(current_color.r - color.r, 2) +
            pow(current_color.g - color.g, 2) +
            pow(current_color.b - color.b, 2)
        );
  
        if (distance < min_distance) {
            min_distance = distance;
            closest_color = current_color;
        }
    }
    return closest_color;
}

uniform bool reflects;
uniform Image reflection;
uniform vec2 offset;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 reflection_coords = texture_coords;
    reflection_coords.y = 1 - reflection_coords.y;
  
    texture_coords = mod(texture_coords - offset, 1);
    vec4 it = Texel(tex, texture_coords);
    if (!reflects) return it;
    vec4 it2 = Texel(reflection, reflection_coords);
    if (it2.a == 0) return it;
    return match(vec4((it + it2).rgb / 2.5, (it.a + it2.a) / 2));
}
