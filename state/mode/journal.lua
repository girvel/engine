local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local journal = {}

--- @class state_mode_journal
--- @field type "journal"
--- @field _prev state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_journal
journal.new = function(prev)
  return setmetatable({
    type = "journal",
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("j") then
    State.quests:new_content_is_read()
    State.mode:close_menu()
  end

  tk.start_window("center", "center", "read_max", "max")
    ui.h1("Журнал")

    for _, codename in ipairs(State.quests.order) do
      local quest = State.quests.items[codename]
      if not quest then goto continue end

      ui.start_font(36)
        ui.start_line()
          love.graphics.setColor(colors.white_dim)
          ui.text("# ")

          if quest.status == "new" or quest.status == "active" then
            love.graphics.setColor(colors.white)
            ui.text(quest.name)
          else
            ui.text(quest.name)
            love.graphics.setColor(colors.white)
          end
        ui.finish_line()
      ui.finish_font()
      ui.br()

      for _, objective in ipairs(quest.objectives) do
        local prefix
        local needs_color_reset = true
        if objective.status == "done" then
          love.graphics.setColor(colors.white_dim)
          prefix = "+ "
        elseif objective.status == "failed" then
          love.graphics.setColor(colors.white_dim)
          prefix = "x "
        elseif objective.status == "new" then
          love.graphics.setColor(colors.golden)
          prefix = "- "
        else
          prefix = "- "
          needs_color_reset = false
        end

        ui.text(prefix .. objective.text)

        if needs_color_reset then
          love.graphics.setColor(colors.white)
        end

      end
      ui.br()
      ui.br()

      ::continue::
    end
    love.graphics.setColor(Vector.white)
  tk.finish_window()
end

Ldump.mark(journal, {}, ...)
return journal
