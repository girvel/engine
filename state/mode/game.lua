local ui = require("engine.tech.ui")

local game = {}

--- @class state_mode_game
local methods = {}
local mt = {__index = methods}

game.new = function()
  return setmetatable({
    
  }, mt)
end

methods.draw_gui = function()
  ui.text("<game>")
end

methods.draw_entity = function(self, entity)
  love.graphics.draw(entity.sprite.image, unpack(entity.position))
end

methods.draw_grid = function(self)
  local start = Vector.one
  local finish = State.grid_size
  -- TODO mask
  -- TODO background

  for _, layer in ipairs(State.level.grid_layers) do
    local grid = State.grids[layer]
    for x = start.x, finish.x do
      for y = start.y, finish.y do
        -- TODO mask apply
        local cell = grid:fast_get(x, y)
        if not cell then goto continue end

        if not State.level.grid_complex_layers[layer] then
          cell = {cell}
        end

        for _, e in ipairs(cell) do
          -- TODO tcod
          -- local is_hidden_by_perspective = (
          --   not snapshot:is_transparent_unsafe(x, y)
          --   and e.perspective_flag
          --   and e.position[2] > State.player.position[2]
          -- )
          -- if not is_hidden_by_perspective then
            self:draw_entity(e)
          -- end
        end

        ::continue::
      end
    end
  end
end

return Ldump.mark(game, {}, ...)
