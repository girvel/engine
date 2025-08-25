local xp = require("engine.mech.xp")
local action = require("engine.tech.action")
local health = require("engine.mech.health")


local class = {}

--- @param die integer
--- @return action
class.hit_dice = function(die)
  return Table.extend({
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
      health.heal(entity, (D(die) + entity:get_modifier("con")):roll())
      return true
    end,
  }, action.base)
end

--- @param skill skill
--- @return table
class.skill_proficiency = function(skill)
  return {
    codename = skill .. "_proficiency",

    modify_skill_score = function(self, entity, score, this_skill)
      if this_skill == skill then
        score = score + xp.get_proficiency_bonus(entity.level)
      end
      return score
    end,
  }
end

Ldump.mark(class, {}, ...)
return class
