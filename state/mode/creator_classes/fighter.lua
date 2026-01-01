local class = require("engine.mech.class")
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

fighter.init_data = function(data)
  if data.class_level == 1 then
    data.fighting_style = FIGHTING_STYLES[1]
  end
  return data
end

--- @param creator state_mode_creator
fighter.draw_pane = function(creator, dt, data)
  local con_mod = abilities.get_modifier(
    creator.model.pane_data[0].abilities.con + creator:get_bonus("con")
  )
  local hp_bonus
  if data.total_level == 1 then
    hp_bonus = 10
  else
    hp_bonus = 6
  end

  -- NEXT move to the creator itself
  -- NEXT calculate total?
  ui.text(
    "  +%d %s %d (Телосложение) = %+d здоровья",
    hp_bonus, con_mod >= 0 and "+" or "-", math.abs(con_mod), hp_bonus + con_mod
  )
  ui.br()

  if data.class_level == 1 then
    creator:start_ability(gui_elements.fighting_styles, true)
      ui.text("Боевой стиль:")
      creator:switch(FIGHTING_STYLES, "fighting_style")
    creator:finish_ability(data.fighting_style.description)

    creator:start_ability(gui_elements.second_wind)
      ui.text("Способность: Второе дыхание")
      local roll = fighter_class.second_wind:get_roll(creator.model.total_level)
    creator:finish_ability(
      "Раз за бой бонусным действием восстанавливает %d-%d здоровья",
      roll:min(), roll:max()
    )
  elseif data.class_level == 2 then
    creator:start_ability(gui_elements.action_surge)
      ui.text("Способность: Всплеск действий")
    creator:finish_ability("Раз за бой даёт одно дополнительное действие")
  elseif data.class_level == 3 then
    creator:start_ability(gui_elements.fighting_spirit)
      ui.text("Способность: Боевой дух")
    creator:finish_ability(
      "Три раза за игру бонусным действием даёт 5 ед. временного здоровья; атаки в этот ход " ..
      "попадают чаще."
    )
  end
end

--- @param creator state_mode_creator
fighter.submit = function(creator, data)
  local result

  if data.total_level == 1 then
    result = {fighter_class.base_hit_dice}
  else
    result = {fighter_class.hit_dice}
  end

  if data.class_level == 1 then
    table.insert(result, data.fighting_style)
    table.insert(result, fighter_class.second_wind)
  elseif data.class_level == 2 then
    table.insert(result, fighter_class.action_surge)
  elseif data.class_level == 3 then
    table.insert(result, fighter_class.fighting_spirit)
  end

  return result
end

Ldump.mark(fighter, {}, ...)
return fighter
