local ui = require("engine.tech.ui")


local debug_overlay = {}

--- @class state_debug
--- @field points table<string, overlay_point>
--- @field _show_points boolean
--- @field _show_fps boolean
--- @field _show_stats boolean
local methods = {}
local mt = {__index = methods}

--- @param is_debug boolean
--- @return state_debug
debug_overlay.new = function(is_debug)
  return setmetatable({
    points = {},
    _show_points = false,
    _show_fps = is_debug,
    _show_stats = is_debug,
  }, mt)
end

local ai_load_percent_average = 0
local sum = 0
local frames_n = 0

methods.draw = function(self, dt)
  if self._show_fps then
    ui.text("%.2f" % {1 / love.timer.getAverageDelta()})
  end

  if State.rails and self._show_stats then
    if Period(1, self, "ai_load_percent") then
      ai_load_percent_average = sum / frames_n
      sum = 0
      frames_n = 0
    end
    sum = sum + State.stats.ai_frame_time * 100 / love.timer.getAverageDelta()
    frames_n = frames_n + 1

    ui.text(("active AIs (%s, %.2f%%):"):format(#State.stats.active_ais, ai_load_percent_average))

    local active_ais = {}
    for _, codename in ipairs(State.stats.active_ais) do
      active_ais[codename] = active_ais[codename] and active_ais[codename] + 1 or 1
    end

    for codename, count in pairs(active_ais) do
      ui.text("- " .. codename .. (count > 1 and (" (%s)"):format(count) or ""))
    end

    local scenes = State.rails.runner.scenes
    local enabled_n do
      enabled_n = 0
      for _, v in pairs(scenes) do
        if v.enabled then
          enabled_n = enabled_n + 1
        end
      end
    end
    ui.text(("enabled scenes (%s/%s):"):format(enabled_n, Table.count(scenes)))
    for k, v in pairs(scenes) do
      if v.enabled then
        ui.text("- " .. k)
      end
    end

    local running = State.rails.runner._scene_runs
    ui.text(("running scenes (%s):"):format(#running))
    for _, v in ipairs(running) do
      ui.text("- " .. v.name)
    end

    ui.text("Rails state:")
    for k, v in pairs(State.rails) do
      ui.text(("  %s: %s"):format(k, v))
    end
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
      local x, y = unpack(v)
      love.graphics.circle("fill", x, y, 3)
      love.graphics.print(k, x, y)
      love.graphics.setColor(Vector.white)
    end
    ui.finish_font()
  end

  if ui.keyboard("f1") then
    self._show_points = not self._show_points
  end

  if ui.keyboard("f2") then
    self._show_fps = not self._show_fps
  end

  if ui.keyboard("f3") then
    self._show_stats = not self._show_stats
  end
end

--- @class overlay_point
--- @field position vector
--- @field color vector
--- @field view "grid"|"gui"|"absolute"

Ldump.mark(debug_overlay, {}, ...)
return debug_overlay
