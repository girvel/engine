local bad_trip = {}

--- @class shaders_bad_trip: shader
--- @field now number
--- @field duration number
local methods = {}
bad_trip.mt = {__index = methods}

--- @return shaders_bad_trip
bad_trip.new = function(duration)
  local result = setmetatable({
    duration = duration,
    now = 0,
    love_shader = love.graphics.newShader(
      love.filesystem.read("engine/tech/shaders/bad_trip.frag"), nil
    ),
  }, bad_trip.mt)

  return result
end

bad_trip.mt.__serialize = function(self)
  local duration = self.duration
  local now = self.now
  return function()
    local result = bad_trip.new(duration)
    result.now = now
    return result
  end
end

methods.update = function(self, dt)
  self.now = self.now + dt
  local degree = 1 - 2 * math.abs(self.now / self.duration - .5)
  degree = math.max(degree, 0)
  self.love_shader:send("degree", degree)
end

Ldump.mark(bad_trip, {mt = "const"}, ...)
return bad_trip
