local iteration = require("engine.tech.iteration")
local level = require("engine.tech.level")
local animated = require "engine.tech.animated"
local interactive = require "engine.tech.interactive"


local item = {}

item.DROPPING_SLOTS = {"hand", "offhand", "head", "body"}

--- @class item: entity
--- @field damage_roll? d
--- @field bonus? integer
--- @field tags table<string, true>
--- @field slot string
--- @field anchor? string

item.mixin = function(animation_path)
  return Table.extend(
    animated.mixin(animation_path),
    interactive.mixin(function(self, other)
      if not item.give(other, self) then return end
      level.remove(self)
      self.position = nil
      State:add(self)
    end),
    {
      inventory = {
        highlight = item.cues.highlight(),
      },
      tags = {},
      direction = Vector.right,  -- needed to initially animate into idle_right instead of idle
    }
  )
end

--- @param parent entity
--- @param slot string | integer
--- @return boolean
item.drop = function(parent, slot)
  local drop_position
  for d in iteration.expanding_rhombus(2) do
    local p = d + parent.position
    if (d == Vector.zero or not State.grids.solids:slow_get(p, true))
      and not State.grids.items[p]
    then
      drop_position = p
      break
    end
  end
  if not drop_position then return false end

  local this_item = parent.inventory[slot]
  if not this_item then return true end

  parent.inventory[slot] = nil
  this_item.position = drop_position
  this_item.grid_layer = "items"
  State:add(this_item)
  return true
end

local give_to_hands

--- Put item in the entity's inventory. 
--- Drops the item if entity can't take the item; contains logic for taking weapons.
--- @param entity entity entity to receive the item
--- @param this_item item item to give
--- @return boolean success did item make it to the entity's inventory
item.give = function(entity, this_item)
  local is_free
  local slot
  if this_item.slot == "hands" then
    is_free, slot = give_to_hands(entity, this_item)
  elseif this_item.slot == "offhand" then
    slot = "offhand"
    is_free = (
      (not entity.inventory.offhand or item.drop(entity, "offhand"))
      and (not entity.inventory.hand
        or (not entity.inventory.hand.tags.two_handed and not this_item.tags.two_handed)
        or item.drop(entity, "hand"))
    )
  else
    is_free = not entity.inventory[this_item.slot] or item.drop(entity, this_item.slot)
    slot = this_item.slot
  end

  if not is_free then return false end

  entity.inventory[slot] = this_item

  this_item.direction = entity.direction
  this_item:animate()
  this_item:animation_set_paused(entity.animation and entity.animation.paused)

  return true
end

--- Sets whether given cue should be or not be displayed
--- @param entity entity
--- @param slot cue_slot
--- @param value boolean
--- @return nil
item.set_cue = function(entity, slot, value)
  local factory = assert(item.cues[slot], "Slot %q is not supported" % {slot})

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
item.cues = {
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

--- @return boolean, string?
give_to_hands = function(entity, this_item)
  if this_item.tags.two_handed then
    return (
      (not entity.inventory.hand or item.drop(entity, "hand"))
      and (not entity.inventory.offhand or item.drop(entity, "offhand"))
    ), "hand"
  end

  if not this_item.tags.light then
    return (
      (not entity.inventory.hand or item.drop(entity, "hand"))
      and (not entity.inventory.offhand
        or not entity.inventory.offhand.damage_roll
        or item.drop(entity, "offhand"))
    ), "hand"
  end

  if not entity.inventory.hand then
    if entity.inventory.offhand
      and entity.inventory.offhand.tags.two_handed
      and not item.drop(entity, "offhand")
    then
      return false
    end
    return true, "hand"
  end

  if not entity.inventory.hand.tags.light then
    if not item.drop(entity, "hand") then
      return false
    end
    return true, "hand"
  end

  if not entity.inventory.offhand then
    return true, "offhand"
  end

  if not item.drop(entity, "offhand") then
    return false
  end

  entity.inventory.offhand = entity.inventory.hand
  entity.inventory.hand = nil
  return true, "hand"
end

Ldump.mark(item, {}, ...)
return item
