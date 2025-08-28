local tcod = require("engine.tech.tcod")


local perspective = {}

local smooth_camera_offset

--- @class state_perspective
--- @field camera_offset vector
--- @field vision_start vector
--- @field vision_end vector
--- @field sidebar_w integer
--- @field SCALE integer
local methods = {}
local mt = {__index = methods}

perspective.new = function()
  return setmetatable({
    camera_offset = Vector.zero,
    vision_start = Vector.zero,
    vision_end = Vector.zero,
    sidebar_w = 0,
    SCALE = 4,
  }, mt)
end

--- @param prev vector
--- @param position vector
--- @return vector
methods.center_camera = function(self, prev, position)
  local scene_k = State.level.cell_size * self.SCALE
  local window_size = V(love.graphics.getDimensions()) - V(self.sidebar_w, 0)
  local border_size = (window_size / 2 - Vector.one * scene_k):map(math.floor)
  local scaled_position = position * scene_k

  return Vector.use(Math.median,
    window_size - scaled_position - border_size,
    prev,
    border_size - scaled_position
  )
end

methods.update = function(self, dt)
  if not State.player then return end

  self.camera_offset = smooth_camera_offset:next(self.camera_offset, dt)

  do
    local total_scale = self.SCALE * State.level.cell_size
    self.vision_start = -(State.perspective.camera_offset / total_scale):map(math.ceil)
    self.vision_end = self.vision_start
      + (V(love.graphics.getDimensions()) / total_scale):map(math.ceil)

    self.vision_start = Vector.use(
      Math.median, Vector.one, self.vision_start, State.level.grid_size
    )
    self.vision_end = Vector.use(Math.median, Vector.one, self.vision_end, State.level.grid_size)
  end

  tcod.snapshot(State.grids.solids):refresh_fov(State.player.position, State.player.fov_r)
end

local SMOOTHING_CUTOFF = 3
local SPRING_STIFFNESS = 50
local DAMPING_K = 4 * math.sqrt(SPRING_STIFFNESS)

smooth_camera_offset = {
  velocity = Vector.zero,
  next = function(self, prev, dt)
    local target = State.perspective:center_camera(prev, State.player.position)

    local d = target - prev
    if d:abs() <= SMOOTHING_CUTOFF then return target end

    local acceleration = SPRING_STIFFNESS * d - DAMPING_K * self.velocity
    self.velocity = self.velocity + acceleration * dt
    return (prev + self.velocity * dt):map(math.floor)
  end,
}

Ldump.mark(perspective, {}, ...)
return perspective
