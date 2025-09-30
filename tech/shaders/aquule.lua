local aquule = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/aquule.frag"), nil
  )
}

Ldump.mark(aquule, "const", ...)
return aquule
