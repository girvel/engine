local gui_elements = require("engine.state.mode.gui_elements")
local fighter = require("engine.mech.class.fighter")
local xp = require("engine.mech.xp")
local translation = require("engine.tech.translation")
local abilities = require("engine.mech.abilities")
local colors = require("engine.tech.colors")
local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local creator = {}

--- @class state_mode_creator
--- @field type "creator"
--- @field _prev state_mode_game
--- @field model table
--- @field pane_i integer
local methods = {}
creator.mt = {__index = methods}

local SKILLS = Fun.iter(abilities.skill_bases)
  :map(function(skill) return assert(translation.skills[skill]):utf_capitalize() end)
  :totable()

local ABILITIES = Fun.iter(abilities.list)
  :map(function(ability) return assert(translation.abilities[ability]):utf_capitalize() end)
  :totable()

local FEAT_CODENAMES = {
  "savage_attacker",
  "great_weapon_master",
}

local FEATS = Fun.iter(FEAT_CODENAMES)
  :map(function(feat) return assert(translation.feats[feat]):utf_capitalize() end)
  :totable()

local FEAT_DESCRIPTIONS = {
  "Атаки наносят больше урона",
  "Шанс попадания двуручным оружием меньше на 25%, урон выше на 10",
}

local RACES = {
  "Разносторонний человек",
  "Альтернативный человек",
  "Необычное происхождение",
}

local CLASSES_DATA = {
  fighter,
}

local CLASSES = Fun.iter(CLASSES_DATA)
  :map(function(cls) return assert(translation.classes[cls.codename]):utf_capitalize() end)
  :totable()

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  local current_level = State.player.level

  local total_level, pane_i do
    total_level = current_level
    local xp_remains = State.player.xp
    while true  do
      local delta = xp.for_level[total_level + 1] - xp.for_level[total_level]
      if xp_remains < delta then break end
      xp_remains = xp_remains - delta
      total_level = total_level + 1
    end

    if current_level == 0 then
      pane_i = 0
    elseif total_level > current_level then
      pane_i = current_level + 1
    else
      pane_i = total_level
    end
  end

  local model do
    model = State.player.creator_model
    if not model then
      model = {
        base_data = {
          abilities = abilities.new(8, 8, 8, 8, 8, 8),
          points = 27,
          race = RACES[1],
          skill_1 = SKILLS[1],
          skill_2 = SKILLS[2],
          bonus_plus1_1 = ABILITIES[1],
          bonus_plus1_2 = ABILITIES[2],
          bonus_plus2 = ABILITIES[1],
          feat = FEATS[1],
        },
        classes = {},
        class_data = {},
        total_level = total_level,
      }
    end

    for i = 1, total_level - current_level do
      model.classes[current_level + i] = model.classes[current_level] or CLASSES[1]
      model.class_data[current_level + i] = {}
    end
  end

  return setmetatable({
    type = "creator",
    _prev = prev,
    model = model,
    pane_i = pane_i,
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local draw_base_pane, draw_pane

local is_disabled

methods.draw_gui = function(self, dt)
  is_disabled = self.model.total_level <= State.player.level

  if ui.keyboard("escape") or ui.keyboard("n") then
    State.mode:close_menu()
  end

  if ui.keyboard("j") then
    State.mode:close_menu()
    State.mode:open_journal()
  end

  if ui.keyboard("return") then
    if self.model.base_data.points > 0 then
      State.mode:show_warning(
        "Редактирование персонажа не закончено: не все очки способностей израсходованы"
      )
    end
  end

  tk.start_window("center", "center", 700, 620)
    ui.h1("Персонаж")
    ui.start_font(24)
      ui.start_line()
        if ui.selector() then
          if ui.keyboard("left") then
            self.pane_i = (self.pane_i - 1) % (self.model.total_level + 1)
          end

          if ui.keyboard("right") then
            self.pane_i = (self.pane_i + 1) % (self.model.total_level + 1)
          end
        end

        ui.text("Уровень: ")
        for i = 0, self.model.total_level do
          if i > 0 then
            ui.text(">")
          end
          if i == self.pane_i then
            ui.text(" [%s] ", i)
          else
            if i > State.player.level then ui.start_styles({link_color = colors.golden}) end
            if ui.text_button(" [%s] ", i).is_clicked then
              self.pane_i = i
            end
            if i > State.player.level then ui.finish_styles() end
          end
        end
      ui.finish_line()
      ui.br()

      if self.pane_i == 0 then
        draw_base_pane(self, dt)
      else
        draw_pane(self, dt)
      end

      -- NEXT submit
      -- NEXT link_color for ui.choice
      -- NEXT display only the available actions in sidebar
      -- NEXT really highlight the updated creator
      -- NEXT highlight the updated journal
      -- NEXT task for never: setting to disable annoying highlights
      -- NEXT when warlock: kind of recognize the Nea
      -- NEXT distribute abilities randomly?
      -- NEXT more fighting styles

    ui.finish_font()
  tk.finish_window()
end

--- @param self state_mode_creator
--- @param dt number
draw_base_pane = function(self, dt)
  local data = self.model.base_data
  local column1_length = Fun.iter(ABILITIES)
    :map(function(name) return name:utf_len() end)
    :max()

  local column2_length = 16

  local header = ("%s   %s МОДИФИКАТОР"):format(
    ("ХАР-КА"):ljust(column1_length, " "),
    ("ЗНАЧЕНИЕ"):ljust(column2_length, " ")
  )

  ui.text("  " .. header)
  ui.text("  " .. "-" * header:utf_len())

  for _, codename in ipairs(abilities.list) do
    ui.start_line()
      local name = translation.abilities[codename]:utf_capitalize()
      local raw_score = data.abilities[codename]
      local bonus
      if data.race == RACES[1] then
        bonus = 1
      elseif data.race == RACES[2] then
        bonus = (data.bonus_plus1_1 == name or data.bonus_plus1_2 == name)
          and 1 or 0
      else
        bonus = data.bonus_plus2 == name
          and 2 or 0
      end
      local score = raw_score + bonus
      local modifier = abilities.get_modifier(score)

      local is_selected = ui.selector()
      ui.text("%s ", name:ljust(column1_length))

      local left_button
      if not is_disabled and raw_score > 8 then
        left_button = ui.text_button(" < ").is_clicked
          or is_selected and ui.keyboard("left")
      else
        ui.text("   ")
        left_button = false
      end

      ui.text("%02d", raw_score)

      local right_button
      if not is_disabled
        and raw_score < 15
        and xp.point_buy[raw_score + 1] - xp.point_buy[raw_score] <= data.points
      then
        right_button = ui.text_button(" > ").is_clicked
          or is_selected and ui.keyboard("right")
      else
        ui.text("   ")
        right_button = false
      end

      ui.text("+ %d = %02d  (%+d)", bonus, score, modifier)

      if left_button then
        data.points = data.points + (
          xp.point_buy[raw_score] - xp.point_buy[raw_score - 1]
        )
        data.abilities[codename] = raw_score - 1
      elseif right_button then
        data.points = data.points - (
          xp.point_buy[raw_score + 1] - xp.point_buy[raw_score]
        )
        data.abilities[codename] = raw_score + 1
      end
    ui.finish_line()
  end

  ui.start_line()
    ui.text("  %s    ", ("Очки:"):ljust(column1_length))
    ui.text("%02d", data.points)  -- NEXT color red on > 0
  ui.finish_line()

  ui.br()

  ui.start_line()
  ui.start_font(30)
    ui.selector()
    love.graphics.setColor(colors.white_dim)
      ui.text("## ")
    love.graphics.setColor(Vector.white)
    ui.text("Раса: ")
    ui.switch(RACES, data, "race", is_disabled)
  ui.finish_font()
  ui.finish_line()
  ui.br()

  ui.start_line()
    ui.selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_1", is_disabled, data.skill_2)
  ui.finish_line()

  ui.start_line()
    ui.selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_2", is_disabled, data.skill_1)
  ui.finish_line()

  if data.race == RACES[1] then
    ui.text("  +1 ко всем характеристикам")
  else
    if data.race == RACES[3] then
      ui.start_line()
        ui.selector()
        ui.text("+2: ")
        ui.switch(ABILITIES, data, "bonus_plus2", is_disabled)
      ui.finish_line()
    else
      ui.start_line()
        ui.selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_1", is_disabled, data.bonus_plus1_2)
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_2", is_disabled, data.bonus_plus1_1)
      ui.finish_line()
    end

    ui.br()
    ui.start_line()
      ui.selector()
      ui.text("Черта: ")
      ui.switch(FEATS, data, "feat", is_disabled)
    ui.finish_line()

    ui.start_frame(ui.get_font():getWidth("w") * 4)
      ui.text(FEAT_DESCRIPTIONS[Table.index_of(FEATS, data.feat)])
    ui.finish_frame()
  end
end

local draw_fighter_pane

--- @param self state_mode_creator
--- @param dt number
draw_pane = function(self, dt)
  local self_classes = self.model.classes

  local class_level = 0
  for i = self.pane_i, 1, -1 do
    if self_classes[i] == self_classes[self.pane_i] then
      class_level = class_level + 1
    end
  end

  ui.br()

  ui.start_line()
    ui.selector()
    ui.start_font(36)
      love.graphics.setColor(colors.white_dim)
        ui.text("## ")
      love.graphics.setColor(Vector.white)
      ui.text("Класс: ")
      ui.switch(CLASSES, self_classes, self.pane_i, is_disabled)
      ui.text("(уровень %s)", class_level)
    ui.finish_font()
  ui.finish_line()
  ui.br()

  local class_i = Table.index_of(CLASSES, self_classes[self.pane_i])
  if class_i == 1 then
    draw_fighter_pane(self, dt, self.pane_i, class_level)
  end
end

local FIGHTING_STYLES = Fun.iter(fighter.fighting_styles_list)
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

local start_icon_header = function(image, selector)
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

local finish_icon_header = function()
  ui.finish_font()
  ui.finish_line()
end

local description = function(fmt, ...)
  ui.start_frame(32 + ui.get_font():getWidth("w") * 3)
    ui.text(fmt, ...)
    local y = ui.get_frame().y
  ui.finish_frame()
  ui.get_frame().y = y
  ui.br()
end

draw_fighter_pane = function(self, dt, total_level, class_level)
  local codename = "fighter_" .. class_level
  if self.model.class_data[total_level].type ~= codename then
    self.model.class_data[total_level] = {type = codename}
  end
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

    start_icon_header(gui_elements.fighting_styles, true)
      ui.text("Боевой стиль:")
      ui.switch(FIGHTING_STYLES, class_data, "fighting_style", is_disabled)
    finish_icon_header()

    description(FS_DESCRIPTIONS[Table.index_of(FIGHTING_STYLES, class_data.fighting_style)])

    start_icon_header(gui_elements.second_wind)
      ui.text("Способность: Второе дыхание")
    finish_icon_header()

    local roll = fighter.second_wind:get_roll(self.model.total_level)
    description(
      "Раз за бой бонусным действием восстанавливает %d-%d здоровья",
      roll:min(), roll:max()
    )
  elseif class_level == 2 then
    start_icon_header(gui_elements.action_surge)
      ui.text("Способность: Всплеск действий")
    finish_icon_header()
    description("Раз за бой даёт одно дополнительное действие")
  elseif class_level == 3 then
    if not class_data.skill then
      class_data.skill = SAMURAI_SKILLS[1]
    end

    start_icon_header(gui_elements.fighting_spirit)
      ui.text("Способность: Боевой дух")
    finish_icon_header()
    description(
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

Ldump.mark(creator, {mt = "const"}, ...)
return creator
