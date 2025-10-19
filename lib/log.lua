local inspect = require("engine.lib.inspect")


local log = {}

if love then
  local log_directory = love.filesystem.getSaveDirectory() .. "/logs"
  if not love.filesystem.getInfo(log_directory) then
    love.filesystem.createDirectory("/logs")
  end
  log.outfile = "/logs/" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".txt"
end

log.usecolor = true
log.level = "trace"

local levels, count, pretty


--- @param fmt any
--- @param ... any
--- @return string
log.format = function(fmt, ...)
  if type(fmt) == "string" then
    return fmt:format(pretty(...))
  else
    if not select("#", ...) == 0 then
      Error(
        "Log.format's first argument should be of type string to use formatting args; got %s",
        type(fmt)
      )
    end
    return tostring(pretty(fmt))
  end
end

--- @generic T
--- @param level log_level
--- @param trace_shift integer
--- @param fmt any
--- @param ... T
--- @return T
log.log = function(level, trace_shift, fmt, ...)
  if count[level] then
    count[level] = count[level] + 1
  end

  if levels[level].index < levels[log.level].index then
    return ...
  end

  local msg = log.format(fmt, ...)

  local info = debug.getinfo(2 + trace_shift, "Sl")
  local lineinfo = info.short_src .. ":" .. info.currentline
  local nameupper = (level --[[@as string]]):upper()
  local frame_number = Kernel and (" %03d"):format(Kernel._total_frames % 1000) or ""

  print(("%s[%-6s%s%s]%s %s: %s"):format(
    log.usecolor and levels[level].color or "",
    nameupper,
    os.date("%H:%M:%S"),
    frame_number,
    log.usecolor and "\27[0m" or "",
    lineinfo,
    msg
  ))

  if log.outfile then
    love.filesystem.append(
      log.outfile, ("[%-6s%s%s] %s: %s\n"):format(
        nameupper,
        os.date("%H:%M:%S"),
        frame_number,
        lineinfo,
        msg
      )
    )
  end

  return ...
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.trace = function(fmt, ...)
  return log.log("trace", 0, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.debug = function(fmt, ...)
  return log.log("debug", 0, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.info = function(fmt, ...)
  return log.log("info", 0, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.warn = function(fmt, ...)
  return log.log("warn", 0, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.error = function(fmt, ...)
  return log.log("error", 0, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.fatal = function(fmt, ...)
  return log.log("fatal", 0, fmt, ...)
end

log.report = function()
  local level = "info"
  if count.fatal > 0 then
    level = "fatal"
  elseif count.error > 0 then
    level = "error"
  elseif count.warn > 0 then
    level = "warn"
  end

  levels.rep = levels[level]

  log.log("rep", 1, ("%s warnings, %s errors, %s fatal"):format(count.warn, count.error, count.fatal))
end

--- @enum (key) log_level
levels = {
  trace = {color = "\27[34m", index = 1},
  debug = {color = "\27[36m", index = 2},
  info = {color = "\27[32m", index = 3},
  warn = {color = "\27[33m", index = 4},
  error = {color = "\27[31m", index = 5},
  fatal = {color = "\27[35m", index = 6},
  rep = {},
}

count = {
  warn = 0,
  error = 0,
  fatal = 0,
}

pretty = function(...)
  local result = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "table" then
      x = Name.code(x, nil) or inspect(x, {depth = 3, keys_limit = 20})
    end
    result[i] = x
  end
  return unpack(result)
end

return log
