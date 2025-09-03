--- Module for displaying names
local name = {}

local NO_ENTITY = "<none>"
local NO_NAME = "<no name>"

--- Get best possible in-game naming; prefers .name, then .codename, then the default value
--- @param entity entity?
--- @return string
name.game = function(entity)
  if not entity then return NO_ENTITY end
  return entity.name or entity.codename or NO_NAME
end

--- Get best possible in-code naming; prefers .codename, then .name, then the default value
--- @param entity entity?
--- @return string
name.code = function(entity)
  if not entity then return NO_ENTITY end
  return entity.codename or entity.name or NO_NAME
end

return name
