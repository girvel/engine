local level = require "engine.tech.level"
local action= require "engine.tech.action"
local actions = {}

--- @param direction vector
--- @return action
actions.move = function(direction)
  return Table.extend({
    cost = {
      movement = 1,
    },
    _run = function(_, entity)
      return level.safe_move(entity, entity.position + direction)
      -- NEXT reaction, animation, sound
    end,
  }, action.base)
end

Ldump.mark(actions, {}, ...)
return actions
