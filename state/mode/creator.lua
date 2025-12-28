local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local creator = {}

--- @class state_mode_creator
--- @field type "creator"
--- @field _prev state_mode_game
--- @field model table
local methods = {}
creator.mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  return setmetatable({
    type = "creator",
    _prev = prev,
    model = {
      skill_1 = "Выживание",
      skill_2 = "Внимание",
    },
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("n") then
    State.mode:close_menu()
  end

  tk.start_window("center", "center", 400, 600)
  ui.start_font(24)
    ui.h1("Персонаж")

    ui.text("[0] > [1] > [2]")
    ui.br()

    ui.text("## Раса: < Человек >")
    ui.br()

    ui.text("+1 ко всем характеристикам")
    ui.text("Навык: < %s >", self.model.skill_1)
    ui.text("Навык: < %s >", self.model.skill_2)
    -- NEXT analyze script, find out used abilities
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(creator, {mt = "const"}, ...)
return creator
