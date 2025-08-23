local level = require "engine.tech.level"
local action = require "engine.tech.action"
local health = require "engine.mech.health"


local actions = {}

--- @param direction vector
--- @return action
actions.move = function(direction)
  return Table.extend({
    cost = {
      movement = 1,
    },
    _act = function(_, entity)
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
      -- NEXT reaction, sound
    end,
  }, action.base)
end

--- @type action
actions.hand_attack = Table.extend({
  cost = {
    actions = 1,
  },
  _is_available = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    return target and target.hp
  end,
  _act = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    entity:animate("hand_attack"):next(function()
      health.attack(target, D(20), D(4) + 1)
    end)
  end,
}, action.base)

Ldump.mark(actions, {}, ...)
return actions
