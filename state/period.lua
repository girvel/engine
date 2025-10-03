local period = {}

--- @class state_period
--- @field _absolute_map composite_map
--- @field _once_map composite_map
local methods = {}
period.mt = {__index = methods}

--- @return state_period
period.new = function()
  return setmetatable({
    _absolute_map = CompositeMap.new(),
    _once_map = CompositeMap.new(),
  }, period.mt)
end

--- @param self state_period
--- @param period_value integer
--- @param ... any identifier
--- @return boolean
methods.absolute = function(self, period_value, ...)
  local now = love.timer.getTime()
  local start_time = self._absolute_map:get(...)
  if not start_time then
    start_time = now
    self._absolute_map:set(now, ...)
  end

  if now - start_time >= period_value then
    self._absolute_map:set(start_time + period_value, ...)
    return true
  end

  return false
end

--- @param self state_period
--- @param ... any identifier
--- @return boolean
methods.once = function(self, ...)
  if not self._once_map:get(...) then
    self._once_map:set(true, ...)
    return true
  end
  return false
end

Ldump.mark(period, {mt = "const"}, ...)
return period
