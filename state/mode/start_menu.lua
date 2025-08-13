local ui = require("engine.tech.ui")


local start_menu = {}

start_menu.draw_gui = function()
  local choice = ui.choice({
    "New game",
    "Load game",
  })

  if choice == 1 then
    State.mode:transition("loading_screen")
    Log.info("Start a new game")
  elseif choice == 2 then
    Log.info("Load a save")
  end
end

return Ldump.mark(start_menu, {}, ...)
