local action = require("engine.tech.action")


local fighter = {}

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
    -- State:add(fx("assets/sprites/fx/action_surge_proto", "fx_under", entity.position))
    -- NEXT!
    -- sound("assets/sounds/action_surge.mp3", .3):place(entity.position):play()
    -- NEXT (sounds)
    entity.resources.actions = entity.resources.actions + 1
    return true
  end,
}, action.base)

Ldump.mark(fighter, {}, ...)
return fighter
