--- @param tint vector 3-dimensional
--- @param intensity number
--- @param darkness_factor number
local build_love_shader = function(tint, intensity, darkness_factor)
  assert(#tint == 3)

  local result = love.graphics.newShader [[
    uniform vec3 tint;
    uniform float intensity;
    uniform float darkness_factor;
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
      vec4 it = Texel(tex, texture_coords);
      vec3 mixed_color = mix(it.rgb, tint, intensity) * darkness_factor;
      return vec4(mixed_color, it.a);
    }
  ]]
  result:send("tint", tint)
  result:send("intensity", intensity)
  result:send("darkness_factor", darkness_factor)
  return result
end

--- @type shader
local winter = {
  love_shader = build_love_shader(Vector.hex("3e4957"):swizzle("rgb"), .5, .8),
}

Ldump.mark(winter, "const", ...)
return winter

