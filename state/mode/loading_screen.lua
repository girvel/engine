local ui = require("engine.tech.ui")


local loading_screen = {}

--- @class state_mode_loading_screen
--- @field _loading_coroutine thread
--- @field _next_state fun()
local methods = {}
local mt = {__index = methods}

--- @param loading_coroutine thread
--- @param next_state fun()
loading_screen.new = function(loading_coroutine, next_state)
  return setmetatable({
    _loading_coroutine = loading_coroutine,
    _next_state = next_state,
  }, mt)
end

methods.draw_gui = function(self)
  local t = love.timer.getTime()
  ui.text("." * (t % 4))
  coroutine.resume(self._loading_coroutine)
  if coroutine.status(self._loading_coroutine) == "dead" then
    self._next_state()
  end
end

return Ldump.mark(loading_screen, {}, ...)
