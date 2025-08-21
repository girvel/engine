local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local load_menu = {}

--- @class state_mode_load_menu
--- @field type "load_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return state_mode_load_menu
load_menu.new = function(prev)
  return setmetatable({
    type = "load_menu",
    _prev = prev,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._prev:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._prev:draw_entity(...)
end

local PADDING = 40

methods.draw_gui = function(self, dt)
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
    ui.h1("Загрузить игру")

    local options = Kernel:list_saves()

    local n = ui.choice(options)
    local escape_pressed = ui.keyboard("escape")

    if n then
      Kernel:plan_load(options[n])
    end

    if n or escape_pressed then
      ui.handle_selection_reset()
      State.mode:close_menu()
    end
  ui.finish_frame()
end

Ldump.mark(load_menu, {}, ...)
return load_menu
