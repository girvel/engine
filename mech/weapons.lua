local cue = require("engine.tech.cue")
local animated = require "engine.tech.animated"
local interactive = require "engine.tech.interactive"


--- @type table<string, fun(): item>
local weapons = {}

weapons.knife = function()
  return Table.extend(
    animated.mixin("engine/assets/sprites/animations/knife"),
    interactive.mixin(function()
      Log.trace("Hi!")
    end),
    {
      inventory = {
        highlight = cue.factories.highlight(),
      },
      direction = Vector.right,  -- needed to initially animate into idle_right instead of idle
      name = "кухонный нож",
      codename = "knife",
      damage_roll = D(2),
      bonus = 1,
      tags = {
        finesse = true,
        light = true,
      },
      slot = "hands",
    }
  )
end

Ldump.mark(weapons, {}, ...)
return weapons
