local view = require("engine.tech.view")


local perspective = {}

--- @class state_perspective
--- @field views table<string, view>
--- @field views_order string[]
--- @field offset_fs table<string, fun(vector, number): vector>
--- @field SIDEBAR_W integer
local methods = {}
local mt = {__index = methods}

local offsets = {}
local from_matrix

perspective.new = function()
  local views, views_order, offset_fs = from_matrix {
    {"grids", 4, offsets.camera},
    {"grids_fx", 4, offsets.camera},
  }

  return setmetatable({
    views = views,
    views_order = views_order,
    offset_fs = offset_fs,
    SIDEBAR_W = 400,
  }, mt)
end

methods.center_camera = function(self, prev, position)
  local scene_k = State.level.cell_size * self.views.grids.scale
  local window_size = V(love.graphics.getDimensions()) - V(self.SIDEBAR_W, 0)
  local border_size = (window_size / 2 - Vector.one * scene_k):map(math.floor)
  local player_position = position * scene_k

  return Vector.use(Math.median,
    window_size - player_position - border_size,
    prev,
    border_size - player_position
  )
end

methods.update = function(self, dt)
  for _, key in ipairs(self.views_order) do
    self.views[key].offset = self.offset_fs[key](self.views[key].offset, dt)
  end
end

from_matrix = function(matrix)
  local views = {}
  local views_order = {}
  local views_offset_functions = {}

  for _, v in ipairs(matrix) do
    local name, scale, f = unpack(v)
    views[name] = view.new(Vector.zero, scale)
    table.insert(views_order, name)
    views_offset_functions[name] = f
  end

  return views, views_order, views_offset_functions
end

local SMOOTHING_CUTOFF = 3
local SPRING_STIFFNESS = 100
local DAMPING_K = 2 * math.sqrt(SPRING_STIFFNESS)

offsets.camera = setmetatable({
  velocity = Vector.zero,
}, {
  __call = function(self, prev, dt)
    local target = State.perspective:center_camera(prev, State.player.position)

    local d = target - prev
    if d:abs() <= SMOOTHING_CUTOFF then return target end

    local acceleration = SPRING_STIFFNESS * d - DAMPING_K * self.velocity
    self.velocity = self.velocity + acceleration * dt
    return (prev + self.velocity * dt):map(math.floor)
  end,
})

Ldump.mark(perspective, {}, ...)
return perspective
