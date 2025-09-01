local ui = require("engine.tech.ui")


local debug_overlay = {}

--- @class state_debug
--- @field points table<string, overlay_point>
--- @field _show_points boolean
local methods = {}
local mt = {__index = methods}

--- @return state_debug
debug_overlay.new = function()
  return setmetatable({
    points = {},
    _show_points = false,
  }, mt)
end

methods.draw = function(self, dt)
  ui.text("%.2f" % {1 / love.timer.getAverageDelta()})

  if State.rails then
    local enabled = Fun.pairs(State.rails.runner.scenes)
      :map(function(k, v) return k end)
      :totable()

    ui.text("enabled:")
    for k, v in pairs(State.rails.runner.scenes) do
      if not v.disabled then
        ui.text("- " .. k)
      end
    end

    ui.text("running:")
    for _, v in ipairs(State.rails.runner._scene_runs) do
      ui.text("- " .. v.name)
    end
  end

  if ui.keyboard("f1") then
    self._show_points = not self._show_points
  end

  if self._show_points then
    ui.start_font(12)
    for k, point in pairs(self.points) do
      love.graphics.setColor(point.color)
      local v
      if point.view == "grid" then
        v = point.position * 4 * State.level.cell_size + State.perspective.camera_offset
      elseif point.view == "absolute" then
        v = point.position + State.perspective.camera_offset
      elseif point.view == "gui" then
        v = point.position
      else
        assert(false)
      end
      local x, y = v:unpack()
      love.graphics.circle("fill", x, y, 3)
      love.graphics.print(k, x, y)
      love.graphics.setColor(Vector.white)
    end
    ui.finish_font()
  end
end

--- @class overlay_point
--- @field position vector
--- @field color vector
--- @field view "grid"|"gui"|"absolute"

Ldump.mark(debug_overlay, {}, ...)
return debug_overlay
