local player_mod = require("engine.state.player")
local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local gui = require("engine.state.mode.gui_elements")
local fighter = require("engine.mech.class.fighter")


local PADDING = 40
local HP_BAR_H = 10 * 4

--- @param self state_mode_game
--- @param dt number
local draw_gui = function(self, dt)
  State.perspective:update(dt)
  local SIDEBAR_W = State.perspective.SIDEBAR_W - 2 * PADDING

  ui.start_frame(love.graphics.getWidth() - SIDEBAR_W - 2 * PADDING)
    ui.tile(gui.window_bg)
  ui.finish_frame()

  ui.start_frame(
    love.graphics.getWidth() - SIDEBAR_W - PADDING, PADDING,
    SIDEBAR_W, love.graphics.getHeight() - 2 * PADDING
  )
    local player = State.player

    ui.start_frame(nil, nil, SIDEBAR_W, HP_BAR_H + 16)
      ui.tile(gui.hp_bg)
      ui.start_frame(8, 8, (SIDEBAR_W - 16) * player.hp / player:get_max_hp(), HP_BAR_H)
        ui.tile(gui.hp_bar)
      ui.finish_frame()
      ui.start_alignment("center", "center")
      ui.start_font(32)
        ui.text("%s/%s" % {player.hp, player:get_max_hp()})
      ui.finish_font()
      ui.finish_alignment()
    ui.finish_frame(true)

    ui.br()
    ui.br()

    ui.start_line()
      if ui.hot_button(gui.escape_menu, "escape") then
        State.mode:open_escape_menu()
      end
      ui.offset(4)

      local journal_image = State.quests.has_new_content and gui.journal or gui.journal_inactive
      if ui.hot_button(journal_image, "j") then
        State.mode:open_journal()
      end
      ui.offset(4)

      if State.combat then
        tk.action_button(player_mod.skip_turn, "space")
        ui.offset(4)
      end
    ui.finish_line()
    ui.offset(0, 4)

    ui.start_line()
      tk.action_button(actions.hand_attack, "1")
      ui.offset(4)

      tk.action_button(actions.offhand_attack, "2")
      ui.offset(4)

      tk.action_button(fighter.action_surge, "4")
      ui.offset(4)
    ui.finish_line()

    ui.br()

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
      "actions", "bonus_actions", "reactions", "movement", "hit_dice", "action_surge",
    }

    ui.table({"Ресурсы", ""}, Fun.iter(RESOURCE_DISPLAY_ORDER)
      :filter(function(key)
        return player.resources[key] and (State.combat or key ~= "movement")
      end)
      :map(function(key)
        return {
          translation.resources[key]:utf_capitalize(),
          player.resources[key] .. "/" .. max[key]
        }
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
