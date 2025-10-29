local colors = require("engine.tech.colors")
local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local exit_confirmation = {}

--- @class state_mode_exit_confirmation
--- @field type "exit_confirmation"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @return state_mode_exit_confirmation
exit_confirmation.new = function(prev)
  return setmetatable({
    type = "exit_confirmation",
    _prev = prev,
  }, mt)
end

methods.draw_entity = function(self, ...)
  if self._prev.draw_entity then
    self._prev:draw_entity(...)
  end
end

methods.draw_gui = function(self)
  local W = 470
  local H = 160

  if self._prev.has_saved == false then
    H = H + 60
  end

  tk.start_window("center", "center", W, H)
  ui.start_font(28)
  ui.start_alignment("center")
    ui.text("Вы действительно хотите выйти из игры?")
    ui.br()

    if self._prev.has_saved == false then
      love.graphics.setColor(colors.red)
      ui.text("Игра не сохранена")
      ui.br()
      love.graphics.setColor(Vector.white)
    end

    local n = ui.choice({
      "Вернуться  ",
      "Выйти из игры  ",
    })

    if n == 1 or ui.keyboard("escape") then
      State.mode:close_menu()
    elseif n == 2 then
      Log.info("Exiting the game from escape menu")
      love.event.quit()
    end
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end


Ldump.mark(exit_confirmation, {}, ...)
return exit_confirmation
