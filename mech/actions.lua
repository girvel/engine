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

local base_attack

--- @type action
actions.hand_attack = Table.extend({
  codename = "hand_attack",

  cost = {
    actions = 1,
  },

  _is_available = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    return target and target.hp
  end,

  _act = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    base_attack(entity, target, "hand")
    return true
  end,
}, action.base)

--- @type action
actions.offhand_attack = Table.extend({
  codename = "offhand_attack",

  cost = {
    bonus_actions = 1,
  },

  _is_available = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    return target and target.hp and entity.inventory.offhand
  end,

  _act = function(_, entity)
    local target = State.grids.solids:safe_get(entity.position + entity.direction)
    base_attack(entity, target, "offhand")
    return true
  end,
}, action.base)

base_attack = function(entity, target, slot)
  local direction = target.position - entity.position
  assert(direction:abs() == 1)
  entity:rotate(direction)

  -- sound.play("assets/sounds/whoosh", 0.1, entity.position)
  -- NEXT (sounds)

  entity:animate(slot .. "_attack"):next(function()
    -- State:register_aggression(entity, target)
    -- NEXT (combat AI)

    if not health.attack(
      target,
      entity:get_melee_attack_roll(slot),
      entity:get_melee_damage_roll(slot)
    ) then return end

    -- if target and target.sounds and target.sounds.hit then
    --   sound.play(target.sounds.hit, target.position)
    -- end
    -- NEXT (sounds)

    -- if target.hardness and not -Query(entity).inventory[slot] then
    --   attacking.attack_save(entity, "con", target.hardness, D.roll({}, 1))
    -- end
  end)
end

Ldump.mark(actions, {}, ...)
return actions
