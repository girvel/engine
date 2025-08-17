local creature = {}

--- @class creature
--- @field resources table<string, integer>
local methods = {}

--- @return creature
creature.new = function()
  local result = Table.extend({
    resources = {},
  }, methods)

  result:rest("full")
  return result
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

--- @param rest_type rest_type
methods.rest = function(self, rest_type)
  Table.extend(self.resources, self:get_resources(rest_type))
  -- NEXT reset HP on long
end

Ldump.mark(creature, {}, ...)
return creature
