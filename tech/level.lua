--- Module for level grid logic
local level = {}

--- @alias grid_positioned {position: vector, grid_layer: string}

--- Forcefully move entity to a new position
--- @param entity grid_positioned
--- @param position vector
--- @return nil
level.unsafe_move = function(entity, position)
  assert(entity.position, "Can not move an entity without the current position")

  local grid = State.grids[entity.grid_layer]
  if grid[position] then
    Log.warn("level.unsafe_move: replacing %s with %s" % {Name.code(grid[position]), Name.code(entity)})
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
level.slow_move = function(entity, position)
  local grid = State.grids[entity.grid_layer]
  if not grid:can_fit(position) or grid[position] then return false end
  level.unsafe_move(entity, position)
  return true
end

--- Forcefully change entity's grid_layer
--- @param entity grid_positioned
--- @param new_grid_layer string
--- @return nil
level.change_grid_layer = function(entity, new_grid_layer)
  local grids = State.grids
  grids[entity.grid_layer][entity.position] = nil
  grids[new_grid_layer][entity.position] = entity
  entity.grid_layer = new_grid_layer
end

--- Put entity in its .position
--- @param entity grid_positioned
--- @return nil
level.put = function(entity)
  local grid = assert(State.grids[entity.grid_layer], "Invalid grid_layer %s" % entity.grid_layer)

  if grid[entity.position] then
    Log.warn("Grid collision at %s[%s]: %s replaces %s" % {
      entity.grid_layer, entity.position, Name.code(entity), Name.code(grid[entity.position])
    })
  end
  grid[entity.position] = entity
end

--- Remove entity from its .position
--- @param entity grid_positioned
--- @return nil
level.remove = function(entity)
  State.grids[entity.grid_layer][entity.position] = nil
end

Ldump.mark(level, {}, ...)
return level
