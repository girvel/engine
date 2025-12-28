local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local creator = {}

--- @class state_mode_creator
--- @field type "creator"
--- @field _prev state_mode_game
--- @field model table
local methods = {}
creator.mt = {__index = methods}

local POSSIBLE_SKILLS = {
  "Выживание",
  "Внимание",
  "Атлетика",
}

local POSSIBLE_RACES = {
  "Разносторонний человек",
  "Альтернативный человек",
  "Необычное происхождение",
}

local POSSIBLE_ABILITIES = {
  "Сила",
  "Ловкость",
  "Телосложение",
}

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  return setmetatable({
    type = "creator",
    _prev = prev,
    model = {
      race = POSSIBLE_RACES[1],
      skill_1 = POSSIBLE_SKILLS[1],
      skill_2 = POSSIBLE_SKILLS[2],
      bonus_plus1_1 = POSSIBLE_ABILITIES[1],
      bonus_plus1_2 = POSSIBLE_ABILITIES[2],
      bonus_plus2 = POSSIBLE_ABILITIES[1],
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

    ui.start_line()
      ui.selector()
      ui.text("## ")
      ui.switch(POSSIBLE_RACES, self.model, "race")
    ui.finish_line()
    ui.br()

    ui.start_line()
      ui.selector()
      ui.text("Навык:  ")
      ui.switch(POSSIBLE_SKILLS, self.model, "skill_1")
    ui.finish_line()

    ui.start_line()
      ui.selector()
      ui.text("Навык:  ")
      local skills = Table.shallow_copy(POSSIBLE_SKILLS)
      Table.remove(skills, self.model.skill_1)
      ui.switch(skills, self.model, "skill_2")
    ui.finish_line()

    if self.model.race == POSSIBLE_RACES[1] then
      ui.text("  +1 ко всем характеристикам")
    else
      if self.model.race == POSSIBLE_RACES[3] then
        ui.start_line()
          ui.selector()
          ui.text("+2:  ")
          ui.switch(POSSIBLE_ABILITIES, self.model, "bonus_plus2")
        ui.finish_line()
      else
        ui.start_line()
          ui.selector()
          ui.text("+1:  ")
          ui.switch(POSSIBLE_ABILITIES, self.model, "bonus_plus1_1")
        ui.finish_line()

        ui.start_line()
          ui.selector()
          ui.text("+1:  ")
          local remaining_abilities = Table.shallow_copy(POSSIBLE_ABILITIES)
          Table.remove(remaining_abilities, self.model.bonus_plus1_1)
          ui.switch(remaining_abilities, self.model, "bonus_plus1_2")
        ui.finish_line()
      end

      ui.start_line()
        ui.selector()
        ui.text("Черта: < Чёрт >")
        -- NEXT
      ui.finish_line()
    end

    -- NEXT analyze script, find out used abilities
    -- NEXT handle mouse
    -- NEXT align switch
    -- NEXT fancier subheader
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(creator, {mt = "const"}, ...)
return creator
