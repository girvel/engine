local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local tk = {}

local PADDING = 40
local MAX_READABLE_W = 800

--- @param x integer|"center"
--- @param y integer|"center"
--- @param w integer|"max"|"read_max"
--- @param h integer|"max"
tk.start_window = function(x, y, w, h)
  assert(x == "center")
  assert(y == "center")

  --- @cast w integer
  if w == "max" then
    w = love.graphics.getWidth() - 4 * PADDING
  elseif w == "read_max" then
    w = math.max(love.graphics.getWidth() - 4 * PADDING, MAX_READABLE_W)
  end

  --- @cast h integer
  if h == "max" then
    h = love.graphics.getHeight() - 4 * PADDING
  end

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
end

tk.finish_window = function()
  ui.finish_frame()
end

Ldump.mark(tk, {}, ...)
return tk
