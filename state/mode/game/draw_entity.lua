--- @param self state_mode_game
--- @param entity table
--- @param dt number
local draw_entity = function(self, entity, dt)
  local current_view = State.perspective.views[entity.view]
  local offset_position = entity.position
  if entity.layer then
    offset_position = offset_position * State.level.cell_size
  end
  offset_position = current_view:apply(offset_position)
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
  -- NEXT inventory
  -- NEXT text?

  local sprite = entity.sprite
  if sprite.type == "image" or (sprite.type == "atlas" and entity.shader) then
    love.graphics.draw(entity.sprite.image, x, y, 0, current_view.scale)
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.layer]:add(sprite.quad, x, y, 0, current_view.scale)
  end

  if entity.shader then
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw(self._temp_canvas)
  end
end

return draw_entity
