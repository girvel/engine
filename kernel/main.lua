require("engine.kernel.globals")
local state = require("engine.state")


local systems = require("engine.systems")
for callback_name, _ in pairs(
  Fun.iter(systems):reduce(function(acc, system)
    acc[system.base_callback] = true
    return acc
  end, {})
) do
  love[callback_name] = function(...)
    -- TODO debug system
    State._world:update(function(_, system) return system.base_callback == callback_name end, ...)
    State._world:refresh()
  end
end

love.load = function()
  Log.info("Started love.load")

  State = state.new(systems)

  Log.info("Finished love.load")
end

love.quit = function()
  Log.info("Exited smoothly")
end

Log.info("Initialized kernel setup")
