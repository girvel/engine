--- @async
--- @param path string
--- @return table
local read_json = function(path)
  local start_t = love.timer.getTime()

  local content = love.filesystem.read(path)
  coroutine.yield(0)

  local json_thread = love.thread.newThread [[
    local content = ...

    love.thread.getChannel('json'):push(
      require("engine.lib.json").decode(content)
    )
  ]]
  json_thread:start(content)

  while true do
    coroutine.yield(0)
    local result = love.thread.getChannel('json'):pop()
    if result then
      Log.info("Read & parsed JSON %q in %.2f s", path, love.timer.getTime() - start_t)
      return result
    end
  end
end

Ldump.mark(read_json, "const", ...)
return read_json
