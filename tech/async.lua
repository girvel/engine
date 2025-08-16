local async = {}

local LAG_THRESHOLD_SEC = .1

async.resume = function(coroutine_, ...)
  local t = love.timer.getTime()
  local success, result = coroutine.resume(coroutine_, ...)
  t = love.timer.getTime() - t
  if t > LAG_THRESHOLD_SEC then
    Log.warn("Coroutine lags\n" .. debug.traceback())
  end

  if not success then
    error("Coroutine error: %s\ncoroutine %s" % {result, debug.traceback(coroutine_)})
  end

  return result
end

Ldump.mark(async, {}, ...)
return async
