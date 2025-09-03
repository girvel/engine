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
      direction = Vector.right,  -- needed to initially animate into idle_right instead of idle
    }
  )
end

--- @param parent entity
--- @param slot string | integer
--- @return boolean
item.drop = function(parent, slot)
  local drop_position = Fun.chain({Vector.zero}, Vector.directions)
    :map(function(d) return parent.position + d end)
    :filter(function(v)
      return (v == parent.position or not State.grids.solids:slow_get(v, true))
        and not State.grids.items[v]
    end)
    :nth(1)
  if not drop_position then return false end

  local this_item = parent.inventory[slot]
  if not this_item then return true end

  parent.inventory[slot] = nil
  this_item.position = drop_position
  this_item.grid_layer = "items"
  State:add(this_item)
  return true
end

--- Put item in the entity's inventory. 
--- Drops the item if entity can't take the item; contains logic for taking weapons.
--- @param entity entity entity to receive the item
--- @param this_item item item to give
--- @return boolean success did item make it to the entity's inventory
item.give = function(entity, this_item)
  local slot
  local is_free
  if this_item.slot == "hands" then
    if this_item.tags.two_handed or not this_item.tags.light then
      is_free = (
        (not entity.inventory.hand or item.drop(entity, "hand"))
        and (not entity.inventory.offhand or item.drop(entity, "offhand"))
      )
      slot = "hand"
    else
      if not entity.inventory.hand
        or (not entity.inventory.hand.tags.light and item.drop(entity, "hand"))
      then
        slot = "hand"
        is_free = true
      elseif entity.inventory.hand.tags.light and not entity.inventory.offhand then
        slot = "offhand"
        is_free = true
      elseif entity.inventory.hand.tags.light and item.drop(entity, "offhand") then
        entity.inventory.offhand = entity.inventory.hand
        entity.inventory.hand = nil
        slot = "hand"
        is_free = true
      else
        is_free = false
      end
    end
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

Ldump.mark(item, {}, ...)
return item
