local ui = require("engine.tech.ui")
local tcod  = require("engine.tech.tcod")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local sprite       = require("engine.tech.sprite")

local game = {}

--- @class state_mode_game
--- @field _sprite_batches table<string, love.SpriteBatch>
--- @field _temp_canvas love.Canvas
local methods = {}
local mt = {__index = methods}

game.new = function()
  return setmetatable({
    _sprite_batches = Fun.iter(State.level.atlases)
      :map(function(layer, base_image) return layer, love.graphics.newSpriteBatch(base_image) end)
      :tomap(),
    _temp_canvas = love.graphics.newCanvas(),
  }, mt)
end

local SIDEBAR_W = 320
local PADDING = 40
local HP_BAR_H = 10 * 4

local ICON_ATLAS = love.graphics.newImage("engine/assets/sprites/icons.png")
local SKIP_TURN = sprite.utility.cut_out(ICON_ATLAS, sprite.utility.get_atlas_quad(1, 16, ICON_ATLAS:getDimensions()))

methods.draw_gui = function(self, dt)
  State.perspective:update(dt)

  ui.start_frame(love.graphics.getWidth() - SIDEBAR_W - 2 * PADDING)
    ui.tile("assets/sprites/atlases/sidebar_bg.png")
  ui.finish_frame()

  ui.start_frame(love.graphics.getWidth() - SIDEBAR_W - PADDING, PADDING, love.graphics.getHeight() - 2 * PADDING, SIDEBAR_W)
    local player = State.player

    ui.start_frame(nil, nil, SIDEBAR_W, HP_BAR_H + 16)
      ui.tile("engine/assets/sprites/hp_bg.png")
      ui.start_frame(8, 8, SIDEBAR_W - 16, HP_BAR_H)
        ui.tile("engine/assets/sprites/hp_bar.png")
        ui.start_alignment("center", "center")
        ui.start_font(32)
          ui.text("%s/%s" % {player.hp, player:get_max_hp()})
        ui.finish_font()
        ui.finish_alignment()
      ui.finish_frame()
    ui.finish_frame(true)

    ui.br()
    ui.br()

    if State.combat then
      local button = ui.hot_button(SKIP_TURN, "space")
      if button.is_pressed then
        player.ai.finish_turn = true
      end
    end

    -- NEXT (when actions) limit speed
    for key, direction in pairs {
      w = Vector.up,
      a = Vector.left,
      s = Vector.down,
      d = Vector.right,
    } do
      if ui.keyboard(key) then
        player.ai.next_action = actions.move(direction)
      end
    end

    ui.text("Lorem ipsum dolor sit amet inscowd werdf efds asdew")

    ui.br()
    local max = player:get_resources("full")
    local RESOURCE_DISPLAY_ORDER = {
      "actions", "bonus_actions", "reactions", "movement", "hit_dice",
    }

    ui.table({"Ресурсы", ""}, Fun.iter(RESOURCE_DISPLAY_ORDER)
      :filter(function(key)
        return player.resources[key] and (State.combat or key ~= "movement")
      end)
      :map(function(key)
        return {translation.resources[key], player.resources[key] .. "/" .. max[key]}
      end)
      :totable())

    if State.combat then
      ui.br()
      ui.text("Combat:")
      for i, entity in ipairs(State.combat.list) do
        local prefix = State.combat.current_i == i and "x " or "- "
        ui.text(prefix .. Entity.name(entity))
      end
    end
  ui.finish_frame()
end

methods.draw_entity = function(self, entity, dt)
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

methods.draw_grid = function(self, dt)
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
    self:draw_entity(State.player, dt)
    return
  end
  snapshot:refresh_fov(State.player.position, State.player.fov_r)

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

        self:draw_entity(e, dt)
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
