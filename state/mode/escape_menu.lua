local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local escape_menu = {}

--- @class state_mode_escape_menu
--- @field type "escape_menu"
--- @field _prev state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_escape_menu
escape_menu.new = function(prev)
  return setmetatable({
    type = "escape_menu",
    _prev = prev,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._prev:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._prev:draw_entity(...)
end

local W = 240
local H = 140
local PADDING = 40

methods.draw_gui = function(self, dt)
  ui.start_frame(
    (love.graphics.getWidth() - W) / 2 - PADDING,
    (love.graphics.getHeight() - H) / 2 - PADDING,
    W + 2 * PADDING,
    H + 2 * PADDING
  )
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(
    (love.graphics.getWidth() - W) / 2,
    (love.graphics.getHeight() - H) / 2,
    W, H
  )
  ui.start_font(36)
    local n = ui.choice({
      "Continue",
      "Save game",
      "Load game",
      "Exit game",
    })

    local escape_pressed = ui.keyboard("escape")

    if n or escape_pressed then
      ui.handle_selection_reset()
    end

    if n == 1 or escape_pressed then
      State.mode:close_menu()
    elseif n == 2 then
      -- NEXT (save/load)
      State.mode:open_save_menu()
    elseif n == 3 then
      -- NEXT (save/load)
      Kernel:plan_load("test")
    elseif n == 4 then
      -- NEXT (save/load) make sure the game is saved
      Log.info("Exiting the game from escape menu")
      love.event.quit()
    end
  ui.finish_font()
  ui.finish_frame()
end

Ldump.mark(escape_menu, {}, ...)
return escape_menu
