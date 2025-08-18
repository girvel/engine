local health = require "engine.mech.health"
local creature = {}

--- @class creature_mixin
--- @field resources table<string, integer>
--- @field hp integer
--- @field base_hp integer
local methods = {}

--- @return creature_mixin
creature.mixin = function()
  local result = Table.extend({
    resources = {},
  }, methods)

  return result
end

--- @param entity creature_mixin
creature.init = function(entity)
  assert(entity.base_hp, "creature requires .base_hp for %s" % {Entity.codename(entity)})
  entity:rest("full")
end

--- @alias rest_type "free"|"move"|"short"|"long"|"full"

--- @param rest_type rest_type
methods.get_resources = function(self, rest_type)
  if rest_type == "free" then
    return {
      movement = 6,
      bonus_actions = 1,
    }
  end

  if rest_type == "move" then
    return {
      actions = 1,
      bonus_actions = 1,
      reactions = 1,
      movement = 6,
    }
  end

  if rest_type == "short" then
    return {}  -- NEXT modify with effects
  end

  if rest_type == "long" then
    return {}  -- NEXT modify with effects
  end

  if rest_type == "full" then
    return Table.extend(
      self:get_resources("move"),
      self:get_resources("short"),
      self:get_resources("long")
    )
  end

  error("Unknown rest type %q" % {rest_type})
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
  -- NEXT reset HP on long
end

Ldump.mark(creature, {}, ...)
return creature
