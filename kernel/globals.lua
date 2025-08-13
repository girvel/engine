Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")


Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Math = require("engine.lib.math")

Table = require("engine.lib.table")

Tiny = require("engine.lib.tiny")
-- TODO does it need a tiny_dump_patch?

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")

Query = require("engine.lib.query")

Log.info("Initialized globals")
