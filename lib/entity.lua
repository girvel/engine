--- Module for in-game entities
local entityx = {}

--- @class base_entity
--- @field name? string in-game name
--- @field codename? string in-code name
--- @field view? string entity's coordinate system's (offset + scale) name
--- @field position? vector position relative to the view
--- @field size? vector
--- @field layer? string name of the grid layer
--- @field ai? ai
--- @field shader? shader
---
--- @field player_flag? true marks player character for level loading
--- @field transparent_flag? true marks entities that block path, but not vision
--- @field perspective_flag? true marks entities that could be seen only from below
--- @field low_flag? true disable reflections TODO move it somewhere, it's not part of engine logic

--- Check is given position over the entity's hitbox
--- @param position vector
--- @param entity base_entity
--- @return boolean
entityx.is_over = function(position, entity)
  return position >= entity.position and position < entity.position + entity.size
end

local NO_ENTITY = "<none>"
local NO_NAME = "<no name>"

--- Get best possible in-game naming; prefers .name, then .codename, then the default value
--- @param entity base_entity?
--- @return string
entityx.name = function(entity)
  if not entity then return NO_ENTITY end
  return entity.name or entity.codename or NO_NAME
end

--- Get best possible in-code naming; prefers .codename, then .name, then the default value
--- @param entity base_entity?
--- @return string
entityx.codename = function(entity)
  if not entity then return NO_ENTITY end
  return entity.codename or entity.name or NO_NAME
end

return entityx
