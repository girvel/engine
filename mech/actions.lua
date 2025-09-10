local xp = require("engine.mech.xp")
local level = require "engine.tech.level"
local action = require "engine.tech.action"
local health = require "engine.mech.health"
local sound  = require "engine.tech.sound"
local animated = require "engine.tech.animated"
local interactive = require "engine.tech.interactive"
local tcod        = require "engine.tech.tcod"


local actions = {}

--- @type table<entity, sound>
local last_walk_sound = setmetatable({}, {__mode = "k"})

--- @param direction vector
--- @return action
actions.move = Memoize(function(direction)
  return Table.extend({
    codename = "move_" .. Vector.name_from_direction(direction),

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
              and State.hostility:get(e, entity) == "enemy"
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
      local prev_tile = State.grids.tiles[entity.position - entity.direction]
      local sounds = tile and tile.sounds and tile.sounds.walk
      if sounds and (  -- preventing ear DDOS with repetitive sounds
        not prev_tile
        or prev_tile.codename ~= tile.codename
        or not last_walk_sound[entity]
        or not last_walk_sound[entity].source:isPlaying()
      ) then
        if entity == State.player then
          last_walk_sound[entity] = sounds:play()
        else
          last_walk_sound[entity] = sounds:play_at(entity.position)
        end
      end

      return result
    end,
  }, action.base)
end)

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
    return target
      and target.hp
      and (not entity.inventory.offhand or not entity.inventory.offhand.tags.ranged)
      and State.hostility:get(entity, target) ~= "ally"
  end,

  _act = function(_, entity)
    base_attack(entity, "hand")
    return true
  end,

  get_hint = function(self, entity)
    return "%s (%s)" % {
      Name.game(self),
      entity:get_melee_damage_roll("hand"):simplified()
    }
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
    return target
      and target.hp
      and entity.inventory.offhand
      and entity.inventory.offhand.damage_roll
      and not entity.inventory.offhand.tags.ranged
      and State.hostility:get(entity, target) ~= "ally"
  end,

  _act = function(_, entity)
    base_attack(entity, "offhand")
    return true
  end,

  get_hint = function(self, entity)
    return "%s (%s)" % {
      Name.game(self),
      entity:get_melee_damage_roll("offhand"):simplified()
    }
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
    return target
      and target.hp
      and (not target.inventory.offhand or not target.inventory.offhand.tags.ranged)
  end,

  _act = function(_, entity)
    base_attack(entity, "hand")
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
    return target
      and target.hp
      and target.get_modifier
      and not (entity.inventory.offhand and entity.inventory.offhand.damage_roll)
      and State.hostility:get(entity, target) ~= "ally"
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

actions.bow_attack_base = Table.extend({
  name = "выстрелить",
  codename = "bow_attack",

  cost = {
    actions = 1,
  },

  _is_available = function(self, entity)
    return entity.inventory
      and entity.inventory.offhand
      and entity.inventory.offhand.tags.ranged
  end,

  get_hint = function(self, entity)
    return "%s (%s)" % {
      Name.game(self),
      entity:get_ranged_damage_roll():simplified(),
    }
  end
}, action.base)

actions.bow_attack = function(target)
  return Table.extend({}, actions.bow_attack_base, {
    _is_available = function(self, entity)
      if not (actions.bow_attack_base:_is_available(entity)
        and target
        and target.hp
        and State.hostility:get(entity, target) ~= "ally")
      then return false end

      local snapshot = tcod.copy(State.grids.solids)
      snapshot:refresh_fov(entity.position, 15)
      local result = snapshot:is_visible_unsafe(unpack(target.position))
      snapshot:free()
      return result
    end,

    _act = function(self, entity)
      local d = (target.position - entity.position)
      if d ~= Vector.zero then
        entity:rotate(d:normalized2())
      end
      entity:animate("bow_attack"):next(function()
        -- SOUND bow
        local attack_roll = entity:get_ranged_attack_roll()
        if d:abs() == 1 then
          attack_roll = attack_roll:extended({advantage = "disadvantage"})
        end
        health.attack(
          target,
          attack_roll,
          entity:get_ranged_damage_roll()
        )
        State.hostility:register(entity, target)
        -- SOUND hit
      end)
      return true
    end,
  })
end

actions.interact = Table.extend({
  name = "взаимодействовать",
  codename = "interact",

  cost = {
    bonus_actions = 1,
  },

  _is_available = function(self, entity)
    return interactive.get_for(entity)
  end,

  _act = function(self, entity)
    assert(interactive.get_for(entity)):interact(entity)
    return true
  end,
}, action.base)

Ldump.mark(actions, {}, ...)
return actions
