Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")


Kernel = require("engine.kernel").new()


Argparse = require("engine.lib.argparse")

Common = require("engine.lib.common")

CompositeMap = require("engine.lib.composite_map")
Ldump.mark_module("engine.lib.composite_map", "const")

Entity = require("engine.lib.entity")

Fn = require("engine.lib.fn")

Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Inspect = require("engine.lib.inspect")

Json = require("engine.lib.json")

Math = require("engine.lib.math")

Memoize = require("engine.lib.memoize")

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
  local systems = self.systems
  local entities = self.entities
  return function()
    local result = Tiny.world(unpack(systems))
    for _, e in ipairs(entities) do
      result:add(e)
    end
    return result
  end
end

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")

Query = require("engine.lib.query")
Ldump.mark_module("engine.lib.query", "const")

Log.info("Initialized globals")
