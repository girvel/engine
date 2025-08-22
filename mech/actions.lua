local level = require "engine.tech.level"
local action = require "engine.tech.action"


local actions = {}

--- @param direction vector
--- @return action
actions.move = function(direction)
  return Table.extend({
    cost = {
      movement = 1,
    },
    _run = function(_, entity)
      if entity.rotate then
        entity:rotate(direction)
      elseif entity.direction then
        entity.direction = direction
      end

      local result = level.safe_move(entity, entity.position + direction)
      if result and entity.animate then
        entity:animate("move")
      end
      return result
      -- NEXT reaction, animation, sound
    end,
  }, action.base)
end

Ldump.mark(actions, {}, ...)
return actions
