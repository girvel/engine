local combat = {}
-- NEXT rename to round_robin

--- @class state_combat
--- @field list base_entity[]
--- @field current_i integer
local methods = {}
local mt = {__index = methods}

--- @param list base_entity[]
--- @return state_combat
combat.new = function(list)
  assert(Fun.iter(list):all(function(e) return State:exists(e) end))
  return setmetatable({
    list = list,
    current_i = 1,
  }, mt)
end

methods.get_current = function(self)
  return self.list[self.current_i]
end

methods._pass_turn = function(self)
  self.current_i = Math.loopmod(self.current_i + 1, #self.list)
end

Ldump.mark(combat, {}, ...)
return combat
