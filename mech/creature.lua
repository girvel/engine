local health = require "engine.mech.health"
local creature = {}

local methods = {}

--- @return entity
creature.mixin = function()
  local result = Table.extend({
    resources = {},
    inventory = {},
    perks = {},
  }, methods)

  return result
end

--- @param entity entity
creature.init = function(entity)
  assert(entity.base_hp, "creature requires .base_hp for %s" % {Entity.codename(entity)})
  entity:rest("full")
  entity:rotate(entity.direction or Vector.right)
end

--- @param self entity
--- @param name string
--- @param value any
--- @param ... any
methods.modify = function(self, name, value, ...)
  local additional_args = {...}
  name = "modify_" .. name
  return Fun.iter(self.perks)
    :filter(function(p) return p[name] end)
    :reduce(
      function(acc, p) return p[name](p, self, acc, unpack(additional_args)) end,
      value
    )
end

--- @alias rest_type "free"|"move"|"short"|"long"|"full"

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

  return self:modify("get_resources", result, rest_type)
end

methods.get_max_hp = function(self)
  -- TODO effects
  return self.base_hp
end

--- @param rest_type rest_type
methods.rest = function(self, rest_type)
  if rest_type == "long" or rest_type == "full" then
    health.set_hp(self, self:get_max_hp())
  end

  Table.extend(self.resources, self:get_resources(rest_type))
end

methods.rotate = function(self, direction)
  self.direction = direction
  for _, item in pairs(self.inventory) do
    item.direction = direction
  end
  if self.animate then
    self:animate()
  end
end

methods.get_armor = function(self)
  return
  -- NEXT (when class) use abilities
end

--- @param self entity
--- @param slot string
methods.get_melee_attack_roll = function(self, slot)
  return D(20)
  -- NEXT (when class)
  -- local roll = D(20)
  --   + experience.get_proficiency_modifier(self.level)
  --   + abilities.get_melee_modifier(self, slot)

  -- local weapon = self.inventory[slot]
  -- if weapon then
  --   roll = roll + weapon.bonus
  -- end

  -- return self:get_effect("modify_attack_roll", roll)
end

--- @param self entity
--- @param slot string
methods.get_melee_damage_roll = function(self, slot)
  return D(4)
  -- NEXT (class)
  -- local weapon = self.inventory[slot]
  -- if not weapon then
  --   return D.roll({}, self:get_modifier("str") + 1)
  -- end

  -- local roll
  -- if weapon.tags.versatile and not self.inventory.other_hand then
  --   roll = D(weapon.damage_roll.dice[1].sides_n + 2)
  -- else
  --   roll = weapon.damage_roll
  -- end

  -- roll = roll + weapon.bonus

  -- if slot == "main_hand" then
  --   roll = roll + abilities.get_melee_modifier(self, slot)
  -- end

  -- return self:get_effect("modify_damage_roll", roll, slot)
end

Ldump.mark(creature, {}, ...)
return creature
