local ui = require("engine.tech.ui")


local start_menu = {}

start_menu.draw_gui = function()
  local choice = ui.choice({
    "New game",
    "Load game",
  })

  if choice == 1 then
    State:add {
      sprite = {
        image = love.graphics.newImage("engine/assets/sprites/moose_dude.png"),
      },
      position = V(64, 64),
    }
    State.mode:transition("game")
    Log.info("Start a new game")
  elseif choice == 2 then
    Log.info("Load a save")
  end
end

return Ldump.mark(start_menu, {}, ...)
