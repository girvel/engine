local animated = require("engine.tech.animated")
local level    = require("engine.tech.level")
local sound    = require("engine.tech.sound")

local mode = {}

local STATES = {
  start_menu = require("engine.state.mode.start_menu"),
  game = require("engine.state.mode.game"),
  loading_screen = require("engine.state.mode.loading_screen"),
  escape_menu = require("engine.state.mode.escape_menu"),
  journal = require("engine.state.mode.journal"),
  save_menu = require("engine.state.mode.save_menu"),
  load_menu = require("engine.state.mode.load_menu"),
  death = require("engine.state.mode.death"),
  exit_confirmation = require("engine.state.mode.exit_confirmation"),
  ending = require("engine.state.mode.ending"),
}

local OPEN_JOURNAL = sound.multiple("engine/assets/sounds/open_journal", .3)
local CLOSE_JOURNAL = sound.multiple("engine/assets/sounds/close_journal", 1)

local empty_f = function() end

--- @class state_mode
--- @field _mode table
local methods = {}
mode.mt = {__index = methods}

methods._set_mode = function(self, mode_value)
  self._mode = mode_value

  for _, id in ipairs {"draw_gui", "draw_entity", "preprocess", "postprocess"} do
    self[id] = mode_value[id] and Ldump.ignore_upvalue_size(function(_, ...)
      return mode_value[id](mode_value, ...)
    end) or empty_f
  end
end

methods.draw_gui = function(self, dt)
  Error("No State.mode._mode is set")
end

methods.draw_entity = function(self, entity, dt)
  Error("No State.mode._mode is set")
end

methods.preprocess = function(self, entity, dt)
  Error("No State.mode._mode is set")
end

methods.postprocess = function(self, entity, dt)
  Error("No State.mode._mode is set")
end

methods.start_game = function(self)
  -- TODO switch modes between frames, not in the middle
  assert(self._mode.type == "start_menu")
  Log.info("Starting new game...")
  self:_set_mode(STATES.loading_screen.new(
    coroutine.create(function() return State:load_level("levels/main") end),
    function() return self:start_game_finish() end
  ))
end

methods.start_game_finish = function(self)
  assert(self._mode.type == "loading_screen")
  Log.info("Game started")
  self:_set_mode(STATES.game.new())
end

methods.open_escape_menu = function(self)
  Log.info("Opening escape menu")
  self:_set_mode(STATES.escape_menu.new(self._mode --[[@as state_mode_game]]))
end

methods.open_journal = function(self)
  Log.info("Opening journal")
  self:_set_mode(STATES.journal.new(self._mode --[[@as state_mode_game]]))
  OPEN_JOURNAL:play()
end

methods.open_save_menu = function(self)
  Log.info("Opening save menu")
  self:_set_mode(STATES.save_menu.new(self._mode))
end

methods.open_load_menu = function(self)
  Log.info("Opening load menu")
  self:_set_mode(STATES.load_menu.new(self._mode))
end

methods.close_menu = function(self)
  Log.info("Closing %s", self._mode.type)
  if self._mode.type == "journal" then
    CLOSE_JOURNAL:play()
  end
  self:_set_mode(assert(self._mode._prev))
end

methods.player_has_died = function(self)
  self:_set_mode(STATES.death.new())
  level.remove(State.player)
  State.player:rotate(Vector.left)
  animated.change_pack(State.player, "engine/assets/sprites/animations/skeleton")
end

methods.to_start_screen = function(self)
  assert(self._mode.type == "death" or self._mode.type == "ending")
  self:_set_mode(STATES.start_menu.new())
  State:reset()
end

methods.ending = function(self, is_good)
  self:_set_mode(STATES.ending.new(is_good))
end

--- @return boolean ok false if already in confirmation menu
methods.attempt_exit = function(self)
  if self._mode.type == "exit_confirmation" then
    return false
  end
  self:_set_mode(STATES.exit_confirmation.new(self._mode))
  return true
end

mode.new = function()
  local result = setmetatable({}, mode.mt)
  result:_set_mode(STATES.start_menu.new())
  return result
end

Ldump.mark(mode, {mt = "const"}, ...)
return mode
