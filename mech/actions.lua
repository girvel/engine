local level = require "engine.tech.level"
local action = require "engine.tech.action"
local health = require "engine.mech.health"
local sound  = require "engine.tech.sound"
local animated = require "engine.tech.animated"


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
              and e.resources
              and State.hostility:get(e, entity)
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

      local tile = State.grids.tiles[entity.position]
      if tile and tile.sounds and tile.sounds.walk then
        tile.sounds.walk:play_at(entity.position)
      end

      return result
    end,
  }, action.base)
end

actions.dash = Table.extend({
  name = "рывок",
  codename = "dash",

  cost = {
    actions = 1,
    movement = -6,
  },

  sounds = sound.multiple("engine/assets/sounds/dash", .5),

  _act = function(self, entity)
    if State.combat then
      State:add(animated.fx("engine/assets/sprites/animations/dash", entity.position))
      self.sounds:play_at(entity.position)
    end
    return true
  end,
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
  name = "отступление",
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
  name = "атака",
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
  name = "атака вторым оружием",
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
  name = "толкнуть",
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
      State.hostility:register(entity, target)
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

local WHOOSH = sound.multiple("engine/assets/sounds/whoosh", .1)

base_attack = function(entity, slot)
  local target = State.grids.solids:slow_get(entity.position + entity.direction)

  WHOOSH:play_at(entity.position)

  entity:animate(slot .. "_attack"):next(function()
    State.hostility:register(entity, target)

    if not health.attack(
      target,
      entity:get_melee_attack_roll(slot),
      entity:get_melee_damage_roll(slot)
    ) then return end

    if target and target.sounds and target.sounds.hit then
      target.sounds.hit:play_at(target.position)
    end
  end)
end

Ldump.mark(actions, {}, ...)
return actions
