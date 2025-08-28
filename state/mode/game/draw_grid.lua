local tcod  = require("engine.tech.tcod")


--- @param self state_mode_game
--- @param dt number
local draw_grid = function(self, dt)
  if State.player.fov_r == 0 then
    self:draw_entity(State.player, dt)
    return
  end

  local snapshot = tcod.snapshot(State.grids.solids)

  for _, grid_layer in ipairs(State.level.grid_layers) do
    local grid = State.grids[grid_layer]
    local sprite_batch = self._sprite_batches[grid_layer]
    if sprite_batch then
      sprite_batch:clear()
    end

    for x = State.perspective.vision_start.x, State.perspective.vision_end.x do
      for y = State.perspective.vision_start.y, State.perspective.vision_end.y do
        if not snapshot:is_visible_unsafe(x, y) then goto continue end

        local e = grid:unsafe_get(x, y)
        if not e then goto continue end

        local is_hidden_by_perspective = (
          not snapshot:is_transparent_unsafe(x, y)
          and e.perspective_flag
          and e.position.y > State.player.position.y
        )
        if is_hidden_by_perspective then goto continue end

        self:draw_entity(e, dt)
        ::continue::
      end
    end

    if sprite_batch then
      love.graphics.draw(sprite_batch)
    end
  end
end

return draw_grid
