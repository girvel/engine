--- Module with uncategorized utility functions
local common = {}

--- @generic T
--- @param value T
--- @return T
common.nil_serialized = function(value)
  Ldump.serializer.handlers[value] = "nil"
  return value
end

return common
