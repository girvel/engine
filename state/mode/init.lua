local mode = {}

local STATES = {
  start_menu = require("engine.state.mode.start_menu"),
  game = require("engine.state.mode.game"),
  loading_screen = require("engine.state.mode.loading_screen"),
}

--- @class state_mode
--- @field _mode table
local methods = {
  draw_gui = function(self)
    return -Query(self._mode):draw_gui()
  end,

  draw_entity = function(self, entity)
    return -Query(self._mode):draw_entity(entity)
  end,

  draw_grid = function(self, entity)
    return -Query(self._mode):draw_grid(entity)
  end,

  start_game = function(self)
    Log.info("Starting new game...")
    self._mode = STATES.loading_screen.new(
      coroutine.create(Fn.curry(State.load_level, State, "levels.main")),
      Fn.curry(self.start_game_finish, self)
    )
  end,

  start_game_finish = function(self)
    Log.info("Game started")
    self._mode = STATES.game.new()
  end,
}

local mt = {__index = methods}

mode.new = function()
  return setmetatable({
    _mode = STATES.start_menu.new(),
  }, mt)
end

return Ldump.mark(mode, {}, ...)
