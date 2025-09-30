local bad_trip = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/bad_trip.frag"), nil
  )
}

Ldump.mark(bad_trip, "const", ...)
return bad_trip
