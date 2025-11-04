local perspective = {}


----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

--- @class state_perspective
--- @field target_override entity?
--- @field is_camera_following boolean
--- @field is_moving boolean (internally set)
--- @field camera_offset vector (internally set) offset in pixels relative to the grid start
--- @field vision_start vector (internally set)
--- @field vision_end vector (internally set)
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

methods.immediate_center = function(self)
  self.camera_offset = V(self:_center(unpack((self.target_override or State.player).position)))
end


----------------------------------------------------------------------------------------------------
-- [SECTION] Implementation
----------------------------------------------------------------------------------------------------

local smooth_camera_offset

methods._update = function(self, dt)
  State.player.ai._vision_map:refresh_fov(State.player.position, State.player.fov_r)

  if self.is_camera_following then
    local prev_offset = self.camera_offset

    if dt >= .05 then
      self:immediate_center()
    else
      local target = self.target_override or State.player
      local px, py = unpack(self.camera_offset)
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

      self.camera_offset = V(smooth_camera_offset:next(tx, ty, px, py, dt))
    end

    self.is_moving = prev_offset ~= self.camera_offset
  else
    self.is_moving = false
  end

  do
    local total_scale = self.SCALE * Constants.cell_size
    self.vision_start = -(State.perspective.camera_offset / total_scale):map(math.ceil)
    self.vision_end = V(love.graphics.getWidth() - self.sidebar_w, love.graphics.getHeight())
      :div_mut(total_scale)
      :map_mut(math.ceil)
      :add_mut(self.vision_start)

    self.vision_start = Vector.use(
      Math.median, Vector.one, self.vision_start, State.level.grid_size
    )
    self.vision_end = Vector.use(Math.median, Vector.one, self.vision_end, State.level.grid_size)
  end
end

--- @param x number
--- @param y number
--- @return number, number
methods._center = function(self, x, y)
  local k = Constants.cell_size * self.SCALE
  return
    math.floor(love.graphics.getWidth() / 2 - self.sidebar_w - x * k),
    math.floor(love.graphics.getHeight() / 2 - y * k)
end

local SPRING_STIFFNESS = 100
local DAMPING_K = 2 * math.sqrt(SPRING_STIFFNESS)

smooth_camera_offset = {
  vx = 0,
  vy = 0,
  next = function(self, tx, ty, px, py, dt)
    local dest_x, dest_y = State.perspective:_center(tx, ty)

    local dx = dest_x - px
    local dy = dest_y - py

    local ax = SPRING_STIFFNESS * dx - DAMPING_K * self.vx
    local ay = SPRING_STIFFNESS * dy - DAMPING_K * self.vy

    self.vx = self.vx + ax * dt
    self.vy = self.vy + ay * dt

    return
      math.floor(px + self.vx * dt),
      math.floor(py + self.vy * dt)
  end,
}

Ldump.mark(perspective, {mt = "const"}, ...)
return perspective
