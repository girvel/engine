local composite_map = require("engine.lib.composite_map")


local map = composite_map.new()

--- @param period integer
--- @param ... any identifier
--- @return boolean
return function(period, ...)
  local now = love.timer.getTime()
  local start_time = map:get(...)
  if not start_time then
    start_time = now
    map:set(now, ...)
  end

  if now - start_time >= period then
    map:set(start_time + period, ...)
    return true
  end

  return false
end
