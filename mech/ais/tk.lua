local iteration = require("engine.tech.iteration")


local tk = {}

--- @param entity entity
--- @param r number
--- @return entity?
tk.find_target = function(entity, r)
  for d in iteration.rhombus(r) do
    local e = State.grids.solids:slow_get(entity.position + d)
    if e and State.hostility:get(entity, e) then
      return e
    end
  end
end

--- @class ai_targeting
--- @field scan_period number time period determining target search frequency
--- @field scan_range number radius in which to search for target
--- @field range number radius in which to continue targeting a single entity

--- @class ai_targeting_optional
--- @field scan_period? number time period determining target search frequency
--- @field scan_range? number radius in which to search for target
--- @field range? number radius in which to continue targeting a single entity

return tk
