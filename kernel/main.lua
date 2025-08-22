local cli = require "engine.kernel.cli"
local saves = require "engine.kernel.saves"
-- pre-initialization --
love.graphics.setDefaultFilter("nearest", "nearest")
love.audio.setDistanceModel("exponent")
love.keyboard.setKeyRepeat(true)
require("engine.kernel.globals")
require("engine.kernel.wrappers")


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

local inner_draw = love.draw
love.draw = function()
  inner_draw(love.timer.getDelta())
end

love.load = function(args)
  Log.info("Started love.load")

  args = cli.parse(args)
  Log.info("CLI args:", args)

  State = state.new(systems)
  State.debug = args.debug

  Log.info("Finished love.load")
end

love.quit = function()
  Log.info("Exited smoothly")
end

love.run = function()
	love.load(love.arg.parseGameArguments(arg), arg)

	love.timer.step()
	local dt = 0

	return function()
    if Kernel._load then
      saves.read(Kernel._load)
      Kernel._load = nil
    end

    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
      if name == "quit" then
        if not love.quit or not love.quit() then
          return a or 0
        end
      end
      love.handlers[name](a,b,c,d,e,f)
    end

		dt = love.timer.step()

		love.update(dt)

    love.graphics.origin()
    love.graphics.clear(love.graphics.getBackgroundColor())

    love.draw()

    love.graphics.present()

		love.timer.sleep(0.001)

    if Kernel._save then
      saves.write(Kernel._save)
      Kernel._save = nil
    end
  end
end

love.errorhandler = function(msg)
  -- TODO display locals
  Log.fatal(debug.traceback(msg))
  love.window.requestAttention()
end

Log.info("Initialized kernel setup")
