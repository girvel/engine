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
  :map(function(feat) return assert(translation.feats[feat]) end)
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

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  return setmetatable({
    type = "creator",
    _prev = prev,
    model = {
      abilities = abilities.new(8, 8, 8, 8, 8, 8),
      points = 27,
      race = RACES[1],
      skill_1 = SKILLS[1],
      skill_2 = SKILLS[2],
      bonus_plus1_1 = ABILITIES[1],
      bonus_plus1_2 = ABILITIES[2],
      bonus_plus2 = ABILITIES[1],
      feat = FEATS[1],
      classes = {},
      total_level = 3,
    },
    pane_i = 0,
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local draw_base_pane, draw_pane

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("n") then
    State.mode:close_menu()
  end

  if ui.keyboard("j") then
    State.mode:close_menu()
    State.mode:open_journal()
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
            if ui.text_button(" [%s] ", i).is_clicked then
              self.pane_i = i
            end
          end
        end
      ui.finish_line()
      ui.br()

      if self.pane_i == 0 then
        draw_base_pane(self, dt)
      else
        draw_pane(self, dt)
      end

      -- NEXT switches in the class pane
      -- NEXT finish the fighter class
      -- NEXT extract idioms

      -- NEXT active/inactive
      -- NEXT change icon
      -- NEXT select the first unset pane by default
      -- NEXT really highlight the updated creator
      -- NEXT highlight the updated journal
      -- NEXT task for never: setting to disable annoying highlights
      -- NEXT when warlock: kind of recognize the Nea
      -- NEXT distribute abilities randomly?

    ui.finish_font()
  tk.finish_window()
end

--- @param self state_mode_creator
--- @param dt number
draw_base_pane = function(self, dt)
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
      local name = translation.abilities[codename]
      local raw_score = self.model.abilities[codename]
      local bonus
      if self.model.race == RACES[1] then
        bonus = 1
      elseif self.model.race == RACES[2] then
        bonus = self.model.bonus_plus1_1 == name
          or self.model.bonus_plus1_2 == name
          and 1 or 0
      else
        bonus = self.model.bonus_plus2 == name
          and 2 or 0
      end
      local score = raw_score + bonus
      local modifier = abilities.get_modifier(score)

      local is_selected = ui.selector()
      ui.text("%s ", name:ljust(column1_length):utf_capitalize())

      local left_button
      if raw_score > 8 then
        left_button = ui.text_button(" < ").is_clicked
          or is_selected and ui.keyboard("left")
      else
        ui.text("   ")
        left_button = false
      end

      ui.text("%02d", raw_score)

      local right_button
      if raw_score < 15
        and xp.point_buy[raw_score + 1] - xp.point_buy[raw_score] <= self.model.points
      then
        right_button = ui.text_button(" > ").is_clicked
          or is_selected and ui.keyboard("right")
      else
        ui.text("   ")
        right_button = false
      end

      ui.text("+ %d = %02d  (%+d)", bonus, score, modifier)

      if left_button then
        self.model.points = self.model.points + (
          xp.point_buy[raw_score] - xp.point_buy[raw_score - 1]
        )
        self.model.abilities[codename] = raw_score - 1
      elseif right_button then
        self.model.points = self.model.points - (
          xp.point_buy[raw_score + 1] - xp.point_buy[raw_score]
        )
        self.model.abilities[codename] = raw_score + 1
      end
    ui.finish_line()
  end

  ui.start_line()
    ui.text("  %s    ", ("Очки:"):ljust(column1_length))
    ui.text("%02d", self.model.points)  -- NEXT color red on > 0
  ui.finish_line()

  ui.br()

  ui.start_line()
  ui.start_font(30)
    ui.selector()
    love.graphics.setColor(colors.white_dim)
      ui.text("## ")
    love.graphics.setColor(Vector.white)
    ui.text("Раса: ")
    ui.switch(RACES, self.model, "race")
  ui.finish_font()
  ui.finish_line()
  ui.br()

  ui.start_line()
    ui.selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, self.model, "skill_1", self.model.skill_2)
  ui.finish_line()

  ui.start_line()
    ui.selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, self.model, "skill_2", self.model.skill_1)
  ui.finish_line()

  if self.model.race == RACES[1] then
    ui.text("  +1 ко всем характеристикам")
  else
    if self.model.race == RACES[3] then
      ui.start_line()
        ui.selector()
        ui.text("+2: ")
        ui.switch(ABILITIES, self.model, "bonus_plus2")
      ui.finish_line()
    else
      ui.start_line()
        ui.selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, self.model, "bonus_plus1_1", self.model.bonus_plus1_2)
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, self.model, "bonus_plus1_2", self.model.bonus_plus1_1)
      ui.finish_line()
    end

    ui.br()
    ui.start_line()
      ui.selector()
      ui.text("Черта: ")
      ui.switch(FEATS, self.model, "feat")
    ui.finish_line()
    ui.br()
    ui.text("    %s", FEAT_DESCRIPTIONS[Table.index_of(FEATS, self.model.feat)])
  end
end

local CLASSES_DATA = {
  fighter,
}

local CLASSES = Fun.iter(CLASSES_DATA)
  :map(function(cls) return assert(translation.classes[cls.codename]):utf_capitalize() end)
  :totable()

local draw_fighter_pane

--- @param self state_mode_creator
--- @param dt number
draw_pane = function(self, dt)
  local self_classes = self.model.classes
  if not self_classes[self.pane_i] then
    self_classes[self.pane_i] = self_classes[self.pane_i - 1] or CLASSES[1]
  end

  local class_level = 0
  for i = self.pane_i, 1, -1 do
    if self_classes[i] == self_classes[self.pane_i] then
      class_level = class_level + 1
    end
  end

  ui.start_line()
  ui.start_font(30)
    ui.selector()
    love.graphics.setColor(colors.white_dim)
      ui.text("## ")
    love.graphics.setColor(Vector.white)
    ui.text("Класс: ")
    ui.switch(CLASSES, self_classes, self.pane_i)  -- NEXT hide switch buttons if # == 1
    ui.text("(уровень %s)", class_level)
  ui.finish_font()
  ui.finish_line()
  ui.br()

  local class_i = Table.index_of(CLASSES, self_classes[self.pane_i])
  if class_i == 1 then
    draw_fighter_pane(self, dt, self.pane_i, class_level)
  end
end

draw_fighter_pane = function(self, dt, total_level, class_level)
  local con_mod = abilities.get_modifier(self.model.abilities.con)
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
    ui.start_line()
      ui.text("  ")
      ui.image(gui_elements.second_wind, 2)

      ui.start_font(28)
      ui.start_alignment("left", "bottom")
      ui.start_frame(nil, nil, nil, gui_elements.second_wind:getHeight() * 2)
        ui.text(" Второе дыхание")
      ui.finish_frame()
      ui.finish_alignment()
      ui.finish_font()
    ui.finish_line()
    ui.br()

    ui.start_frame(ui.get_font():getWidth("w") * 4)
      local roll = fighter.second_wind:get_roll(self.model.total_level)
      ui.text("Бонусным действием раз за бой восстанавливает %d-%d здоровья", roll:min(), roll:max())
    ui.finish_frame(true)
  end
end

Ldump.mark(creator, {mt = "const"}, ...)
return creator
