Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")


Kernel = require("engine.kernel").new()


Argparse = require("engine.lib.argparse")

Common = require("engine.lib.common")

CompositeMap = require("engine.lib.composite_map")
Ldump.mark_module("engine.lib.composite_map", "const")

D = require("engine.lib.d")
Ldump.mark_module("engine.lib.d", "const")

Name = require("engine.lib.name")

Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Inspect = function(x) return require("engine.lib.inspect")(x, {keys_limit = 20}) end

Json = require("engine.lib.json")

Lp = require("engine.lib.line_profiler")
Lp.time_function = love.timer.getTime

Math = require("engine.lib.math")

Memoize = require("engine.lib.memoize")

Moonspeak = require("engine.lib.moonspeak")

Period = require("engine.lib.period")

Profile = require("engine.lib.profile")

Promise = require("engine.lib.promise")
Ldump.mark_module("engine.lib.promise", "const")

Random = require("engine.lib.random")

require("engine.lib.string")

Table = require("engine.lib.table")

Tiny = require("engine.lib.tiny")
Ldump.mark_module("engine.lib.tiny", {
  systemTableKey = {},
})
Tiny.worldMetaTable.__serialize = function(self)
  local entities = self.entities
  return function()
    local result = Tiny.world(require("engine.systems"))
    for _, e in ipairs(entities) do
      result:add(e)
    end
    return result
  end
end

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")

Log.info("Initialized globals")
