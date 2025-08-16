-- pre-initialization --
require("engine.kernel.globals")
love.graphics.setDefaultFilter("nearest", "nearest")
love.audio.setDistanceModel("exponent")


-- imports --
local state = require("engine.state")
local systems = require("engine.systems")


-- callbacks --
for callback_name, _ in pairs(
  Fun.iter(systems):reduce(function(acc, system)
    acc[system.base_callback] = true
    return acc
  end, {})
) do
  love[callback_name] = function(...)
    -- NEXT debug system
    State._world:update(function(_, system) return system.base_callback == callback_name end, ...)
    State._world:refresh()
  end
end

-- NEXT love.run
local inner_draw = love.draw
love.draw = function()
  inner_draw(love.timer.getDelta())
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
