local mode = {}

--- @enum (key) state_mode_name
local STATES = {
  state_menu = require("engine.state.mode.start_menu"),
  game = require("engine.state.mode.game"),
  loading_screen = require("engine.state.mode.loading_screen"),
}

--- @class state_mode
--- @field _mode state_mode_name
local methods = {
  draw_gui = function(self)
    return STATES[self._mode].draw_gui()
  end,

  --- @param mode state_mode_name
  transition = function(self, mode)
    self._mode = mode
  end,
}

local mt = {__index = methods}

mode.new = function()
  return setmetatable({
    _mode = "state_menu",
  }, mt)
end

return Ldump.mark(mode, {}, ...)
