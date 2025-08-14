local ui = require("engine.tech.ui")


local start_menu = {}

--- @class state_mode_start_menu
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({
    
  }, mt)
end

methods.draw_gui = function()
  local choice = ui.choice({
    "New game",
    "Load game",
  })

  if choice == 1 then
    State.mode:start_game()
    Log.info("Start a new game")
  elseif choice == 2 then
    Log.info("Load a save")
  end
end

return Ldump.mark(start_menu, {}, ...)
