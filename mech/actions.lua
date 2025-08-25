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

      if State.grids.solids:slow_get(entity.position + direction, true) then
        return false
      end

      if entity:modify("opportunity_attack_trigger", true) then
        Fun.iter(Vector.directions)
          :map(function(d) return State.grids.solids:slow_get(entity.position + d), d end)
          :filter(function(e)
            return e
              -- and hostility.are_hostile(entity, e)
              -- NEXT (on combat AI)
              and e.resources
            end)
          :each(function(e, d)
            e:rotate(-d)
            actions.opportunity_attack:act(e)
          end)
      end

      local result = level.unsafe_move(entity, entity.position + direction)
      if result and entity.animate then
        entity:animate("move")
      end
      return result
      -- NEXT sound
    end,
  }, action.base)
end

actions.dash = Table.extend({
  codename = "dash",

  cost = {
    actions = 1,
    movement = -6,
  },
}, action.base)

local disengaged = function()
  return {
    codename = "disengaged",

    life_time = 6,

    modify_opportunity_attack_trigger = function(self, entity, triggered)
      return false
    end,
  }
end

actions.disengage = Table.extend({
  codename = "disengage",

  cost = {
    actions = 1,
  },

  _is_available = function() return State.combat end,

  _act = function(self, entity)
    table.insert(entity.conditions, disengaged())
    return true
  end,
}, action.base)

local base_attack

--- @type action
actions.hand_attack = Table.extend({
  codename = "hand_attack",

  cost = {
    actions = 1,
  },

  _is_available = function(_, entity)
    local target = State.grids.solids:slow_get(entity.position + entity.direction)
    return target and target.hp
  end,

  _act = function(_, entity)
    base_attack(entity, "hand")
    return true
  end,
}, action.base)

--- @type action
actions.opportunity_attack = Table.extend({
  codename = "reaction_attack",

  cost = {
    reactions = 1,
  },

  _is_available = function(_, entity)
    local target = State.grids.solids:slow_get(entity.position + entity.direction)
    return target and target.hp
  end,

  _act = function(_, entity)
    base_attack(entity, "hand")
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
    local target = State.grids.solids:slow_get(entity.position + entity.direction)
    return target and target.hp and entity.inventory.offhand
  end,

  _act = function(_, entity)
    base_attack(entity, "offhand")
    return true
  end,
}, action.base)

--- @type action
actions.shove = Table.extend({
  codename = "shove",

  cost = {
    bonus_actions = 1,
  },

  _is_available = function(_, entity)
    local target = State.grids.solids:slow_get(entity.position + entity.direction)
    return target and target.hp and target.get_modifier and not entity.inventory.offhand
  end,

  _act = function(_, entity)
    local target = State.grids.solids:slow_get(entity.position + entity.direction)
    local direction = entity.direction
    entity:animate("offhand_attack"):next(function()
      -- NEXT sound
      local dc = (D(20) + target:get_modifier("acrobatics")):roll()
      local distance = math.ceil(entity:get_modifier("athletics") / 4)

      if distance <= 0 or not entity:ability_check("athletics", dc) then
        State:add(health.floater("-", target.position, health.COLOR_DAMAGE))
        return
      end

      for remains = distance, 1, -1 do
        local next_p = target.position + direction
        if not level.slow_move(target, next_p) and
          (remains == 1 or not State.grids.solids:slow_get(next_p).low_flag)
        then
          health.damage(target, D(2 + remains * 2):roll(), false)
          break
        end
      end
    end)
    return true
  end,
}, action.base)

base_attack = function(entity, slot)
  local target = State.grids.solids:slow_get(entity.position + entity.direction)

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
