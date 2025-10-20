--- Utility function for setting :on_death & on_half_hp to generate blood marks/bodies
--- @param factory fun(): entity
--- @param grid_layer? grid_layer
--- @return fun(self: entity)
return function(factory, grid_layer)
  grid_layer = grid_layer or "marks"
  return function(self)
    local entity = factory()

    local final_position
    for d in Iteration.rhombus(2) do
      local p = d:add_mut(self.position)
      if not State.grids.tiles:can_fit(p) then goto continue end

      local mark = State.grids[grid_layer][p]
      if mark then goto continue end

      local solid = State.grids.solids[p]
      if solid and not solid.transparent_flag then goto continue end

      final_position = p
      do break end

      ::continue::
    end

    if not final_position then return end

    State:add(entity, {position = final_position, grid_layer = grid_layer})
  end
end
