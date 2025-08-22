local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local save_menu = {}

--- @class state_mode_save_menu
--- @field type "save_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return state_mode_save_menu
save_menu.new = function(prev)
  return setmetatable({
    type = "save_menu",
    _prev = prev,
  }, mt)
end

methods.draw_grid = function(self, ...)
  if self._prev.draw_grid then
    self._prev:draw_grid(...)
  end
end

methods.draw_entity = function(self, ...)
  if self._prev.draw_entity then
    self._prev:draw_entity(...)
  end
end

methods.draw_gui = function(self, dt)
  tk.start_window("center", "center", "read_max", "max")
  ui.start_font(24)
    ui.h1("Сохранить игру")

    local options = Kernel:list_saves()
    table.insert(options, 1, "<новое сохранение>")

    local n = ui.choice(options)
    local escape_pressed = ui.keyboard("escape")

    if n == 1 then
      Kernel:plan_save("save_" .. os.date("%Y-%m-%d_%H-%M-%S"))
    elseif n then
      Kernel:plan_save(options[n])
    end

    if n and self._prev.type == "escape_menu" then
      self._prev.has_saved = true
    end

    if n or escape_pressed then
      ui.handle_selection_reset()
      State.mode:close_menu()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(save_menu, {}, ...)
return save_menu
