local state = {}

--- @class state
--- @field _world table
local state_methods
state.mt = {__index = state_methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    _world = Tiny.world(unpack(systems)),
  }, state.mt)
end

return state
