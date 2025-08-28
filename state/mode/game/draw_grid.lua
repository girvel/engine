local tcod  = require("engine.tech.tcod")


--- @param self state_mode_game
--- @param dt number
local draw_grid = function(self, dt)
  local start, finish do
    local total_scale = State.perspective.SCALE * State.level.cell_size
    start = -(State.perspective.camera_offset / total_scale):map(math.ceil)
    finish = start + (V(love.graphics.getDimensions()) / total_scale):map(math.ceil)

    start = Vector.use(Math.median, Vector.one, start, State.level.grid_size)
    finish = Vector.use(Math.median, Vector.one, finish, State.level.grid_size)
  end

  local snapshot = tcod.snapshot(State.grids.solids)
  if State.player.fov_r == 0 then
    self:draw_entity(State.player, dt)
    return
  end
  snapshot:refresh_fov(State.player.position, State.player.fov_r)

  for _, grid_layer in ipairs(State.level.grid_layers) do
    local grid = State.grids[grid_layer]
    local sprite_batch = self._sprite_batches[grid_layer]
    if sprite_batch then
      sprite_batch:clear()
    end

    for x = start.x, finish.x do
      for y = start.y, finish.y do
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
