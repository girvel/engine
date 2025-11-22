local memory = require("engine.tech.shaders.memory")
local colors = require("engine.tech.colors")
local animated = require("engine.tech.animated")
local sound = require("engine.tech.sound")
local base_player = require("engine.state.player.base")
local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local gui = require("engine.state.mode.gui_elements")
local fighter = require("engine.mech.class.fighter")
local tk = require("engine.state.mode.tk")
local interactive = require("engine.tech.interactive")
local api         = require("engine.tech.api")


-- Refactor plan:
--   render functions, utility functions -> game mode as separate file-functions
--   internal state -> game mode fields

-- Internal state
local cost, hint, movement_path, movement_last_t, is_compact
movement_last_t = 0

-- Utility functions
local action_button

-- Render functions
local draw_gui, draw_sidebar, draw_hp_bar, draw_action_grid, draw_resources, draw_move_order,
  draw_bag, draw_dialogue, draw_notification, draw_suggestion, draw_keyboard_action_grid,
  draw_mouse_action_grid, use_mouse, draw_curtain

--- @param self state_mode_game
--- @param dt number
draw_gui = function(self, dt)
  love.graphics.setCanvas(State.player.memory)
  love.graphics.draw(self._main_canvas, unpack(-State.perspective.camera_offset))

  love.graphics.setCanvas()
  local shader = love.graphics.getShader()
  love.graphics.setShader(memory.love_shader)
    love.graphics.draw(State.player.memory, unpack(State.perspective.camera_offset))
  love.graphics.setShader(shader)
  love.graphics.draw(self._main_canvas)

  is_compact = love.graphics.getHeight() < 900

  draw_curtain()
  draw_sidebar(self)
  draw_dialogue()
  draw_notification()
  draw_suggestion()
  use_mouse(self)
end

draw_curtain = function()
  if State.player.curtain_color == Vector.transparent then return end
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(State.player.curtain_color)
    love.graphics.rectangle("fill", 0, 0, w, h)
  love.graphics.setColor(Vector.white)
end

local PADDING_LX = 48
local PADDING_RX = 60
local PADDING_Y = 40

local SIDEBAR_W = 344  -- (usable)

draw_sidebar = function(self)
  if State.runner.locked_entities[State.player] then
    State.perspective.sidebar_w = 0
    return
  end

  State.perspective.sidebar_w = SIDEBAR_W - PADDING_LX - PADDING_RX  -- TODO why -?

  ui.start_frame(love.graphics.getWidth() - SIDEBAR_W - PADDING_LX - PADDING_RX)
    ui.tile(gui.window_bg)
  ui.finish_frame()

  ui.start_frame(
    love.graphics.getWidth() - SIDEBAR_W - PADDING_RX, PADDING_Y,
    SIDEBAR_W, love.graphics.getHeight() - 2 * PADDING_Y
  )
    draw_hp_bar()
    draw_action_grid(self)
    draw_resources()
    draw_move_order()
    draw_bag()

    hint = Kernel._save and "сохранение..." or hint
    if hint then
      ui.start_alignment("center", "bottom")
        ui.text(hint:utf_capitalize())
      ui.finish_alignment()
    end
  ui.finish_frame()
end

action_button = function(action, hotkey)
  local player = State.player
  local is_available = action:is_available(player) and State.player:can_act()
  local codename = is_available and action.codename or (action.codename .. "_inactive")
  local button = ui.key_button(gui_elements[codename], hotkey, not is_available)
  if button.is_clicked then
    player.ai:plan_action(action)
  end
  if button.is_mouse_over then
    cost = action.cost
    hint = action.get_hint and action:get_hint(State.player) or action.name
  end
end

local HP_BAR_W = SIDEBAR_W - 64
local HP_BAR_H = 10 * 4

draw_hp_bar = function()
  local player = State.player

  ui.start_frame(HP_BAR_W + 8, -4, 64, 64)
    ui.image("engine/assets/sprites/gui/shield.png")
  ui.finish_frame()
  ui.start_frame(HP_BAR_W + 8, -4, 64, 64)
  ui.start_alignment("center", "center")
  ui.start_font(32)
    ui.text(player:get_armor())
  ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()

  ui.start_frame(nil, nil, HP_BAR_W, HP_BAR_H + 16)
    ui.tile(gui.hp_bg)

    local saturation = player.hp / player:get_max_hp()
    local base_saturation = math.min(saturation, 1)
    local extra_saturation = saturation > 1 and (1 - 1 / saturation)

    local bar_w = math.floor((HP_BAR_W - 16) * base_saturation / 4)
    ui.start_frame(8, 8, bar_w * 4, HP_BAR_H)
      ui.tile(bar_w > 3 and gui.hp_bar or gui.hp_bar_min)
    ui.finish_frame()

    if extra_saturation then
      ui.start_frame(8, 8, math.floor((HP_BAR_W - 16) * extra_saturation / 4) * 4, HP_BAR_H)
        ui.tile(gui.hp_bar_extra)
      ui.finish_frame()
    end

    ui.start_alignment("center", "center")
    ui.start_font(32)
      ui.text("%s/%s", player.hp, player:get_max_hp())
    ui.finish_font()
    ui.finish_alignment()
  ui.finish_frame(true)
end

draw_action_grid = function(self)
  ui.br()
  if not is_compact then ui.br() end

  cost = nil
  hint = nil

  ui.start_frame(-16, -4)
    ui.image("engine/assets/sprites/gui/action_grid_bg.png")
  ui.finish_frame()

  ui.start_frame(4)
    if self.input_mode == "normal" then
      draw_keyboard_action_grid(self)
    else
      assert(self.input_mode == "target")
      draw_mouse_action_grid(self)
    end
  ui.finish_frame()
  ui.offset(0, 208)

  for key, direction in pairs {
    w = Vector.up,
    a = Vector.left,
    s = Vector.down,
    d = Vector.right,
  } do
    if ui.keyboard(key) then
      movement_path = nil
      movement_last_t = love.timer.getTime()
      State.player.ai:plan_action(actions.move(direction))
    end
  end
end

draw_keyboard_action_grid = function(self)
  ui.start_line()
    do
      local button = ui.key_button(gui.escape_menu, "escape")
      if button.is_clicked then
        State.mode:open_escape_menu()
      end
      if button.is_mouse_over then
        hint = "меню"
      end
    end
    ui.offset(4)

    do
      local journal_image = State.quests.has_new_content and gui.journal or gui.journal_inactive
      local button = ui.key_button(journal_image, "j")
      if button.is_clicked then
        State.mode:open_journal()
      end
      if button.is_mouse_over then
        hint = "журнал"
      end
    end
    ui.offset(4)

    action_button(fighter.hit_dice, "h")
    ui.offset(4)
  ui.finish_line()
  ui.offset(0, 4)

  ui.start_line()
    if State.combat then
      action_button(base_player.skip_turn, "space")
      ui.offset(4)
      action_button(actions.disengage, "g")
    else
      ui.offset(132)
    end
    ui.offset(4)

    action_button(actions.dash, "z")
    ui.offset(4)

    action_button(actions.interact, "e")
    ui.offset(4)
  ui.finish_line()
  ui.offset(0, 4)

  ui.start_line()
    local offhand = State.player.inventory.offhand
    if offhand and offhand.tags.ranged then
      -- when there would be multiple parametrized actions, we can redo this hardcode into an
      -- action_button branch; instead of base action + action factory we can do like an action
      -- class with static methods and like .producer_flag = true; if action_button receives an
      -- action, it does action; if it receives a producer, it does parametrized two-step action.
      local is_available = actions.bow_attack_base:is_available(State.player)
      local image = is_available
        and gui_elements.bow_attack
        or gui_elements.bow_attack_inactive
      local button = ui.key_button(image, "1", not is_available)
      if button.is_clicked then
        self.input_mode = "target"
      end
      if button.is_mouse_over then
        hint = actions.bow_attack_base:get_hint(State.player)
      end
    else
      action_button(actions.hand_attack, "1")
    end
    ui.offset(4)

    if offhand
      and offhand.damage_roll
      and not offhand.tags.ranged
    then
      action_button(actions.offhand_attack, "2")
    else
      action_button(actions.shove, "2")
    end
    ui.offset(4)

    action_button(fighter.second_wind, "3")
    ui.offset(4)

    action_button(fighter.action_surge, "4")
    ui.offset(4)

    action_button(fighter.fighting_spirit, "5")
  ui.finish_line()
end

draw_mouse_action_grid = function(self)
  local escape_button = ui.key_button(gui_elements.escape, "escape")
  if escape_button.is_clicked then
    self.input_mode = "normal"
  end
  if escape_button.is_mouse_over then
    hint = "отмена"
  end
end

local RESOURCE_DISPLAY_ORDER = {
  "actions", "bonus_actions", "reactions", "movement",
  "hit_dice", "action_surge", "second_wind", "fighting_spirit",
}

local ICONS = {
  actions = "#",
  bonus_actions = "+",
  reactions = "*",
  movement = ">",
}

local DEFAULT_ICON = "'"

local COLORS = {
  actions = Vector.hex("79ad9c"),
  bonus_actions = colors.green_high,
  reactions = Vector.hex("fcea9b"),
  movement = Vector.hex("429858"),
}

local PRIMITIVE_RESOURCES = {
  "movement",
  "actions",
  "bonus_actions",
  "reactions",
}

draw_resources = function()
  ui.br()
  if not is_compact then ui.br() end

  local start = tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Ресурсы")
      ui.finish_alignment()
      ui.br()
    end

    for _, r in ipairs(RESOURCE_DISPLAY_ORDER) do
      local amount = State.player.resources[r]
      if not amount or (not State.combat and Table.contains(PRIMITIVE_RESOURCES, r)) then
        goto continue
      end

      ui.start_frame(180)
      ui.start_line()
        local icon = ICONS[r] or DEFAULT_ICON
        local highlighted_n = cost and cost[r]
        if highlighted_n then
          love.graphics.setColor(colors.red_high)
            ui.text(icon * highlighted_n)
          love.graphics.setColor(COLORS[r] or colors.white)
            ui.text(icon * math.max(0, amount - highlighted_n))
          love.graphics.setColor(colors.white)
        else
          love.graphics.setColor(COLORS[r] or colors.white)
            if amount <= 12 then
              ui.text(icon * amount)
            else
              ui.text("x" .. amount)
            end
          love.graphics.setColor(colors.white)
        end
      ui.finish_line()
      ui.finish_frame()

      ui.text(translation.resources[r]:utf_capitalize())

      ::continue::
    end
    love.graphics.setColor(Vector.white)
  tk.finish_block(start)
end

local HOSTILITY_COLOR = {
  enemy = colors.red,
  ally = colors.green_dim,
}

draw_move_order = function()
  if not State.combat then return end

  ui.br()
  if not is_compact then ui.br() end

  local start = tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Очередь ходов")
      ui.finish_alignment()
      ui.br()
    end

    local draw_item = function(i, e)
      ui.start_line()
        if State.combat.current_i == i then
          ui.text("x ")
        else
          love.graphics.setColor(colors.white_dim)
          ui.text("- ")
        end

        local hostility = State.hostility:get(e, State.player)
        local color = hostility and HOSTILITY_COLOR[hostility] or Vector.white

        love.graphics.setColor(color)
          ui.text(Name.game(e):utf_capitalize())
        love.graphics.setColor(Vector.white)
      ui.finish_line()
    end

    local list = State.combat.list
    if #list <= 8 then
      for i, e in ipairs(list) do
        draw_item(i, e)
      end
    else
      local pivot = math.ceil(#list / 10) * 5

      local frame = ui.get_frame()
      ui.start_frame(frame.w / 2)
        for i = pivot + 1, #list do
          draw_item(i, list[i])
        end
      ui.finish_frame()

      for i = 1, pivot do
        draw_item(i, list[i])
      end
    end
  tk.finish_block(start)
end

draw_bag = function()
  --- @type [string, integer][], integer
  local sorted, max_length do
    sorted = {}
    max_length = 0
    for k, v in pairs(State.player.bag) do
      if v > 0 then
        table.insert(sorted, {k, v})
        max_length = math.max(max_length, k:utf_len())
      end
    end

    if #sorted == 0 then return end

    table.sort(sorted, function(a, b)
      return a[1] < b[1]
    end)
  end

  ui.br()
  if not is_compact then ui.br() end

  local start = tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Сумка")
      ui.finish_alignment()
      ui.br()
    end

    for _, t in ipairs(sorted) do
      local k, v = unpack(t)
      ui.text("%s:%s %s", translation.bag[k] or k, " " * (max_length - k:utf_len()), v)
    end
  tk.finish_block(start)  -- TODO UI make this stateless?
end

local draw_line, draw_options

draw_dialogue = function()
  local line = State.player.hears
  if not line then return end

  local H = is_compact and 110 or 200
  local BOTTOM_GAP = (is_compact and 0 or 50) + 40  -- (padding)
  local FONT_SIZE = is_compact and 26 or 32

  tk.start_window("center", love.graphics.getHeight() - H - BOTTOM_GAP, "read_max", H)
  ui.start_font(FONT_SIZE)
    if line.type == "plain_line" then
      draw_line(line)
    elseif line.type == "options" then
      draw_options(line)
    else
      assert(false)
    end
  ui.finish_font()
  tk.finish_window()

  if ui.keyboard("escape") then
    State.mode:open_escape_menu()
  end
end

local SKIP_SOUNDS = sound.multiple("engine/assets/sounds/skip_line", .05)

local FAILURE = colors.red_high
local SUCCESS = colors.green_high

draw_line = function(line)
  local text = line.text
  ui.start_frame()
  ui.start_line()
    local offset = 0
    if line.source then
      local name = Name.game(line.source)
      love.graphics.setColor(line.source.sprite.color)
        ui.text(name)
      love.graphics.setColor(Vector.white)
      ui.text(": ")
      offset = offset + name:utf_len() + 2
    end

    do
      local color
      local _, j, highlighted = text:find("^(%[[^%]]+ — успех%] )")
      if highlighted then
        color = SUCCESS
      else
        _, j, highlighted = text:find("^(%[[^%]]+ — провал%] )")
        if highlighted then
          color = FAILURE
        end
      end

      if highlighted then
        love.graphics.setColor(color)
          ui.text(highlighted)
        love.graphics.setColor(Vector.white)
        offset = offset + highlighted:utf_len()
        text = text:sub(j + 1)
      end
    end

    text = (" " * offset) .. text
  ui.finish_line()
  ui.finish_frame()
  ui.text(text)

  if ui.keyboard("space") or ui.mousedown(1) then
    State.player.hears = nil
    SKIP_SOUNDS:play()
  end
end

draw_options = function(line)
  local sorted = {}
  for i, o in pairs(line.options) do  -- can't use luafun: ipairs/pairs detection conflict
    table.insert(sorted, {i, o})
  end
  table.sort(sorted, function(a, b) return a[1] < b[1] end)

  local displayed = Fun.iter(sorted)
    :enumerate()
    :map(function(i, pair) return i .. ". " .. pair[2] end)
    :totable()

  local n = ui.choice(displayed)
  for i = 1, #displayed do
    if ui.keyboard(tostring(i)) then
      n = i
    end
  end
  if n then
    State.player.speaks = sorted[n][1]
    State.player.hears = nil
  end
end

local start_t, prev

draw_notification = function()
  local text = State.player.notification
  if not text then
    prev = text
    return
  end

  if not prev then
    start_t = love.timer.getTime()
  end
  local dt = love.timer.getTime() - start_t

  local postfix, prefix
  if dt <= .3 then
    prefix  = "  ."
    postfix = ".  "
  elseif dt <= .6 then
    prefix  = " . "
    postfix = " . "
  elseif dt <= .9 then
    prefix  = ".  "
    postfix = "  ."
  else
    prefix  = "   "
    postfix = "   "
  end

  ui.start_frame(nil, 10)
  ui.start_font(32)
  ui.start_alignment("center")
    ui.text(prefix .. text .. postfix)
  ui.finish_alignment()
  ui.finish_font()
  ui.finish_frame()

  prev = text
end

draw_suggestion = function()
  if State.runner.locked_entities[State.player] then return end
  if not actions.interact:is_available(State.player) then return end
  local target = interactive.get_for(State.player)  --[[@as item]]
  if not target then return end

  ui.start_frame(nil, love.graphics.getHeight() - 100)
  ui.start_alignment("center")
  ui.start_font(32)
    local name = Name.game(target)
    local roll = target.damage_roll
    if roll then
      if target.bonus then
        roll = roll + target.bonus
      end
      name = ("%s (%s)"):format(name, roll:simplified())
    end
    ui.text("[E] для взаимодействия с " .. name)
  ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()
end

local movement_interact = nil
local PATH_MAX_LENGTH = 50

use_mouse = function(self)
  if movement_path then
    if love.timer.getTime() - movement_last_t >= 1/8 then
      movement_last_t = love.timer.getTime()

      if #movement_path > 0 then
        local next = table.remove(movement_path, 1)
        State.player.ai:plan_action(actions.move(next - State.player.position)):next(function(ok)
          if not ok then
            movement_path = nil
          end
        end)
      else
        if movement_interact then
          local target = interactive.get_at(movement_interact)
          if target then
            api.rotate(State.player, target)
            State.player.ai:plan_action(actions.interact)
          end
          movement_interact = nil
        end
        movement_path = nil
      end
    end

    if ui.mousedown(1) then
      movement_path = nil
    end
  end

  if not State.player:can_act() then return end

  ui.start_frame(nil, nil, -State.perspective.sidebar_w)
    ui.cursor(self.input_mode == "target" and "target_inactive" or nil)

    local position = V(love.mouse.getPosition())
      :sub_mut(State.perspective.camera_offset)
      :div_mut(Constants.cell_size * 4)
      :map_mut(math.floor)
    local solid = State.grids.solids:slow_get(position)
    local interaction_target = interactive.get_at(position)

    local lmb = ui.mousedown(1)
    local rmb = ui.mousedown(2)

    if self.input_mode == "target" then
      if rmb then
        self.input_mode = "normal"
      end

      if solid then
        local action = actions.bow_attack(solid)

        if action:is_available(State.player) then
          ui.cursor("target_active")
          if rmb then
            State.player.ai:plan_action(action)
          end
        end
      end
    else
      if interaction_target then
        ui.cursor("hand")
      end

      local offhand = State.player.inventory.offhand
      if (lmb and interaction_target) or (rmb and not solid) then
        local is_target_solid = interaction_target
          and Table.contains({"solids", "on_solids"}, interaction_target.grid_layer)

        if interaction_target and (
          (State.player.position - position):abs2() == 1 and is_target_solid
          or State.player.position == position and not is_target_solid
        ) then
          movement_path = {}
          movement_interact = position
        else
          local path = api.build_path(State.player.position, position)

          if path and #path > 0 and #path <= PATH_MAX_LENGTH then
            if State.player.position ~= position then
              movement_path = path
              movement_last_t = love.timer.getTime()
              State:add(animated.fx("engine/assets/sprites/animations/mouse_travel", position))
            end  -- interact should still work even if no movement is needed
            if lmb then
              movement_interact = interaction_target and position or nil
            end
          end
        end
      end

      if solid and offhand and offhand.tags.ranged then
        local action = actions.bow_attack(solid)

        if action:is_available(State.player)
          and (State.hostility:get(State.player, solid) == "enemy"
            or State.hostility:get(solid, State.player) == "enemy")
        then
          ui.cursor("target_active")
          if rmb then
            State.player.ai:plan_action(action)
          end
        end
      end
    end
  ui.finish_frame()
end

Ldump.mark(draw_gui, {}, ...)
return draw_gui
