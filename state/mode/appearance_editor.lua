local items_entities = require("levels.main.palette.items_entities")
local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local HAIR_TYPES = {
  {codename = "none", name = "Лысый"},
  {codename = "short_hair_1", name = "Короткие (1)"},
  {codename = "short_hair_2", name = "Короткие (2)"},
  {codename = "short_hair_3", name = "Короткие (3)"},
}

local HAIR_COLORS = {
  {codename = "red", name = "Рыжий"},
  {codename = "gray", name = "Седеющий"},
  {codename = "brown", name = "Русый"},
}
-- NEXT same idiom for abilities in creator

local appearance_editor = {}

--- @class state_mode_appearance_editor
--- @field type "appearance_editor"
--- @field _prev state_mode_game
--- @field model table
local methods = {}
appearance_editor.mt = {__index = methods}

--- @return state_mode_appearance_editor
appearance_editor.new = function(prev)
  return setmetatable({
    type = "appearance_editor",
    _prev = prev,
    model = {
      hair_type = HAIR_TYPES[1],
      hair_color = HAIR_COLORS[2],
    },
  }, appearance_editor.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  tk.start_window("center", "center", 780, 700)
    ui.h1("Внешность")

    local context = ui.get_context()
    tk.draw_entity(State.player, context.cursor_x, context.cursor_y, 16)

    ui.start_frame(256)
    ui.start_font(24)
      ui.start_line()
        ui.selector()
        ui.text("Тип волос:")
        local hair_type_changed = ui.switch(HAIR_TYPES, self.model, "hair_type")
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("Цвет волос:")
        local hair_color_changed = ui.switch(HAIR_COLORS, self.model, "hair_color")
      ui.finish_line()
    ui.finish_font()
    ui.finish_frame()

    if hair_type_changed or hair_color_changed then
      local inventory = State.player.inventory
      local hair_type = self.model.hair_type.codename
      local hair_color = self.model.hair_color.codename

      if inventory.hair then
        State:remove(inventory.hair, true)
      end
      inventory.hair = hair_type ~= "none"
        and State:add(items_entities.hair(hair_type, hair_color))
        or nil
    end
  tk.finish_window()
end

Ldump.mark(appearance_editor, {mt = "const"}, ...)
return appearance_editor
