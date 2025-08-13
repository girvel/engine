local display = {}

--- @enum (key) state_display_mode
local STATES = {
  state_menu = require("engine.state.display.start_menu"),
  game = require("engine.state.display.game"),
}

--- @class state_display
--- @field _mode state_display_mode
local methods = {
  gui = function(self)
    return STATES[self._mode].gui()
  end,

  --- @param mode state_display_mode
  transition = function(self, mode)
    self._mode = mode
  end,
}

local mt = {__index = methods}

display.new = function()
  return setmetatable({
    _mode = "state_menu",
  }, mt)
end

return Ldump.mark(display, {}, ...)
