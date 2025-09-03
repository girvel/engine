local item = require("engine.tech.item")


--- @type table<string, fun(): item>
local weapons = {}

weapons.knife = function()
  return Table.extend(
    item.mixin("engine/assets/sprites/animations/knife"),
    {
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
