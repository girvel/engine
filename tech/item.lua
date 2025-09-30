local level = require("engine.tech.level")
local animated = require "engine.tech.animated"
local interactive = require "engine.tech.interactive"


local item = {}

item.DROPPING_SLOTS = {"hand", "offhand", "head", "body"}

--- @alias item item_strict|table

--- @class item_strict: entity_strict
--- @field damage_roll? d present only in weapons
--- @field bonus? integer bonus damage
--- @field tags table<string, true>
--- @field slot item_slot
--- @field anchor? anchor overrides .slot for anchoring
--- @field projectile_factory? fun(): entity present only in ranged weapons
--- @field no_drop_flag? true
--- @field animated_independently_flag? true

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

--- @param slot string
item.mixin_min = function(slot)
  return {
    tags = {},
    direction = Vector.right,
    slot = slot,
  }
end

--- @param entity entity
--- @param slot inventory_slot
item.anchor_offset = function(entity, slot)
  local this_item = assert(
    entity.inventory[slot],
    ("anchor_offset for empty %s's inventory slot %s"):format(Name.code(entity), slot)
  )

  local parent_anchor = entity.sprite.anchors[this_item.anchor or slot]
  if not parent_anchor then return Vector.zero end

  local item_anchor = this_item.sprite and this_item.sprite.anchors.parent
  if not item_anchor then return Vector.zero end

  return (parent_anchor - item_anchor):div_mut(16)
end

--- @param parent entity
--- @param ... string | integer
--- @return boolean
item.drop = function(parent, ...)
  local next_position = Iteration.rhombus(5)
  for i = 1, select("#", ...) do
    local slot = select(i, ...)

    local position
    for d in next_position do
      local p = d + parent.position
      if (d == Vector.zero or not State.grids.solids:slow_get(p, true))
        and not State.grids.items[p]
      then
        position = p
        goto found
        break
      end
    end
    do return false end
    ::found::

    local this_item = parent.inventory[slot]
    if not this_item then return true end

    parent.inventory[slot] = nil
    this_item.position = position
    this_item.grid_layer = "items"
    State:add(this_item)
  end
  return true
end

local give_to_hands, give_to_offhand

--- Put item in the entity's inventory. 
--- Drops the item if entity can't take the item; contains logic for taking weapons.
--- @param entity entity entity to receive the item
--- @param this_item item item to give
--- @return boolean success did item make it to the entity's inventory
item.give = function(entity, this_item)
  local inv = entity.inventory

  local is_free
  local slot
  if this_item.slot == "hands" then
    is_free, slot = give_to_hands(entity, this_item)
  elseif this_item.slot == "offhand" then
    is_free = give_to_offhand(entity, this_item)
    slot = "offhand"
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

--- Sets whether given cue should (not) be or displayed
---
--- Cues are simplistic items that exist for visualization only, like blood marks or a highlight.
--- @param entity entity
--- @param slot cue_slot
--- @param value boolean
--- @return nil
item.set_cue = function(entity, slot, value)
  local factory = assert(
    entity.cues and entity.cues[slot] or item.cues[slot],
    ("Slot %q is not supported"):format(slot)
  )

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
      animated.mixin("engine/assets/sprites/animations/highlight", 1),
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
  local inv = entity.inventory
  local hand = inv.hand
  local offhand = inv.offhand
  local both = hand and offhand

  if this_item.tags.two_handed then
    local ok
    if both then
      ok = item.drop(entity, "hand", "offhand")
    elseif hand then
      ok = item.drop(entity, "hand")
    elseif offhand then
      ok = item.drop(entity, "offhand")
    else
      ok = true
    end
    return ok, "hand"
  end

  if not this_item.tags.light then
    local ok
    if both then
      if offhand.damage_roll then
        ok = item.drop(entity, "hand", "offhand")
      else
        ok = item.drop(entity, "hand")
      end
    else
      if offhand.damage_roll then
        ok = item.drop(entity, "offhand")
      else
        ok = true
      end
    end
    return ok, "hand"
  end

  if not inv.hand then
    if inv.offhand
      and inv.offhand.tags.two_handed
      and not item.drop(entity, "offhand")
    then
      return false
    end
    return true, "hand"
  end

  if not inv.hand.tags.light then
    if not item.drop(entity, "hand") then
      return false
    end
    return true, "hand"
  end

  if not inv.offhand then
    return true, "offhand"
  end

  if not item.drop(entity, "offhand") then
    return false
  end

  inv.offhand = inv.hand
  inv.hand = nil
  return true, "hand"
end

give_to_offhand = function(entity, this_item)
  local inv = entity.inventory
  local hand = inv.hand
  local offhand = inv.offhand
  local both = hand and offhand

  if both then
    if hand.tags.two_handed or this_item.tags.two_handed then
      
    end
  end
    is_free = (
      (not entity.inventory.offhand or item.drop(entity, "offhand"))
      and (not entity.inventory.hand
        or (not entity.inventory.hand.tags.two_handed and not this_item.tags.two_handed)
        or item.drop(entity, "hand"))
    )
end

Ldump.mark(item, {}, ...)
return item
