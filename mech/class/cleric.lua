local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")
local class = require("engine.mech.class")


local cleric = {}

cleric.hit_dice = class.hit_dice(8)

cleric.spell_slots = {
  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      if entity.level == 1 then
        resources.spell_slots_1 = 2
      elseif entity.level == 2 then
        resources.spell_slots_1 = 3
      else
        resources.spell_slots_1 = 4
      end

      if entity.level >= 4 then
        resources.spell_slots_2 = 3
      elseif entity.level >= 3 then
        resources.spell_slots_2 = 2
      end

      if entity.level >= 6 then
        resources.spell_slots_3 = 3
      elseif entity.level >= 5 then
        resources.spell_slots_3 = 2
      end
    end
    return resources
  end,
}

cleric.healing_word_base = Table.extend({
  name = "Лечащее слово",
  codename = "healing_word",

  cost = {
    bonus_actions = 1,
    spell_slots_1 = 1,
  },

  range = 40,
}, action.base)

--- @param target entity
cleric.healing_word = function(target)
  return Table.extend({}, cleric.healing_word_base, {
    _is_available = function(self, entity)
      if not (target
        and target.hp
        and target.hp < target:get_max_hp())
      then return false end

      local result do
        local vision_map = tcod.map(State.grids.solids)
        vision_map:refresh_fov(entity.position, cleric.healing_word_base.range)
        result = vision_map:is_visible_unsafe(unpack(target.position))
        vision_map:free()
      end

      return result
    end,

    --- @param entity entity
    _act = function(self, entity)
      health.heal(target, (D(4) + entity:get_modifier("wis")):roll())
      return true
    end,
  })
end

return cleric
