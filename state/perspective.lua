local tcod = require("engine.tech.tcod")


local perspective = {}

local smooth_camera_offset

--- @class state_perspective
--- @field is_camera_following boolean
--- @field camera_offset vector
--- @field vision_start vector
--- @field vision_end vector
--- @field sidebar_w integer
--- @field SCALE integer
local methods = {}
local mt = {__index = methods}

perspective.new = function()
  return setmetatable({
    is_camera_following = true,
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
  local window_size = V(love.graphics.getDimensions()) - V(self.sidebar_w, 0)
  return -(position) * State.level.cell_size * self.SCALE + window_size / 2
end

methods.update = function(self, dt)
  if not State.player then return end

  if self.is_camera_following and State.is_loaded then
    self.camera_offset = smooth_camera_offset:next(self.camera_offset, dt)
    State.debug.points.camera = {
      position = -self.camera_offset + V(734, 540) + V(32, 32),
      color = V(0, 0, 1),
      view = "absolute",
    }
  end

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

local SPRING_STIFFNESS = 100
local DAMPING_K = 2 * math.sqrt(SPRING_STIFFNESS)

smooth_camera_offset = {
  velocity = Vector.zero,
  next = function(self, prev, dt)
    prev = prev:map(function(v) return v ~= v and 0 or v end)
    
    local virtual_position = State.player.position
    if State.player:can_act() and State.player.resources.movement > 0 then
      virtual_position = virtual_position
        - Vector.up    * math.min(1, (Kernel._delays.w or 0) * Kernel:get_key_rate("w"))
        - Vector.left  * math.min(1, (Kernel._delays.a or 0) * Kernel:get_key_rate("a"))
        - Vector.down  * math.min(1, (Kernel._delays.s or 0) * Kernel:get_key_rate("s"))
        - Vector.right * math.min(1, (Kernel._delays.d or 0) * Kernel:get_key_rate("d"))
    end

    State.debug.points.vp = {
      position = virtual_position + V(.5, .5),
      color = V(1, 0, 0),
      view = "grid",
    }

    local target = State.perspective:center_camera(prev, virtual_position)

    State.debug.points.target = {
      position = -target + V(734, 540) + V(32, 32),
      color = V(0, 1, 0),
      view = "absolute",
    }

    if dt >= .1 then  -- spring-based camera overshoots on low FPS
      return target
    end
    
    local d = target - prev

    local acceleration = SPRING_STIFFNESS * d - DAMPING_K * self.velocity
    self.velocity = self.velocity + acceleration * dt

    local result = (prev + self.velocity * dt):map(math.floor)
    return result
  end,
}

Ldump.mark(perspective, {}, ...)
return perspective
