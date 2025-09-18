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

return tk
