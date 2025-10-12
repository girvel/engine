--- Convience module for randomization
local random = {}

--- Returns true with given chance
--- @param chance number
--- @return boolean
random.chance = function(chance)
	return math.random() < chance
end

--- @generic T
--- @param ... T
--- @return T
random.choice = function(...)
  local len = select("#", ...)
  assert(len > 0, "Can not random.choice with empty list")
  return select(math.random(len), ...)
end

--- Chooses random element from the list
--- @generic T
--- @param list T[]
--- @return T
random.item = function(list)
  assert(#list > 0, "Can not random.choice with empty list")
  return list[math.random(#list)]
end

--- Random float in range
--- @param a number
--- @param b number
--- @return number
random.float = function(a, b)
  return math.random() * (b - a) + a
end

return random
