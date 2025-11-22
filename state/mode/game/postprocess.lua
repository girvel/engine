local memory = require("engine.tech.shaders.memory")


--- @param self state_mode_game
--- @param dt number
local postprocess = function(self, dt)
  if State.shader then
    love.graphics.setShader()
  end

  love.graphics.setShader()
  love.graphics.setCanvas(State.player.memory)
  love.graphics.draw(self._main_canvas, unpack(-State.perspective.camera_offset))

  love.graphics.setCanvas()
  love.graphics.setShader(memory.love_shader)
    love.graphics.draw(State.player.memory, unpack(State.perspective.camera_offset))
  love.graphics.setShader()
  love.graphics.draw(self._main_canvas)
end

return postprocess
