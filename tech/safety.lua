local safety = {}

--- Prevents the system from running if the level is not fully loaded
--- @generic T
--- @param system T
--- @return T
safety.live_system = function(system)
  --- @cast system table
  local prev = system.update
  system.update = function(...)
    if not State.is_loaded then return end
    return prev(...)
  end
  return system
end

--- @generic T
--- @param condition T
--- @param message string
--- @return T
safety.assert = function(condition, message)
  if condition then
    return condition
  end

  if State.debug then
    error(message)
  end

  Log.warn(message)
  return condition
end

Ldump.mark(safety, {}, ...)
return safety
