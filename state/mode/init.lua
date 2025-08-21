local mode = {}

local STATES = {
  start_menu = require("engine.state.mode.start_menu"),
  game = require("engine.state.mode.game"),
  loading_screen = require("engine.state.mode.loading_screen"),
  escape_menu = require("engine.state.mode.escape_menu"),
  journal = require("engine.state.mode.journal"),
}

--- @class state_mode
--- @field _mode table
local methods = {
  draw_gui = function(self, dt)
    return -Query(self._mode):draw_gui(dt)
  end,

  draw_entity = function(self, entity, dt)
    return -Query(self._mode):draw_entity(entity, dt)
  end,

  draw_grid = function(self, entity, dt)
    return -Query(self._mode):draw_grid(entity, dt)
  end,

  start_game = function(self)
    -- TODO switch modes between frames, not in the middle
    assert(self._mode.type == "start_menu")
    Log.info("Starting new game...")
    self._mode = STATES.loading_screen.new(
      coroutine.create(Fn.curry(State.load_level, State, "levels.main")),
      Fn.curry(self.start_game_finish, self)
    )
  end,

  start_game_finish = function(self)
    assert(self._mode.type == "loading_screen")
    Log.info("Game started")
    self._mode = STATES.game.new()
  end,

  open_escape_menu = function(self)
    assert(self._mode.type == "game")
    Log.info("Opening escape menu")
    self._mode = STATES.escape_menu.new(self._mode --[[@as state_mode_game]])
  end,

  close_escape_menu = function(self)
    assert(self._mode.type == "escape_menu")
    Log.info("Closing escape menu")
    self._mode = self._mode._game
  end,

  open_journal = function(self)
    assert(self._mode.type == "game")
    Log.info("Opening journal")
    self._mode = STATES.journal.new(self._mode --[[@as state_mode_game]])
  end,

  close_journal = function(self)
    assert(self._mode.type == "journal")
    Log.info("Closing journal")
    self._mode = self._mode._game
  end,
}

local mt = {__index = methods}

mode.new = function()
  return setmetatable({
    _mode = STATES.start_menu.new(),
  }, mt)
end

Ldump.mark(mode, {}, ...)
return mode
