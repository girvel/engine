local state = {}

--- @class state
--- @field display state_display
--- @field _world table
local state_methods
state.mt = {__index = state_methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    display = require("engine.state.display").new(),

    _world = Tiny.world(unpack(systems)),
  }, state.mt)
end

return Ldump.mark(state, {}, ...)
