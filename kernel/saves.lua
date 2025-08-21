local saves = {}

local SLASH = love.system.getOS() == "Windows" and "\\" or "/"

saves.write = function(name)
  love.filesystem.createDirectory("saves")
  local filepath = "saves" .. SLASH .. name .. ".ldump.gz"

  local base = love.filesystem.getSaveDirectory()
  Log.info("Saving the game to %s%s%s" % {base, SLASH, filepath})

  local t = love.timer.getTime()
  love.filesystem.write(filepath, love.data.compress("string", "gzip", Ldump(State)))
  t = love.timer.getTime() - t

  Fun.iter(Ldump.get_warnings()):each(Log.warn)
  local size_kb = love.filesystem.getInfo(filepath).size / 1024
  Log.info("Game saved in %.2f s, file size %.2f KB" % {t, size_kb})
end

saves.read = function(name)
  local filepath = "saves" .. SLASH .. name .. ".ldump.gz"

  local base = love.filesystem.getSaveDirectory()
  Log.info("Loading the game from %s%s%s" % {base, SLASH, filepath})

  local t = love.timer.getTime()
  State = assert(loadstring(
    love.data.decompress(
      "string", "gzip", love.filesystem.read(filepath)
    ) --[[@as string]],
    filepath
  ))()
  t = love.timer.getTime() - t

  Log.info("Game loaded in %.2f s" % {t})
end

return saves
