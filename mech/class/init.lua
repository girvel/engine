local xp = require("engine.mech.xp")
local action = require("engine.tech.action")
local health = require("engine.mech.health")
local sound  = require("engine.tech.sound")


local class = {}

--- @param die integer
--- @return action
class.hit_dice = function(die)
  return Table.extend({
    name = "перевязать раны",
    codename = "hit_dice",

    modify_max_hp = function(self, entity, value)
      return value + die + (math.floor(die / 2) + 1) * (entity.level - 1)
    end,

    modify_resources = function(self, entity, resources, rest_type)
      if rest_type == "long" then
        resources.hit_dice = (resources.hit_dice or 0) + entity.level
      end
      return resources
    end,

    cost = {
      hit_dice = 1,
    },

    sounds = sound.multiple("engine/assets/sounds/hit_dice", .3),

    _is_available = function(self, entity)
      return not State.combat and entity.hp < entity:get_max_hp()
    end,

    _act = function(self, entity)
      self.sounds:play_at(entity.position)
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

--- @param ability ability
--- @return table
class.save_proficiency = function(ability)
  return {
    codename = ability .. "_save_proficiency",

    modify_saving_throw = function(self, entity, roll, this_ability)
      if ability == this_ability then
        return roll + xp.get_proficiency_bonus(entity.level)
      end
      return roll
    end,
  }
end

Ldump.mark(class, "const", ...)
return class
