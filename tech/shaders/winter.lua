--- @param tint vector 3-dimensional
--- @param intensity number
--- @param brightness number
--- @param contrast_midpoint number
--- @param contrast_factor number
local build_love_shader = function(tint, intensity, brightness, contrast_midpoint, contrast_factor)
  assert(#tint == 3)

  local result = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/winter.frag"), nil
  )
  result:send("tint", tint)
  result:send("intensity", intensity)
  result:send("brightness", brightness)
  result:send("contrast_midpoint", contrast_midpoint)
  result:send("contrast_factor", contrast_factor)
  return result
end

--- @type shader
local winter = {
  love_shader = build_love_shader(
    Vector.hex("3e4957"):swizzle("rgb"),
    .6, 1.2,
    V(.5, .5, .5), 1.5
  ),
}

Ldump.mark(winter, "const", ...)
return winter

