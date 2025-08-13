local state = require("engine.state")
require("engine.kernel.globals")

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
  State = state.new(systems)
  --Log.info("Engine finished love.load")
end
