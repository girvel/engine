local period = {}

--- @class state_period
--- @field _absolute_map composite_map
--- @field _once_map composite_map
--- @field _key_map composite_map
local methods = {}
period.mt = {__index = methods}

--- @return state_period
period.new = function()
  return setmetatable({
    _absolute_map = CompositeMap.new("weak"),
    _once_map = CompositeMap.new("weak"),
    _key_map = CompositeMap.new("weak"),
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

methods.push_key = function(self, t, key, value)
  assert(value ~= nil)
  assert(self._key_map:get(t, key) == nil)
  self._key_map:set(t[key], t, key)
  t[key] = value
end

methods.pop_key = function(self, t, key)
  assert(self._key_map:get(t, key) ~= nil)
  t[key] = self._key_map:get(t, key)
  self._key_map:set(nil, t, key)
end

Ldump.mark(period, {mt = "const"}, ...)
return period
