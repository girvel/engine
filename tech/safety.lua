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

--- @param f function
--- @param ... any
--- @return any
safety.call = function(f, ...)
  if State.debug then
    return f(...)
  end

  local ok, result = pcall(f, ...)
  if ok then return result end

  Log("warn", 1, "safety.call error:", result)
end

Ldump.mark(safety, {}, ...)
return safety
