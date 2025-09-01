local systems = require("engine.systems")


for callback_name, _ in pairs(
  Fun.iter(systems):reduce(function(acc, system)
    acc[system.base_callback] = true
    return acc
  end, {})
) do
  love[callback_name] = function(...)
    -- NEXT safeties
    State._world:update(function(_, system) return system.base_callback == callback_name end, ...)
    State._world:refresh()
  end
end

love.load = require("engine.kernel.callbacks.load")
love.quit = require("engine.kernel.callbacks.quit")
love.errorhandler = require("engine.kernel.callbacks.errorhandler")
love.run = require("engine.kernel.callbacks.run")
