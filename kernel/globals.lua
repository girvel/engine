Ldump = require("engine.vendor.ldump")

Fun = require("engine.vendor.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Tiny = require("engine.vendor.tiny")
-- TODO does it need a tiny_dump_patch?

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")
