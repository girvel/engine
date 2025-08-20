local ui = require("engine.tech.ui")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local gui = require("engine.state.mode.game.gui_elements")


local SIDEBAR_W = 320
local PADDING = 40
local HP_BAR_H = 10 * 4

--- @param self state_mode_game
--- @param dt number
local draw_gui = function(self, dt)
  State.perspective:update(dt)

  ui.start_frame(love.graphics.getWidth() - SIDEBAR_W - 2 * PADDING)
    ui.tile(gui.sidebar_bg)
  ui.finish_frame()

  ui.start_frame(
    love.graphics.getWidth() - SIDEBAR_W - PADDING, PADDING,
    SIDEBAR_W, love.graphics.getHeight() - 2 * PADDING
  )
    local player = State.player

    ui.start_frame(nil, nil, SIDEBAR_W, HP_BAR_H + 16)
      ui.tile(gui.hp_bg)
      ui.start_frame(8, 8, SIDEBAR_W - 16, HP_BAR_H)
        ui.tile(gui.hp_bar)
        ui.start_alignment("center", "center")
        ui.start_font(32)
          ui.text("%s/%s" % {player.hp, player:get_max_hp()})
        ui.finish_font()
        ui.finish_alignment()
      ui.finish_frame()
    ui.finish_frame(true)

    ui.br()
    ui.br()

    ui.start_line()
      -- if State.combat then
        local button = ui.hot_button(gui.skip_turn, "space")
        if button.is_pressed then
          player.ai.finish_turn = true
        end
      -- end

      do
        local button = ui.hot_button(gui.journal, "j")
        if button.is_pressed then
          Log.debug("Journal")
        end
      end
    ui.finish_line()

    -- ui.start_line()
    -- ui.finish_line()

    ui.br()

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

    ui.text("Lorem ipsum dolor sit amet inscowd werdf efds asdew asdfawe qwerasd fqwera asdf")

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

return draw_gui
