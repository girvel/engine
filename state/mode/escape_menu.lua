local gui_elements = require("engine.state.mode.game.gui_elements")
local ui = require("engine.tech.ui")


local escape_menu = {}

--- @class state_mode_escape_menu
--- @field type "escape_menu"
--- @field _game state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param game state_mode_game
--- @return state_mode_escape_menu
escape_menu.new = function(game)
  return setmetatable({
    type = "escape_menu",
    _game = game,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._game:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._game:draw_entity(...)
end

local W = 300
local H = 600
local PADDING = 40

methods.draw_gui = function(self, dt)
  ui.start_frame(
    (love.graphics.getWidth() - W) / 2 - PADDING,
    (love.graphics.getHeight() - H) / 2 - PADDING,
    W + 2 * PADDING,
    H + 2 * PADDING
  )
    ui.tile(gui_elements.sidebar_bg)
  ui.finish_frame()

  ui.start_frame(
    (love.graphics.getWidth() - W) / 2,
    (love.graphics.getHeight() - H) / 2,
    W, H
  )
    ui.text("Lorem ipsum dolor asdf ewnksl asdifojne")
  ui.finish_frame()
end

Ldump.mark(escape_menu, {}, ...)
return escape_menu
