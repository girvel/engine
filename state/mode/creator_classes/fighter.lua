local fighter_class = require("engine.mech.class.fighter")
local gui_elements = require("engine.state.mode.gui_elements")
local abilities = require("engine.mech.abilities")
local ui = require("engine.tech.ui")
local translation = require("engine.tech.translation")


local fighter = {}

local FIGHTING_STYLES = Fun.iter(fighter_class.fighting_styles_list)
  :map(function(style)
    return assert(translation.fighting_styles[style.codename]):utf_capitalize()
  end)
  :totable()

local FS_DESCRIPTIONS = {
  "Удар оружием во второй руке наносит больше урона",
  "+1 к классу брони при наличии шлема/доспеха",
}

local SAMURAI_SKILLS = Fun.iter {"performance", "history", "insight"}
  :map(function(codename) return assert(translation.skills[codename]):utf_capitalize() end)
  :totable()

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
  local class_data = self.model.class_data[total_level]

  local con_mod = abilities.get_modifier(self.model.base_data.abilities.con)
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
    if not class_data.fighting_style then
      class_data.fighting_style = FIGHTING_STYLES[1]
    end

    start_ability(gui_elements.fighting_styles, true)
      ui.text("Боевой стиль:")
      ui.switch(FIGHTING_STYLES, class_data, "fighting_style", is_disabled)
    finish_ability(FS_DESCRIPTIONS[Table.index_of(FIGHTING_STYLES, class_data.fighting_style)])

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
    if not class_data.skill then
      class_data.skill = SAMURAI_SKILLS[1]
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
      ui.switch(SAMURAI_SKILLS, class_data, "skill", is_disabled)
      -- NEXT how to detect skill collisions?
    ui.finish_line()
  end
end


Ldump.mark(fighter, {}, ...)
return fighter
