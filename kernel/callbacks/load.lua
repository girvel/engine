local saves = require("engine.kernel.saves")
local state = require("engine.state")
local systems = require("engine.systems")
local safety = require "engine.tech.safety"
local cli = require "engine.kernel.cli"
local async = require "engine.tech.async"


return function(args)
  Log.info("Started love.load")

  args = cli.parse(args)
  Log.info("CLI args:", args)

  if args.profiler then
    Profile.start()
    async.lag_threshold = 1
  end

  if args.mobdebug then
    local ok, mobdebug = pcall(require, "mobdebug")
    assert(
      ok,
      "-debug option provided, but mobdebug is not found. Are you running this from ZeroBrane?"
    )

    mobdebug.start()
    async.lag_threshold = 2
  end

  if not args.debug then
    Lp = {
      start = function() end,
      stop = function() end,
      report = function() return "" end,
    }
  end

  if args.resolution then
    love.window.updateMode(args.resolution[1], args.resolution[2], {fullscreen = false})
  else
    love.window.updateMode(0, 0, {fullscreen = true})
  end

  if args.fast_scenes then
    Kernel:set_key_rate("space", 15)
  end

  State = state.new(systems, args)
  assert = safety.assert

  Log.info("Finished love.load")
end
