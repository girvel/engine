local ui = require("engine.tech.ui")


local start_menu = {}

--- @class state_mode_start_menu
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({}, mt)
end

methods.draw_gui = function()
  ui.font_size(48)

  ui.rect(100, 100)
  local choice = ui.choice({
    "New game",
    "Load game",
  })

  if choice == 1 then
    State.mode:start_game()
  elseif choice == 2 then
    Log.info("Load a save")
  end
end

Ldump.mark(start_menu, {}, ...)
return start_menu
