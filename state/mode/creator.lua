local races = require("engine.mech.races")
local class = require("engine.mech.class")
local feats = require("engine.mech.class.feats")
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
--- @field is_disabled boolean
local methods = {}
creator.mt = {__index = methods}

local ABILITIES = Fun.iter(abilities.list)
  :map(function(ability) return assert(translation.abilities[ability]):utf_capitalize() end)
  :totable()

local SKILLS = Fun.iter(abilities.skill_bases)
  :map(function(skill) return class.skill_proficiency(skill) end)
  :totable()
table.sort(SKILLS, function(a, b) return a.name < b.name end)

local FEATS = Fun.pairs(feats)
  :map(function(k, v) return v end)
  :totable()
table.sort(FEATS, function(a, b) return a.name < b.name end)

local RACES = {
  races.human,
  races.variant_human,
  races.custom_lineage,
}

local CLASSES = {
  fighter,
}

local CREATOR_CLASSES = Table.do_folder("engine/state/mode/creator_classes")

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  ui.handle_selection_reset()
  local current_level = State.player.level

  local total_level, pane_i do
    total_level = current_level
    local xp_remains = State.player.xp
    while true do
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
        classes = {},
        pane_data = {
          [0] = {
            abilities = State.debug
              and abilities.new(15, 15, 15, 8, 8, 8)
              or abilities.new(8, 8, 8, 8, 8, 8),
            points = State.debug and 0 or 27,
            race = RACES[1],
            skill_1 = SKILLS[1],
            skill_2 = SKILLS[2],
            bonus_plus1_1 = ABILITIES[1],
            bonus_plus1_2 = ABILITIES[2],
            bonus_plus2 = ABILITIES[1],
            feat = FEATS[1],
          },
        },
        total_level = total_level,
      }
    end

    for i = 1, total_level - current_level do
      local this_class = model.classes[current_level] or CLASSES[1]
      model.classes[current_level + i] = this_class
      model.pane_data[current_level + i] = CREATOR_CLASSES[this_class.codename].init_data(current_level + i, current_level + i)
      -- NEXT doesn't consider multiclassing; counting the level of this class is so repetitive; maybe it's better to 
    end
  end

  return setmetatable({
    type = "creator",
    _prev = prev,
    model = model,
    pane_i = pane_i,
    is_disabled = model.total_level <= State.player.level,
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local draw_base_pane, draw_pane, submit

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("n") then
    State.mode:close_menu()
  end

  if ui.keyboard("j") then
    State.mode:close_menu()
    State.mode:open_journal()
  end

  if not self.is_disabled and ui.keyboard("return") then
    if self.model.pane_data[0].points > 0 then
      State.mode:show_confirmation(
        "Редактирование персонажа не закончено: не все очки способностей израсходованы"
      )
    else
      State.mode:confirm(
        "Закончить создание персонажа?",
        function() submit(self) end
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

      -- NEXT LSP for model
      -- NEXT no submit for inactive creator

    ui.finish_font()
  tk.finish_window()
end

--- @param self state_mode_creator
--- @param dt number
draw_base_pane = function(self, dt)
  local data = self.model.pane_data[0]
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

  for _, ability_name in ipairs(abilities.list) do
    ui.start_line()
      local name = translation.abilities[ability_name]:utf_capitalize()
      local raw_score = data.abilities[ability_name]
      local bonus = self:get_bonus(ability_name)
      local score = raw_score + bonus
      local modifier = abilities.get_modifier(score)

      local is_selected = self:selector()
      ui.text("%s ", name:ljust(column1_length))

      local left_button
      if not self.is_disabled and raw_score > 8 then
        left_button = ui.text_button(" < ").is_clicked
          or is_selected and ui.keyboard("left")
      else
        ui.text("   ")
        left_button = false
      end

      ui.text("%02d", raw_score)

      local right_button
      if not self.is_disabled
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
        data.abilities[ability_name] = raw_score - 1
      elseif right_button then
        data.points = data.points - (
          xp.point_buy[raw_score + 1] - xp.point_buy[raw_score]
        )
        data.abilities[ability_name] = raw_score + 1
      end
    ui.finish_line()
  end

  ui.start_line()
    ui.text("  %s    ", ("Очки:"):ljust(column1_length))
    if data.points > 0 then
      love.graphics.setColor(colors.red)
    end
    ui.text("%02d", data.points)
    if data.points > 0 then
      love.graphics.setColor(Vector.white)
    end
  ui.finish_line()

  ui.br()

  ui.start_line()
  ui.start_font(30)
    self:selector()
    love.graphics.setColor(colors.white_dim)
      ui.text("## ")
    love.graphics.setColor(Vector.white)
    ui.text("Раса: ")
    self:switch(RACES, "race")
  ui.finish_font()
  ui.finish_line()
  ui.br()

  ui.start_line()
    self:selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_1", self.is_disabled, data.skill_2)
  ui.finish_line()

  ui.start_line()
    self:selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_2", self.is_disabled, data.skill_1)
  ui.finish_line()

  if data.race == races.human then
    ui.text("  +1 ко всем характеристикам")
  else
    if data.race == races.custom_lineage then
      ui.start_line()
        self:selector()
        ui.text("+2: ")
        ui.switch(ABILITIES, data, "bonus_plus2", self.is_disabled)
      ui.finish_line()
    else
      ui.start_line()
        self:selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_1", self.is_disabled, data.bonus_plus1_2)
      ui.finish_line()

      ui.start_line()
        self:selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_2", self.is_disabled, data.bonus_plus1_1)
      ui.finish_line()
    end

    ui.br()
    ui.start_line()
      self:selector()
      ui.text("Черта: ")
      ui.switch(FEATS, data, "feat", self.is_disabled)
    ui.finish_line()

    local description = data.feat.description
    if description then
      ui.start_frame(ui.get_font():getWidth("w") * 4)
        ui.text(description)
      ui.finish_frame()
    end
  end
end

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
    self:selector()
    ui.start_font(36)
      love.graphics.setColor(colors.white_dim)
        ui.text("## ")
      love.graphics.setColor(Vector.white)
      ui.text("Класс: ")
      ui.switch(CLASSES, self_classes, self.pane_i, self.is_disabled)
      ui.text("(уровень %s)", class_level)
    ui.finish_font()
  ui.finish_line()
  ui.br()

  local codename = self_classes[self.pane_i].codename
  -- TODO here was class switching logic

  CREATOR_CLASSES[codename].draw_pane(self, dt, self.is_disabled, self.pane_i, class_level)
end

--- @param self state_mode_creator
submit = function(self)
  local perks do
    local data = self.model.pane_data[0]
    perks = {
      data.skill_1,
      data.skill_2,
    }

    if data.race ~= races.human then
      table.insert(perks, data.feat)
    end
  end

  local class_levels = {}
  for i = 1, self.model.total_level do
    local codename = self.model.classes[i].codename
    class_levels[codename] = (class_levels[codename] or 0) + 1
    Table.concat(perks, CREATOR_CLASSES[codename].submit(self, i, class_levels[codename]))
  end

  local mixin = {
    level = self.model.total_level,
    xp = State.player.xp - xp.for_level[self.model.total_level] + xp.for_level[State.player.level],
    perks = perks,
    creator_model = self.model,
    base_abilities = self.model.pane_data[0].abilities,
  }
  Log.info("Submitting a character build: %s", mixin)
  Table.extend(State.player, mixin)
  State.player:rest("full")
  State.mode:close_menu()
end

--- @param possible_values any[]
--- @param key any
--- @param group? string
methods.switch = function(self, possible_values, key, group)
  local container = self.model.pane_data[self.pane_i]
  ui.switch(possible_values, container, key, self.is_disabled)
end

methods.selector = function(self)
  if self.is_disabled then
    ui.text("  ")
    return false
  else
    return ui.selector()
  end
end

methods.start_ability = function(self, image, selector)
  ui.start_line()
  if selector then
    self:selector()
  else
    ui.text("  ")
  end
  ui.image(image, 2)
  ui.start_font(32)
  ui.text(" ")
end

methods.finish_ability = function(self, fmt, ...)
  ui.finish_font()
  ui.finish_line()

  ui.start_frame(32 + ui.get_font():getWidth("w") * 3)
    ui.text(fmt, ...)
    local y = ui.get_frame().y
  ui.finish_frame()
  ui.get_frame().y = y
  ui.br()
end

--- @param ability ability
methods.get_bonus = function(self, ability)
  local name = translation.abilities[ability]:utf_capitalize()
  local data = self.model.pane_data[0]
  if data.race == races.human then
    return 1
  elseif data.race == races.variant_human then
    return (data.bonus_plus1_1 == name or data.bonus_plus1_2 == name)
      and 1 or 0
  else
    return data.bonus_plus2 == name and 2 or 0
  end
end


Ldump.mark(creator, {mt = "const"}, ...)
return creator
