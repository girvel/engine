local ui = require("engine.tech.ui")


local start_menu = {}

--- @class state_mode_start_menu
--- @field type "start_menu"
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({
    type = "start_menu",
  }, mt)
end

methods.draw_gui = function()
  ui.start_font(48)
  ui.start_frame(200, 200)
    local choice = ui.choice({
      "Новая игра",
      "Загрузить игру",
      "Выход",
    })

    if choice then
      ui.handle_selection_reset()
    end

    if choice == 1 then
      State.mode:start_game()
    elseif choice == 2 then
      Log.info("Load a save")
    elseif choice == 3 then
      Log.info("Exiting from the main menu")
      love.event.quit()
    end
  ui.finish_frame()
  ui.finish_font()
end

Ldump.mark(start_menu, {}, ...)
return start_menu
