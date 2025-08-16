local ui = require("engine.tech.ui")

local game = {}

--- @class state_mode_game
--- @field _sprite_batches table<string, love.SpriteBatch>
local methods = {}
local mt = {__index = methods}

game.new = function()
  return setmetatable({
    _sprite_batches = Fun.iter(State.level.atlases)
      :map(function(layer, base_image) return layer, love.graphics.newSpriteBatch(base_image) end)
      :tomap(),
  }, mt)
end

local SIDEBAR_W = 320

methods.draw_gui = function(self, dt)
  State.perspective:update(dt)

  ui.rect(-SIDEBAR_W, nil, nil, nil)
  ui.text("Lorem ipsum dolor sit amet inscowd werdf efds asdew")
  ui.br()
  ui.text("Inventory:")
  ui.text(" - Swords: 3")
end

methods.draw_entity = function(self, entity)
  local current_view = State.perspective.views[entity.view]
  local offset_position = current_view:apply(entity.position)

  -- TODO entity shader
  -- if entity.shader then
  --   love.graphics.setShader(entity.shader.love_shader)
  --   Query(entity.shader):preprocess(entity)
  -- else
  --   Query(State.shader):preprocess(entity)
  -- end

  -- TODO inventory
  -- TODO text?

  if entity.layer then
    offset_position:mul_mut(State.level.cell_size)
  end
  local x, y = unpack(offset_position)

  local sprite = entity.sprite
  if sprite.type == "image" then
    love.graphics.draw(entity.sprite.image, x, y, 0, current_view.scale)
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.layer]:add(sprite.quad, x, y, 0, current_view.scale)
  end

  -- if entity.shader then
  --   love.graphics.setShader(-Query(State.shader).love_shader)
  -- end
end

methods.draw_grid = function(self)
  local start = Vector.one
  local finish = State.level.grid_size
  -- TODO mask
  -- TODO background

  for _, layer in ipairs(State.level.layers) do
    local grid = State.grids[layer]
    local sprite_batch = self._sprite_batches[layer]
    if sprite_batch then
      sprite_batch:clear()
    end

    for x = start.x, finish.x do
      for y = start.y, finish.y do
        -- TODO mask apply
        local e = grid:fast_get(x, y)
        if not e then goto continue end

        -- TODO tcod
        -- local is_hidden_by_perspective = (
        --   not snapshot:is_transparent_unsafe(x, y)
        --   and e.perspective_flag
        --   and e.position[2] > State.player.position[2]
        -- )
        -- if not is_hidden_by_perspective then
          self:draw_entity(e)
        -- end

        ::continue::
      end
    end

    if sprite_batch then
      love.graphics.draw(sprite_batch)
    end
  end
end

Ldump.mark(game, {}, ...)
return game
