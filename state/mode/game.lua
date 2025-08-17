local ui = require("engine.tech.ui")
local level = require("engine.tech.level")
local tcod  = require("engine.tech.tcod")

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
    local player = State.player

    -- NEXT (when actions) limit speed
    for key, direction in pairs {
      w = Vector.up,
      a = Vector.left,
      s = Vector.down,
      d = Vector.right,
    } do
      if ui.keyboard(key) then
        level.safe_move(player, player.position + direction)
      end
    end

    ui.text("Lorem ipsum dolor sit amet inscowd werdf efds asdew")
    ui.br()

    if State.combat then
      ui.text("Combat:")
      for i, entity in ipairs(State.combat.list) do
        local prefix = State.combat.current_i == i and "x " or "- "
        ui.text(prefix .. Entity.name(entity))
      end
    end
  ui.rect()
end

methods.draw_entity = function(self, entity)
  local current_view = State.perspective.views[entity.view]
  local offset_position = entity.position
  if entity.layer then
    offset_position = offset_position * State.level.cell_size
  end
  offset_position = current_view:apply(offset_position)
  local x, y = unpack(offset_position)

  -- NEXT entity shader
  -- if entity.shader then
  --   love.graphics.setShader(entity.shader.love_shader)
  --   Query(entity.shader):preprocess(entity)
  -- else
  --   Query(State.shader):preprocess(entity)
  -- end

  -- NEXT inventory
  -- NEXT text?

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
  local start, finish do
    local view = State.perspective.views.grids
    start = -(view.offset / view.scale / State.level.cell_size):map(math.ceil)
    finish = start + (
      V(love.graphics.getDimensions()) / view.scale / State.level.cell_size
    ):map(math.ceil)

    start = Vector.use(Math.median, Vector.one, start, State.level.grid_size)
    finish = Vector.use(Math.median, Vector.one, finish, State.level.grid_size)
  end

  local snapshot = tcod.snapshot(State.grids.solids)
  if State.player.fov_r == 0 then
    self:draw_entity(State.player)
    return
  end
  snapshot:refresh_fov(State.player.position, State.player.fov_r)

  -- NEXT background

  for _, layer in ipairs(State.level.layers) do
    local grid = State.grids[layer]
    local sprite_batch = self._sprite_batches[layer]
    if sprite_batch then
      sprite_batch:clear()
    end

    for x = start.x, finish.x do
      for y = start.y, finish.y do
        if not snapshot:is_visible_unsafe(x, y) then goto continue end

        local e = grid:fast_get(x, y)
        if not e then goto continue end

        local is_hidden_by_perspective = (
          not snapshot:is_transparent_unsafe(x, y)
          and e.perspective_flag
          and e.position.y > State.player.position.y
        )
        if is_hidden_by_perspective then goto continue end

        self:draw_entity(e)
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
