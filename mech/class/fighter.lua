local health = require("engine.mech.health")
local action = require("engine.tech.action")
local class  = require("engine.mech.class")
local sound  = require("engine.tech.sound")


local fighter = {}

fighter.hit_dice = class.hit_dice(10)

fighter.action_surge = Table.extend({
  name = "всплеск действий",
  codename = "action_surge",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "short" or rest_type == "long" then
      resources.action_surge = (resources.action_surge or 0) + 1
    end
    return resources
  end,

  cost = {
    actions = -1,
    action_surge = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/action_surge", .3),

  _is_available = function() return State.combat end,

  _act = function(self, entity)
    -- State:add(fx("assets/sprites/fx/action_surge", "fx_under", entity.position))
    -- NEXT (FX)
    self.sounds:play_at(entity.position)
    return true
  end,
}, action.base)

fighter.second_wind = Table.extend({
  name = "второе дыхание",
  codename = "second_wind",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "short" or rest_type == "long" then
      resources.second_wind = (resources.second_wind or 0) + 1
    end
    return resources
  end,

  cost = {
    second_wind = 1,
    bonus_actions = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/second_wind", .3),

  _is_available = function(self, entity) return entity.hp <= entity:get_max_hp() end,

  _act = function(self, entity)
    -- State:add(fx("assets/sprites/fx/second_wind", "fx_under", entity.position))
    -- NEXT (FX)
    self.sounds:play_at(entity.position)
    health.heal(entity, (D(10) + entity.level):roll())
    return true
  end,
}, action.base)

local fighting_spirit_condition = function()
  return {
    codename = "fighting_spirit_condition",

    life_time = 6,

    modify_attack_roll = function(self, entity, roll, slot)
      return roll:extended({advantage = true})  -- OPT prevent reallocation
    end,
  }
end

fighter.fighting_spirit = Table.extend({
  name = "боевой дух",
  codename = "fighting_spirit",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      resources.fighting_spirit = (resources.fighting_spirit or 0) + 3
    end
    return resources
  end,

  cost = {
    fighting_spirit = 1,
    bonus_actions = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/fighting_spirit", .3),

  _is_available = function(self, entity) return State.combat end,

  _act = function(self, entity)
    -- NEXT FX
    self.sounds:play_at(entity.position)
    table.insert(entity.conditions, fighting_spirit_condition())
    health.set_hp(entity, entity.hp + 5)
    return true
  end,
}, action.base)

fighter.fighting_styles = {}

fighter.fighting_styles.two_weapon_fighting = {
  codename = "two_weapon_fighting",

  modify_damage_roll = function(self, entity, roll, slot)
    if slot ~= "offhand" or not entity.inventory.offhand then
      return roll
    end
    return roll + entity:get_melee_modifier(slot)
  end,
}

Ldump.mark(fighter, {}, ...)
return fighter
