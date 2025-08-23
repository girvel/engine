local item = {}

item.DROPPING_SLOTS = {"hand", "offhand", "gloves", "right_pocket", "inside"}

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

Ldump.mark(item, {}, ...)
return item
