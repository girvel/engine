local animated = require("engine.tech.animated")
local item = require("engine.tech.item")


local cue = {}

--- Sets whether given cue should be or not be displayed
--- @param entity entity
--- @param slot cue_slot
--- @param value boolean
--- @return nil
cue.set = function(entity, slot, value)
  local factory = assert(cue.factories[slot], "Slot %q is not supported" % {slot})

  if not entity.inventory then entity.inventory = {} end
  if (not not value) == (not not entity.inventory[slot]) then return end
  if value then
    item.give(entity, State:add(factory()))
  else
    State:remove(entity.inventory[slot])
    entity.inventory[slot] = nil
  end
end

--- @enum (key) cue_slot
cue.factories = {
  blood = function()
    return Table.extend(
      animated.mixin("engine/assets/sprites/animations/blood"),
      {
        name = "Кровь",
        codename = "blood",
        slot = "blood",
        boring_flag = true,
      }
    )
  end,

  highlight = function()
    return Table.extend(
      animated.mixin("engine/assets/sprites/animations/highlight"),
      {
        name = "Хайлайт",
        codename = "highlight",
        slot = "highlight",
        animated_independently_flag = true,
        boring_flag = true,
      }
    )
  end,
}

Ldump.mark(cue, {}, ...)
return cue
