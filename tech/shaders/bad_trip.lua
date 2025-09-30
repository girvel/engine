-- TODO non-singleton

local bad_trip = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/bad_trip.frag"), nil
  ),

  update = function(self)
    self.love_shader:send("time", love.timer.getTime())
    self.love_shader:send("sidebar_w", State.perspective.sidebar_w)
  end,
}

Ldump.mark(bad_trip, "const", ...)
return bad_trip
