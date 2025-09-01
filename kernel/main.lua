-- pre-initialization --
love.graphics.setDefaultFilter("nearest", "nearest")
love.audio.setDistanceModel("exponent")
require("engine.kernel.globals")
require("engine.kernel.wrappers")


-- imports --
local state = require("engine.state")
local systems = require("engine.systems")
local safety = require "engine.tech.safety"
local cli = require "engine.kernel.cli"
local saves = require "engine.kernel.saves"
local async = require "engine.tech.async"


-- callbacks --
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

love.load = function(args)
  Log.info("Started love.load")

  args = cli.parse(args)
  Log.info("CLI args:", args)

  if args.profiler then
    Profile.start()
    async.lag_threshold = 1
  end

  if args.recover then
    love.window.minimize()
    State = unpack(saves.read("last_crash.ldump.gz")) --[[@as state]]
    require("engine.kernel.shell").run()
    os.exit()
  end

  State = state.new(systems, args)
  assert = safety.assert

  Log.info("Finished love.load")
end

love.quit = function()
  if not State.debug and State.mode:attempt_exit() then return true end

  Log.info("Exited smoothly")
  if State.args.profiler then
    Log.info(Profile.report(100))
  end
  Log.report()
  return false
end

love.errorhandler = function(msg)
  Log.fatal(debug.traceback(msg))
  if State.args.profiler then
    Log.info(Profile.report(100))
  end
  Log.report()
  -- saves.write({State}, "last_crash.ldump.gz")
  -- love.window.requestAttention()

  if State.debug then return end

  local FONT = love.graphics.newFont("engine/assets/fonts/clacon2.ttf", 48)

  return function()
    love.event.pump()

    for e,a,b,c in love.event.poll() do
      if e == "quit" then
        return 1
      elseif e == "keypressed" and a == "return" then
        love.event.quit()
      end
    end

    love.graphics.clear()
      love.graphics.setColor(Vector.white)
      love.graphics.setFont(FONT)

      love.graphics.print("Игра потерпела крушение", 200, 200)
      love.graphics.print("нажмите [Enter] чтобы выйти", 200, 260)
    love.graphics.present()
  end
end

love.run = function()
	love.load(love.arg.parseGameArguments(arg), arg)

	love.timer.step()
	local dt = 0
  local KEY_REPETITION_DELAY = .3
  local save_load_t = 0

	return function()
    if Kernel._load then
      local t = love.timer.getTime()
        State = saves.read(Kernel._load)  --[[@as state]]
        if State.mode._mode.type == "escape_menu" then
          State.mode:close_menu()
        end
        Kernel._load = nil
      save_load_t = save_load_t + love.timer.getTime() - t
    end

    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
      if name == "quit" then
        if not love.quit or not love.quit() then
          return a or 0
        end
      elseif name == "keypressed" then
        Kernel._delays[b] = KEY_REPETITION_DELAY
      elseif name == "keyreleased" then
        Kernel._delays[b] = nil
      end
      love.handlers[name](a,b,c,d,e,f)
    end

		dt = love.timer.step() - save_load_t
    save_load_t = 0

    for k, v in pairs(Kernel._delays) do
      Kernel._delays[k] = math.max(0, v - dt)
      if Kernel._delays[k] == 0 then
        love.keypressed(k)
        Kernel._delays[k] = 1 / Kernel:get_key_rate(k)
      end
    end

		love.update(dt)

    love.graphics.origin()
    love.graphics.clear(love.graphics.getBackgroundColor())

    love.draw(dt)

    love.graphics.present()

		love.timer.sleep(0.001)

    if Kernel._save then
      local t = love.timer.getTime()
        saves.write(State, Kernel._save)
        Kernel._save = nil
      save_load_t = save_load_t + love.timer.getTime() - t
    end
  end
end

Log.info("Initialized kernel setup")
