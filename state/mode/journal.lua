local ui = require("engine.tech.ui")
local gui_elements = require("engine.state.mode.gui_elements")


local journal = {}

--- @class state_mode_journal
--- @field type "journal"
--- @field _game state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param game state_mode_game
--- @return state_mode_journal
journal.new = function(game)
  return setmetatable({
    type = "journal",
    _game = game,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._game:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._game:draw_entity(...)
end

local PADDING = 40

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("j") then
    State.mode:close_journal()
  end

  local w = math.min(love.graphics.getWidth() - 4 * PADDING, 800)
  local h = love.graphics.getHeight() - 4 * PADDING

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2 - PADDING,
    (love.graphics.getHeight() - h) / 2 - PADDING,
    w + 2 * PADDING,
    h + 2 * PADDING
  )
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2,
    (love.graphics.getHeight() - h) / 2,
    w, h
  )
    ui.text("Lorem ipsum")
  ui.finish_frame()
end

Ldump.mark(journal, {}, ...)
return journal
