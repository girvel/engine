local item = {}

item.DROPPING_SLOTS = {"hand", "offhand", "gloves", "right_pocket", "inside"}

--- @class item: entity
--- @field tags table<string, true>
--- @field slot string

--- @param parent entity
--- @param slot string | integer
--- @return boolean
item.drop = function(parent, slot)
  local drop_position = Fun.chain({Vector.zero}, Vector.directions)
    :map(function(d) return parent.position + d end)
    :filter(function(v)
      return (v == parent.position or not State.grids.solids:safe_get(v, true))
        and not State.grids.items[v]
    end)
    :nth(1)
  if not drop_position then return false end

  local this_item = parent.inventory[slot]
  if not this_item then return true end

  parent.inventory[slot] = nil
  this_item.position = drop_position
  this_item.layer = "items"
  this_item.view = "grids"
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
        (not entity.inventory.main_hand or item.drop(entity, "main_hand"))
        and (not entity.inventory.other_hand or item.drop(entity, "other_hand"))
      )
      slot = "main_hand"
    else
      if not entity.inventory.main_hand
        or (not entity.inventory.main_hand.tags.light and item.drop(entity, "main_hand"))
      then
        slot = "main_hand"
        is_free = true
      elseif entity.inventory.main_hand.tags.light and not entity.inventory.other_hand then
        slot = "other_hand"
        is_free = true
      elseif entity.inventory.main_hand.tags.light and item.drop(entity, "other_hand") then
        entity.inventory.other_hand = entity.inventory.main_hand
        entity.inventory.main_hand = nil
        slot = "main_hand"
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

Ldump.mark(item, {}, ...)
return item
