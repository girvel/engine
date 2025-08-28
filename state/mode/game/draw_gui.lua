local player_mod = require("engine.state.player")
local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local gui = require("engine.state.mode.gui_elements")
local fighter = require("engine.mech.class.fighter")
local tk = require("engine.state.mode.tk")


local PADDING_LX = 48
local PADDING_RX = 60
local PADDING_Y = 40
local HP_BAR_H = 10 * 4

local cost, hint, sidebar_w
local action_button, draw_hp_bar, draw_action_grid, draw_resources, draw_move_order

--- @param self state_mode_game
--- @param dt number
local draw_gui = function(self, dt)
  State.perspective:update(dt)
  sidebar_w = State.perspective.SIDEBAR_W - PADDING_LX - PADDING_RX

  ui.start_frame(love.graphics.getWidth() - sidebar_w - PADDING_LX - PADDING_RX)
    ui.tile(gui.window_bg)
  ui.finish_frame()

  ui.start_frame(
    love.graphics.getWidth() - sidebar_w - PADDING_RX, PADDING_Y,
    sidebar_w, love.graphics.getHeight() - 2 * PADDING_Y
  )
    draw_hp_bar()

    ui.br()
    ui.br()

    draw_action_grid()

    ui.br()
    ui.br()

    draw_resources()

    ui.br()
    ui.br()

    if State.combat then
      draw_move_order()
    end

    if hint then
      ui.start_alignment("center", "bottom")
        ui.text(hint:utf_capitalize())
      ui.finish_alignment()
    end
  ui.finish_frame()
end

action_button = function(action, hotkey)
  local player = State.player
  local is_available = action:is_available(player)
  local codename = is_available and action.codename or (action.codename .. "_inactive")
  local button = ui.hot_button(gui_elements[codename], hotkey, not is_available)
  if button.is_pressed then
    player.ai.next_action = action
  end
  if button.is_mouse_over then
    cost = action.cost
    hint = action.name
  end
end

draw_hp_bar = function()
  local player = State.player

  ui.start_frame(nil, nil, sidebar_w, HP_BAR_H + 16)
    ui.tile(gui.hp_bg)

    local saturation = player.hp / player:get_max_hp()
    local base_saturation = math.min(saturation, 1)
    local extra_saturation = saturation > 1 and (1 - 1 / saturation)

    ui.start_frame(8, 8, math.floor((sidebar_w - 16) * base_saturation / 4) * 4, HP_BAR_H)
      ui.tile(gui.hp_bar)
    ui.finish_frame()

    if extra_saturation then
      ui.start_frame(8, 8, math.floor((sidebar_w - 16) * extra_saturation / 4) * 4, HP_BAR_H)
        ui.tile(gui.hp_bar_extra)
      ui.finish_frame()
    end

    ui.start_alignment("center", "center")
    ui.start_font(32)
      ui.text("%s/%s" % {player.hp, player:get_max_hp()})
    ui.finish_font()
    ui.finish_alignment()
  ui.finish_frame(true)
end

draw_action_grid = function()
  cost = nil
  hint = nil

  ui.start_frame(-16, -4)
    ui.image("engine/assets/sprites/gui/action_grid_bg.png")
  ui.finish_frame()

  ui.start_frame(4)
    ui.start_line()
      do
        local button = ui.hot_button(gui.escape_menu, "escape")
        if button.is_pressed then
          State.mode:open_escape_menu()
        end
        if button.is_mouse_over then
          hint = "меню"
        end
      end
      ui.offset(4)

      do
        local journal_image = State.quests.has_new_content and gui.journal or gui.journal_inactive
        local button = ui.hot_button(journal_image, "j")
        if button.is_pressed then
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
        action_button(player_mod.skip_turn, "space")
        ui.offset(4)
        action_button(actions.disengage, "g")
      else
        ui.offset(132)
      end
      ui.offset(4)

      action_button(actions.dash, "lshift")
      ui.offset(4)
    ui.finish_line()
    ui.offset(0, 4)

    ui.start_line()
      action_button(actions.hand_attack, "1")
      ui.offset(4)

      if State.player.inventory.offhand then
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
  ui.finish_frame()
  ui.offset(0, 208)

  for key, direction in pairs {
    w = Vector.up,
    a = Vector.left,
    s = Vector.down,
    d = Vector.right,
  } do
    if ui.keyboard(key) then
      State.player.ai.next_action = actions.move(direction)
    end
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
  bonus_actions = Vector.hex("c3e06c"),
  reactions = Vector.hex("fcea9b"),
  movement = Vector.hex("429858"),
}

local WHITE = Vector.hex("ffffff")
local HIGHLIGHTED = Vector.hex("e7573e")

local PRIMITIVE_RESOURCES = {
  "movement",
  "actions",
  "bonus_actions",
  "reactions",
}

draw_resources = function()
  local start = tk.start_block()
    ui.start_alignment("center")
      ui.text("Ресурсы")
    ui.finish_alignment()
    ui.br()

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
          love.graphics.setColor(HIGHLIGHTED)
            ui.text(icon * highlighted_n)
          love.graphics.setColor(COLORS[r] or WHITE)
            ui.text(icon * math.max(0, amount - highlighted_n))
          love.graphics.setColor(WHITE)
        else
          love.graphics.setColor(COLORS[r] or WHITE)
            if amount <= 12 then
              ui.text(icon * amount)
            else
              ui.text("x" .. amount)
            end
          love.graphics.setColor(WHITE)
        end
      ui.finish_line()
      ui.finish_frame()

      ui.text(translation.resources[r]:utf_capitalize())

      ::continue::
    end
  tk.finish_block(start)
end

BORDERS = Vector.hex("191919")
ENEMY = Vector.hex("99152c")
ALLY = Vector.hex("5d863f")

draw_move_order = function()
  local start = tk.start_block()
    ui.start_alignment("center")
      ui.text("Очередь ходов")
    ui.finish_alignment()
    ui.br()

    for i, e in ipairs(State.combat.list) do
      ui.start_line()
        if State.combat.current_i == i then
          ui.text("x ")
        else
          love.graphics.setColor(BORDERS)
          ui.text("- ")
        end

        local color =
          e == State.player and Vector.white
          or State.hostility:get(e, State.player) and ENEMY
          or ALLY

        love.graphics.setColor(color)
          ui.text(Entity.name(e))
        love.graphics.setColor(Vector.white)
      ui.finish_line()
    end
  tk.finish_block(start)
  -- ui.separator()
  -- ui.table({"", "Очередь ходов"}, Fun.iter(State.combat.list)
  --   :enumerate()
  --   :map(function(i, e) return {
  --     State.combat.current_i == i and "x" or "-",
  --     Entity.name(e),
  --   } end)
  --   :totable())
end

return draw_gui
