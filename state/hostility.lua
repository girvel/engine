local hostility = {}

--- @class state_hostility
--- @field _are_hostile table<string, boolean>
local methods = {}
local mt = {__index = methods}

--- @return state_hostility
hostility.new = function()
  return setmetatable({
    _are_hostile = {},
  }, mt)
end

--- @param a entity
--- @param b entity
--- @return boolean
methods.get = function(self, a, b)
  if not a.faction or not b.faction then
    return false
  end
  return not not self._are_hostile[a.faction .. "_to_" .. b.faction]
end

--- @param faction_a string
--- @param faction_b string
--- @param value boolean
methods.set = function(self, faction_a, faction_b, value)
  self._are_hostile[faction_a .. "_to_" .. faction_b] = value or nil
end

Ldump.mark(hostility, {}, ...)
return hostility
