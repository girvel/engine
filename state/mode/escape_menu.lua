local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local escape_menu = {}

--- @class state_mode_escape_menu
--- @field type "escape_menu"
--- @field has_saved boolean
--- @field _prev state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_escape_menu
escape_menu.new = function(prev)
  return setmetatable({
    type = "escape_menu",
    has_saved = false,
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
  local W = 320
  local H = 140

  tk.start_window("center", "center", W, H)
  ui.start_font(36)
    local n = ui.choice({
      "Продолжить",
      "Сохранить игру",
      "Загрузить игру",
      "Выход",
    })

    local escape_pressed = ui.keyboard("escape") and not self._display_confirmation

    if n or escape_pressed then
      ui.handle_selection_reset()
    end

    if n == 1 or escape_pressed then
      State.mode:close_menu()
    elseif n == 2 then
      State.mode:open_save_menu()
    elseif n == 3 then
      State.mode:open_load_menu()
    elseif n == 4 then
      State.mode:attempt_exit()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(escape_menu, {}, ...)
return escape_menu
