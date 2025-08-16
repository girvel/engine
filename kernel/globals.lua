Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")


Common = require("engine.lib.common")

Entity = require("engine.lib.entity")

Fn = require("engine.lib.fn")

Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Json = require("engine.lib.json")

Math = require("engine.lib.math")

Memoize = require("engine.lib.memoize")

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
