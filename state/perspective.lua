local tcod = require("engine.tech.tcod")
local level= require("engine.tech.level")


local perspective = {}

local smooth_camera_offset

--- @class state_perspective
--- @field target_override entity?
--- @field is_moving boolean
--- @field is_camera_following boolean
--- @field camera_offset vector
--- @field vision_start vector
--- @field vision_end vector
--- @field sidebar_w integer
--- @field SCALE integer
local methods = {}
perspective.mt = {__index = methods}

perspective.new = function()
  return setmetatable({
    is_moving = false,
    is_camera_following = true,
    camera_offset = Vector.zero,
    vision_start = Vector.zero,
    vision_end = Vector.zero,
    sidebar_w = 0,
    SCALE = 4,
  }, perspective.mt)
end

methods.center_camera = function(self, target_x, target_y)
  local k = Constants.cell_size * self.SCALE
  return
    math.floor(love.graphics.getWidth() / 2 - self.sidebar_w - target_x * k),
    math.floor(love.graphics.getHeight() / 2 - target_y * k)
end

methods.update = function(self, dt)
  if not State.player then return end

  if self.is_camera_following and State.is_loaded then
    local next_offset = smooth_camera_offset:next(
      self.target_override or State.player, self.camera_offset, dt
    )
    self.is_moving = next_offset ~= self.camera_offset
    self.camera_offset = next_offset

    State.debug_overlay.points.camera = {
      position = -self.camera_offset + V(734, 540) + V(32, 32),
      color = V(0, 0, 1),
      view = "absolute",
    }
  else
    self.is_moving = false
  end

  do
    local total_scale = self.SCALE * Constants.cell_size
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
  vx = 0,
  vy = 0,
  next = function(self, target, prev, dt)
    prev = prev:map(function(v) return v ~= v and 0 or v end)
    local prev_x, prev_y = unpack(prev)

    if dt >= .05 then  -- spring-based camera overshoots on low FPS
      return V(State.perspective:center_camera(unpack(State.player.position)))
    end

    local tx, ty = unpack(target.position)
    if target == State.player
      and State.player:can_act()
      and State.player.resources.movement > 0
    then
      tx = tx
        + math.min(1, (Kernel._delays.d or 0) * Kernel:get_key_rate("d"))
        - math.min(1, (Kernel._delays.a or 0) * Kernel:get_key_rate("a"))

      ty = ty
        + math.min(1, (Kernel._delays.s or 0) * Kernel:get_key_rate("s"))
        - math.min(1, (Kernel._delays.w or 0) * Kernel:get_key_rate("w"))
    end

    if State.debug then
      State.debug_overlay.points.target_position = {
        position = V(tx + .5, ty + .5),
        color = V(1, 0, 0),
        view = "grid",
      }
    end

    local target_x, target_y = State.perspective:center_camera(tx, ty)

    if State.debug then
      State.debug_overlay.points.target = {
        position = V(734 + 32 - target_x, 540 + 32 - target_y),
        color = V(0, 1, 0),
        view = "absolute",
      }
    end

    local dx = target_x - prev_x
    local dy = target_y - prev_y

    local ax = SPRING_STIFFNESS * dx - DAMPING_K * self.vx
    local ay = SPRING_STIFFNESS * dy - DAMPING_K * self.vy

    self.vx = self.vx + ax * dt
    self.vy = self.vy + ay * dt

    local result = V(
      math.floor(prev_x + self.vx * dt),
      math.floor(prev_y + self.vy * dt)
    )
    return result
  end,
}

Ldump.mark(perspective, {mt = "const"}, ...)
return perspective
