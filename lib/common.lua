--- Module with uncategorized utility functions
local common = {}

common.resume_logged = function(coroutine_, ...)
  local t = love.timer.getTime()
  local success, result = coroutine.resume(coroutine_, ...)
  t = love.timer.getTime() - t
  if t > 0.1 then
    Log.warn("Coroutine lags\n" .. debug.traceback())
  end

  if not success then
    Log.error("Coroutine error: %s\n%s" % {result, debug.traceback(coroutine_)})
  end

  return result
end

return common
