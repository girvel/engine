local health = require("engine.mech.health")
local action = require("engine.tech.action")


local fighter = {}

--- @type action
fighter.hit_dice = Table.extend({
  codename = "hit_dice",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      resources.hit_dice = (resources.hit_dice or 0) + entity.level
    end
    return resources
  end,

  cost = {
    hit_dice = 1,
  },

  _is_available = function(self, entity)
    return not State.combat and entity.hp <= entity:get_max_hp()
  end,

  _act = function(self, entity)
    -- sound("assets/sounds/hit_dice.mp3", .3):place(entity.position):play()
    -- NEXT (sounds)
    health.heal(entity, (D(10) + entity:get_modifier("con")):roll())
    return true
  end,
}, action.base)

fighter.action_surge = Table.extend({
  codename = "action_surge",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "short" or rest_type == "long" then
      resources.action_surge = (resources.action_surge or 0) + 1
    end
    return resources
  end,

  cost = {
    action_surge = 1,
  },

  _is_available = function() return State.combat end,

  _act = function(self, entity)
    -- State:add(fx("assets/sprites/fx/action_surge", "fx_under", entity.position))
    -- NEXT!
    -- sound("assets/sounds/action_surge.mp3", .3):place(entity.position):play()
    -- NEXT (sounds)
    entity.resources.actions = entity.resources.actions + 1
    return true
  end,
}, action.base)

fighter.second_wind = Table.extend({
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

  _is_available = function(self, entity) return entity.hp <= entity:get_max_hp() end,

  _act = function(self, entity)
    -- State:add(fx("assets/sprites/fx/second_wind", "fx_under", entity.position))
    -- NEXT!
    -- sound("assets/sounds/second_wind.mp3", .3):place(entity.position):play()
    -- NEXT (sounds)
    health.heal(entity, (D(10) + entity.level):roll())
    return true
  end,
}, action.base)

Ldump.mark(fighter, {}, ...)
return fighter
