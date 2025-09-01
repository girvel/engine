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
