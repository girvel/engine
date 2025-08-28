local tk = require("engine.state.mode.tk")


--- @param self state_mode_game
--- @param entity table
--- @param dt number
local draw_entity = function(self, entity, dt)
  local offset_position = entity.position
  if entity.grid_layer then
    offset_position = offset_position * State.level.cell_size
  end
  offset_position = State.perspective.camera_offset
    + entity.position * State.perspective.SCALE * State.level.cell_size
  local x, y = unpack(offset_position)

  if entity.shader then
    love.graphics.setShader(entity.shader.love_shader)
    love.graphics.setCanvas(self._temp_canvas)
    love.graphics.clear()
    if entity.shader.preprocess then
      entity.shader:preprocess(entity, dt)
    end
  end

  -- NEXT global shader

  local sprite = entity.sprite
  if sprite.type == "image" or (sprite.type == "atlas" and entity.shader) then
    tk.draw_entity(entity, x, y, State.perspective.SCALE)
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.grid_layer]:add(sprite.quad, x, y, 0, State.perspective.SCALE)
  elseif sprite.type == "text" then
    love.graphics.setFont(sprite.font)
    love.graphics.print({sprite.color, sprite.text}, x, y)
  else
    error()
  end

  if entity.shader then
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw(self._temp_canvas)
  end
end

return draw_entity
