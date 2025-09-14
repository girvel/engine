local tk = require("engine.state.mode.tk")


--- @param self state_mode_game
--- @param entity table
--- @param dt number
local draw_entity = function(self, entity, dt)
  if entity.sprite.type == "grid" then
    return self:draw_grid(entity.layer, entity.sprite.grid, dt)
  end

  local x, y = unpack(entity.position)
  local dx, dy = unpack(State.perspective.camera_offset)
  local k = State.perspective.SCALE * State.level.cell_size
  x = dx + x * k
  y = dy + y * k

  if entity.shader then
    love.graphics.setShader(entity.shader.love_shader)
    love.graphics.setCanvas(self._temp_canvas)
    love.graphics.clear()
    if entity.shader.preprocess then
      entity.shader:preprocess(entity, dt)
    end
  end

  -- TODO global shader

  local sprite = entity.sprite
  if sprite.type == "image" or (sprite.type == "atlas" and entity.shader) then
    tk.draw_entity(entity, x, y, State.perspective.SCALE)
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.grid_layer]:add(sprite.quad, x, y, 0, State.perspective.SCALE)
  elseif sprite.type == "text" then
    love.graphics.setFont(sprite.font)
    love.graphics.print({sprite.color:pack(), sprite.text}, x, y)
  else
    assert(false)
  end

  if entity.shader then
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw(self._temp_canvas)
  end
end

Ldump.mark(draw_entity, {}, ...)
return draw_entity
