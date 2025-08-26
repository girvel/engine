local xp = require("engine.mech.xp")
local health = require "engine.mech.health"
local abilities = require "engine.mech.abilities"
local creature = {}

--- @class _creature_methods
local methods = {}

--- @return entity
creature.mixin = function()
  local result = Table.extend({
    resources = {},
    inventory = {},
    perks = {},
    conditions = {},
  }, methods)

  return result
end

--- @param entity entity
creature.init = function(entity)
  Table.assert_fields(entity, {"base_abilities", "level"})
  entity:rest("full")
  entity:rotate(entity.direction or Vector.right)
end

--- @alias creature_modification "resources"|"max_hp"|"ability_score"|"skill_score"|"attack_roll"|"damage_roll"|"opportunity_attack_trigger"

--- @param self entity
--- @param modification creature_modification
--- @param value any
--- @param ... any
methods.modify = function(self, modification, value, ...)
  local additional_args = {...}
  modification = "modify_" .. modification
  return Fun.iter(self.perks)
    :chain(self.conditions)
    :filter(function(p) return p[modification] end)
    :reduce(
      function(acc, p) return p[modification](p, self, acc, unpack(additional_args)) end,
      value
    )
end

--- @alias rest_type "free"|"move"|"short"|"long"|"full"

--- @param self entity
--- @param rest_type rest_type
methods.get_resources = function(self, rest_type)
  local result = {}
  if rest_type == "free" then
    result = {
      movement = 6,
      bonus_actions = 1,
    }
  elseif rest_type == "move" then
    result = {
      actions = 1,
      bonus_actions = 1,
      reactions = 1,
      movement = 6,
    }
  elseif rest_type == "short" then
    result = {}
  elseif rest_type == "long" then
    result =  {}
  elseif rest_type == "full" then
    return Table.extend(
      self:get_resources("move"),
      self:get_resources("short"),
      self:get_resources("long")
    )
  else
    error("Unknown rest type %q" % {rest_type})
  end

  return self:modify("resources", result, rest_type)
end

--- @param self entity
methods.get_max_hp = function(self)
  return math.max(1, self:modify("max_hp", self.level * self:get_modifier("con")))
end

--- @param self entity
--- @param rest_type rest_type
methods.rest = function(self, rest_type)
  if rest_type == "long" or rest_type == "full" then
    health.set_hp(self, self:get_max_hp())
  end

  Table.extend(self.resources, self:get_resources(rest_type))
end

--- @param self entity
methods.rotate = function(self, direction)
  self.direction = direction
  for _, item in pairs(self.inventory) do
    item.direction = direction
  end
  if self.animate then
    self:animate()
  end
end

--- Compute armor class; takes priority over .armor
--- @param self entity
methods.get_armor = function(self)
  return 10 + self:get_modifier("dex")
end

--- @param self entity
--- @param ability ability|skill
methods.get_modifier = function(self, ability)
  if abilities.set[ability] then
    return abilities.get_modifier(self:modify(
      "ability_score",
      self.base_abilities[ability],
      ability
    ))
  end

  assert(abilities.skill_bases[ability], "%s is not a skill nor an ability" % {ability})

  return self:modify(
    "skill_score",
    self:get_modifier(abilities.skill_bases[ability]),
    ability
  )
end

--- @param self entity
--- @param to_check ability|skill
--- @param dc integer difficulty class
--- @return boolean
methods.ability_check = function(self, to_check, dc)
  local roll = D(20) + self:get_modifier(to_check)
  local result = roll:roll()

  Log.debug("%s rolls check %s: %s against %s" % {
    Entity.name(self), to_check, result, dc
  })

  local success = result >= dc

  -- NEXT (sound)
  -- sound.play(
  --   ability_check_sound[success and "success" or "failure"],
  --   self.position,
  --   "small"
  -- )

  return success
end

--- @param self entity
--- @param slot string
--- @return integer
methods.get_melee_modifier = function(self, slot)
  local weapon = self.inventory[slot]
  if weapon and weapon.tags and weapon.tags.finesse then
    return math.max(
      self:get_modifier("str"),
      self:get_modifier("dex")
    )
  end
  return self:get_modifier("str")
end

--- @param self entity
--- @param slot string
methods.get_melee_attack_roll = function(self, slot)
  local roll = D(20)
    + xp.get_proficiency_bonus(self.level)
    + self:get_melee_modifier(slot)

  local weapon = self.inventory[slot]
  if weapon then
    roll = roll + weapon.bonus
  end

  return self:modify("attack_roll", roll, slot)
end

--- @param self entity
--- @param slot string
methods.get_melee_damage_roll = function(self, slot)
  local weapon = self.inventory[slot]
  if not weapon then
    return D.new({}, self:get_modifier("str") + 1)
  end

  local roll
  if weapon.tags.versatile and not self.inventory.other_hand then
    roll = D(weapon.damage_roll.dice[1].sides_n + 2)
  else
    roll = weapon.damage_roll
  end

  roll = roll + weapon.bonus

  if slot == "hand" then
    roll = roll + self:get_melee_modifier(slot)
  end

  return self:modify("damage_roll", roll, slot)
end

Ldump.mark(creature, {}, ...)
return creature
