local animated = require("engine.tech.animated")
local async = require("engine.tech.async")
local ui = require("engine.tech.ui")


local loading_screen = {}

--- @class state_mode_loading_screen
--- @field type "loading_screen"
--- @field _loading_coroutine thread
--- @field _next_state fun()
local methods = {}
local mt = {__index = methods}

--- @param loading_coroutine thread
--- @param next_state fun()
loading_screen.new = function(loading_coroutine, next_state)
  return setmetatable({
    type = "loading_screen",
    _loading_coroutine = loading_coroutine,
    _next_state = next_state,
  }, mt)
end

local INDICATOR_LENGTH = 20

local bar_animation = animated.mixin("engine/assets/sprites/gui/loading_bar", "no_atlas").animation.pack.second

methods.draw_gui = function(self)
  local progress = math.max(1, math.ceil((async.resume(self._loading_coroutine) or 1) * #bar_animation))

  ui.start_alignment("center")
  ui.start_frame(nil, love.graphics.getHeight() * 4 / 5)
    ui.image(bar_animation[progress].image)
  ui.finish_frame()
  ui.finish_alignment()

  if coroutine.status(self._loading_coroutine) == "dead" then
    self._next_state()
  end
end

Ldump.mark(loading_screen, {}, ...)
return loading_screen
