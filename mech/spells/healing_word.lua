local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")


local healing_word = {}

--- @class spells_healing_word: action
--- @field target entity
local methods = {}
healing_word.mt = {__index = methods}

--- @type action|table
healing_word.base = Table.extend({
  name = "Лечащее слово",
  codename = "healing_word",

  cost = {
    bonus_actions = 1,
    spell_slots_1 = 1,
  },

  range = 40,
}, action.base)

--- @param target entity
--- @return spells_healing_word
healing_word.new = function(target)
  return setmetatable(Table.extend({target = target}, healing_word.base), healing_word.mt)
end

methods._is_available = function(self, entity)
  if not (self.target
    and self.target.hp
    and self.target.hp < self.target:get_max_hp())
  then return false end

  local result do
    local vision_map = tcod.map(State.grids.solids)
    vision_map:refresh_fov(entity.position, healing_word.base.range)
    result = vision_map:is_visible_unsafe(unpack(self.target.position))
    vision_map:free()
  end

  return result
end

methods._act = function(self, entity)
  health.heal(self.target, (D(4) + entity:get_modifier("wis")):roll())
  return true
end

Ldump.mark(healing_word, {mt = "const"}, ...)
return healing_word
