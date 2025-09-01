local async = {}

async.lag_threshold = .1

--- @param coroutine_ thread
--- @param ... any
--- @return any
async.resume = function(coroutine_, ...)
  local t = love.timer.getTime()
  local success, result = coroutine.resume(coroutine_, ...)
  t = love.timer.getTime() - t
  if t > async.lag_threshold then
    Log.warn("Coroutine lags (%.2f s)\n%s" % {t, debug.traceback()})
  end

  if not success then
    local message = "Coroutine error: %s\ncoroutine %s" % {result, debug.traceback(coroutine_)}
    if State.debug then
      error(message)
    else
      Log.error(message)
    end
  end

  return result
end

--- @async
--- @param seconds number
async.sleep = function(seconds)
  local t = love.timer.getTime()
  while love.timer.getTime() - t < seconds do
    coroutine.yield()
  end
end

Ldump.mark(async, {}, ...)
return async
