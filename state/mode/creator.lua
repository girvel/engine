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

local ABILITIES = Fun.iter(abilities.set)
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
    },
    pane_i = 0,
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local draw_base_pane

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
            self.pane_i = (self.pane_i - 1) % 3
          end

          if ui.keyboard("right") then
            self.pane_i = (self.pane_i + 1) % 3
          end
        end

        ui.text("Уровень: ")
        for i = 0, 2 do
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
      end

      -- NEXT change abilities
      -- NEXT on panes 1+ select a class
      -- NEXT delegate pane to the class
      -- NEXT active/inactive
      -- NEXT select the first unset pane by default
      -- NEXT really highlight the updated creator
      -- NEXT highlight the updated journal
      -- NEXT task for never: setting to disable annoying highlights
      -- NEXT change icon
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

  for codename in pairs(abilities.set) do
    ui.start_line()
      local name = translation.abilities[codename]
      local raw_score = self.model.abilities[codename]
      local bonus = 0
      local score = raw_score + bonus
      local modifier = abilities.get_modifier(score)

      ui.selector()
      ui.text("%s ", name:ljust(column1_length):utf_capitalize())
      ui.text_button(" < ")
      ui.text("%02d", raw_score)
      ui.text_button(" > ")
      ui.text("+ %d = %02d  (%d)", bonus, score, modifier)
    ui.finish_line()
  end

  ui.start_line()
    ui.text("  %s    ", ("Очки:"):ljust(column1_length))
    ui.text("%02d", self.model.points)
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

Ldump.mark(creator, {mt = "const"}, ...)
return creator
