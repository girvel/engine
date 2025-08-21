local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local save_menu = {}

--- @class state_mode_save_menu
--- @field type "save_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return state_mode_save_menu
save_menu.new = function(prev)
  return setmetatable({
    type = "save_menu",
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
    local options = Kernel:list_saves()
    table.insert(options, 1, "<новое сохранение>")

    local n = ui.choice(options)
    local escape_pressed = ui.keyboard("escape")

    if n == 1 then
      Kernel:plan_save("save_" .. #options)
    elseif n then
      Kernel:plan_save(options[n])
    end

    if n or escape_pressed then
      ui.handle_selection_reset()
      State.mode:close_save_menu()
    end
  ui.finish_frame()
end

Ldump.mark(save_menu, {}, ...)
return save_menu
