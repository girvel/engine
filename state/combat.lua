local combat = {}

--- @class state_combat
--- @field list base_entity[]
--- @field current_i integer
local methods = {}
local mt = {__index = methods}

--- @param list base_entity[]
--- @return state_combat
combat.new = function(list)
  -- NEXT! consider combat turn?
  assert(Fun.iter(list):all(function(e) return State:exists(e) end))
  return setmetatable({
    list = list,
    current_i = 1,
  }, mt)
end

Ldump.mark(combat, {}, ...)
return combat
