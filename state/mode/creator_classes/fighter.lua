local class = require("engine.mech.class.init")
local fighter_class = require("engine.mech.class.fighter")
local gui_elements = require("engine.state.mode.gui_elements")
local abilities = require("engine.mech.abilities")
local ui = require("engine.tech.ui")


local fighter = {}

local FIGHTING_STYLES = fighter_class.fighting_styles_list

local SAMURAI_SKILLS = {
  class.skill_proficiency("performance"),
  class.skill_proficiency("history"),
  class.skill_proficiency("insight"),
}

local start_ability = function(image, selector)
  ui.start_line()
  if selector then
    ui.selector()
  else
    ui.text("  ")
  end
  ui.image(image, 2)
  ui.start_font(32)
  ui.text(" ")
end

local finish_ability = function(fmt, ...)
  ui.finish_font()
  ui.finish_line()

  ui.start_frame(32 + ui.get_font():getWidth("w") * 3)
    ui.text(fmt, ...)
    local y = ui.get_frame().y
  ui.finish_frame()
  ui.get_frame().y = y
  ui.br()
end

fighter.draw_pane = function(self, dt, is_disabled, total_level, class_level)
  local data = self.model.pane_data[total_level]

  local con_mod = abilities.get_modifier(self.model.pane_data[0].abilities.con)
  local hp_bonus
  if total_level == 1 then
    -- NEXT implement this
    -- NEXT figure out how many skills & where
    hp_bonus = 10
  else
    hp_bonus = 6
  end

  ui.text("  +%d %s %d (Телосложение) = %+d здоровья", hp_bonus, con_mod >= 0 and "+" or "-", math.abs(con_mod), hp_bonus + con_mod)
  ui.br()

  if class_level == 1 then
    if not data.fighting_style then
      data.fighting_style = FIGHTING_STYLES[1]
    end

    start_ability(gui_elements.fighting_styles, true)
      ui.text("Боевой стиль:")
      ui.switch(FIGHTING_STYLES, data, "fighting_style", is_disabled)
    finish_ability(data.fighting_style.description)

    start_ability(gui_elements.second_wind)
      ui.text("Способность: Второе дыхание")
      local roll = fighter_class.second_wind:get_roll(self.model.total_level)
    finish_ability(
      "Раз за бой бонусным действием восстанавливает %d-%d здоровья",
      roll:min(), roll:max()
    )
  elseif class_level == 2 then
    start_ability(gui_elements.action_surge)
      ui.text("Способность: Всплеск действий")
    finish_ability("Раз за бой даёт одно дополнительное действие")
  elseif class_level == 3 then
    if not data.skill then
      data.skill = SAMURAI_SKILLS[1]
    end

    start_ability(gui_elements.fighting_spirit)
      ui.text("Способность: Боевой дух")
    finish_ability(
      "Три раза за игру бонусным действием даёт 5 ед. временного здоровья; атаки в этот ход " ..
      "попадают чаще."
    )

    ui.start_line()
      ui.selector()
      ui.text("Навык:")
      ui.switch(SAMURAI_SKILLS, data, "skill", is_disabled)
      -- NEXT how to detect skill collisions?
    ui.finish_line()
  end
end


Ldump.mark(fighter, {}, ...)
return fighter
