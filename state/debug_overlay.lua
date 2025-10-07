local ui = require("engine.tech.ui")


local debug_overlay = {}

--- @class state_debug
--- @field points table<string, overlay_point>
--- @field _show_points boolean
--- @field _show_fps boolean
--- @field _show_ai boolean
--- @field _show_scenes boolean
--- @field _show_rails boolean
local methods = {}
local mt = {__index = methods}

--- @param is_debug boolean
--- @return state_debug
debug_overlay.new = function(is_debug)
  is_debug = not not is_debug
  return setmetatable({
    points = {},
    _show_points = false,
    _show_fps = is_debug,
    _show_ai = false,
    _show_scenes = is_debug,
    _show_rails = is_debug,
  }, mt)
end

local draw_points, report_fps, report_ai, report_scenes, report_rails

methods.draw = function(self, dt)
  self._show_points = self._show_points ~= ui.keyboard("f1")
  self._show_fps    = self._show_fps    ~= ui.keyboard("f2")
  self._show_ai     = self._show_ai     ~= ui.keyboard("f3")
  self._show_scenes = self._show_scenes ~= ui.keyboard("f4")
  self._show_rails  = self._show_rails  ~= ui.keyboard("f5")

  if self._show_points then draw_points(self.points) end
  if self._show_fps then report_fps() end
  if self._show_ai then report_ai() end
  if self._show_scenes then report_scenes() end
  if self._show_rails then report_rails() end
end

draw_points = function(points)
  ui.start_font(12)
  for k, point in pairs(points) do
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

report_fps = function()
  ui.text("%.2f" % {1 / love.timer.getAverageDelta()})
end

local ai_load_percent_average = 0
local sum = 0
local frames_n = 0

report_ai = function()
  if State.period:absolute(1, report_ai, "ai_load_percent") then
    ai_load_percent_average = sum / frames_n
    sum = 0
    frames_n = 0
  end
  sum = sum + State.stats.ai_frame_time * 100 / love.timer.getAverageDelta()
  frames_n = frames_n + 1

  ui.br()
  ui.text(("[F3] active AIs (%s, %.2f%%):"):format(#State.stats.active_ais, ai_load_percent_average))

  local active_ais = {}
  for _, codename in ipairs(State.stats.active_ais) do
    active_ais[codename] = active_ais[codename] and active_ais[codename] + 1 or 1
  end

  for codename, count in pairs(active_ais) do
    ui.text("- " .. codename .. (count > 1 and (" (%s)"):format(count) or ""))
  end
end

report_scenes = function()
  if not State.rails then return end

  local scenes = State.runner.scenes
  local enabled_n, total_n do
    enabled_n = 0
    total_n = 0
    for _, v in pairs(scenes) do
      if v.enabled then
        enabled_n = enabled_n + 1
      end
      total_n = total_n + 1
    end
  end

  ui.br()
  ui.text(("[F4] enabled scenes (%s/%s):"):format(enabled_n, total_n))
  for k, v in pairs(scenes) do
    ui.text((v.enabled and "+" or "-") .. " " .. k)
  end

  local running = State.runner._scene_runs
  ui.text(("running scenes (%s):"):format(#running))
  for _, v in ipairs(running) do
    ui.text("- " .. v.name)
  end
end

local hidden_types = Table.set {
  "table", "function", "userdata", "thread"
}

report_rails = function()
  if not State.rails then return end

  ui.br()
  ui.text("[F5] rails state:")
  for k, v in pairs(State.rails) do
    if not hidden_types[type(k)] and not hidden_types[type(v)] then
      ui.text(("  %s: %s"):format(k, Inspect(v)))
    end
  end
end

--- @class overlay_point
--- @field position vector
--- @field color vector
--- @field view "grid"|"gui"|"absolute"

Ldump.mark(debug_overlay, {}, ...)
return debug_overlay
