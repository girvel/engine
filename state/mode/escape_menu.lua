local tk = require("state.mode.tk")
local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local escape_menu = {}

--- @class state_mode_escape_menu
--- @field type "escape_menu"
--- @field _prev state_mode_game
--- @field _display_confirmation boolean
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_escape_menu
escape_menu.new = function(prev)
  return setmetatable({
    type = "escape_menu",
    _prev = prev,
    _display_confirmation = false,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._prev:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._prev:draw_entity(...)
end

methods.draw_gui = function(self, dt)
  if self._display_confirmation then
    self:render_confirmation()
  else
    self:render_menu()
  end
end

methods.render_menu = function(self)
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
      self._display_confirmation = true
    end
  ui.finish_font()
  tk.finish_window()
end

methods.render_confirmation = function(self)
  local W = 470
  local H = 160

  tk.start_window("center", "center", W, H)
  ui.start_font(28)
    ui.start_alignment("center")
      ui.text("Вы действительно хотите выйти из игры?")
      ui.br()
      local n = ui.choice({
        "Вернуться  ",
        "Выйти из игры  ",
      })
    ui.finish_alignment()

    if n == 1 then
      self._display_confirmation = false
    elseif n == 2 then
      -- NEXT (save/load) make sure the game is saved
      Log.info("Exiting the game from escape menu")
      love.event.quit()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(escape_menu, {}, ...)
return escape_menu
