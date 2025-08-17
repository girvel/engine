local level = require "engine.tech.level"
local base_actions = {}

base_actions.move = function(direction)
  return {
    run = function(_, entity)
      if entity.resources.movement <= 0 then return false end
      entity.resources.movement = entity.resources.movement - 1
      return level.safe_move(entity, entity.position + direction)
      -- NEXT reaction, animation, sound
    end,
  }
end

Ldump.mark(base_actions, {}, ...)
return base_actions
