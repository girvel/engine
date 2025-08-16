--- Module for level grid logic
local level = {}

--- @alias grid_positioned {position: vector, layer: string}

--- Forcefully move entity to a new position
--- @param entity grid_positioned
--- @param position vector
--- @return nil
level.move = function(entity, position)
  assert(entity.position, "Can not move an entity without the current position")

  local grid = State.grids[entity.layer]
  if grid[position] then
    Log.warn("level.move: replacing %s with %s" % {Entity.name(grid[position]), Entity.name(entity)})
  end
  grid[entity.position] = nil
  grid[position] = entity
  entity.position = position
  return true
end

--- Safely move entity to a new position
--- @param entity grid_positioned
--- @param position vector
--- @return boolean # false if position is out of grid's bounds or the new position is occupied
level.safe_move = function(entity, position)
  local grid = State.grids[entity.layer]
  if not grid:can_fit(position) or grid[position] then return false end
  level.move(entity, position)
  return true
end

--- Forcefully change entity's layer
--- @param entity grid_positioned
--- @param new_layer string
--- @return nil
level.change_layer = function(entity, new_layer)
  local grids = State.grids
  grids[entity.layer][entity.position] = nil
  grids[new_layer][entity.position] = entity
  entity.layer = new_layer
end

--- Put entity in its .position
--- @param entity grid_positioned
--- @return nil
level.put = function(entity)
  local grid = assert(State.grids[entity.layer], "Invalid layer %s" % entity.layer)

  if grid[entity.position] then
    Log.warn("Grid collision at %s[%s]: %s replaces %s" % {
      entity.layer, entity.position, Entity.name(entity), Entity.name(grid[entity.position])
    })
  end
  grid[entity.position] = entity
end

--- Remove entity from its .position
--- @param entity grid_positioned
--- @return nil
level.remove = function(entity)
  State.grids[entity.layer][entity.position] = nil
end

Ldump.mark(level, {}, ...)
return level
