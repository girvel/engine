local state = {}

--- @class state
--- @field mode state_mode
--- @field _world table
local state_methods
state.mt = {__index = state_methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    mode = require("engine.state.mode").new(),

    _world = Tiny.world(unpack(systems)),
  }, state.mt)
end

return Ldump.mark(state, {}, ...)
