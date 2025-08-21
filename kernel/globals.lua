Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")


Argparse = require("engine.lib.argparse")

Common = require("engine.lib.common")

CompositeMap = require("engine.lib.composite_map")
Ldump.mark_module("engine.lib.composite_map", "const")

Entity = require("engine.lib.entity")

Fn = require("engine.lib.fn")

Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Json = require("engine.lib.json")

Math = require("engine.lib.math")

Memoize = require("engine.lib.memoize")

Promise = require("engine.lib.promise")
Ldump.mark_module("engine.lib.promise", "const")

Random = require("engine.lib.random")

require("engine.lib.string")

Table = require("engine.lib.table")

Tiny = require("engine.lib.tiny")
-- NEXT does it need a tiny_dump_patch?

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")

Query = require("engine.lib.query")

Log.info("Initialized globals")
