--- Module for in-game entities
local entityx = {}

--- @class entity: _creature_methods
--- @field name string in-game name
--- @field codename string in-code name
--- @field view string entity's coordinate system's (offset + scale) name
--- @field position vector position relative to the view
--- @field direction vector
--- @field size vector
--- @field layer string name of the grid layer
--- @field ai ai
--- @field shader shader individial shader to render with
--- @field sprite sprite
--- @field animation animation
--- @field animate fun(entity, string?): promise
--- @field animation_set_paused fun(entity, boolean)
---
--- @field base_abilities abilities ability scores before perks/level-ups
--- @field level integer
--- @field resources table<string, integer> resources to spend on actions
--- @field inventory table<string, item>
--- @field hp integer current health points
--- @field armor integer static armor class; less priority than :get_armor()
--- @field perks table[] all class, feat, race perks that modify default creature behavior
--- @field conditions table[] like .perks, but temporary
---
--- @field player_flag? true marks player character for level loading
--- @field transparent_flag? true marks entities that block path, but not vision
--- @field perspective_flag? true marks entities that could be seen only from below
--- @field low_flag? true entity is low: disable reflections, shove may go over
--- @field boring_flag? true disable log messages about the entity because it's dull

--- Check is given position over the entity's hitbox
--- @param position vector
--- @param entity entity
--- @return boolean
entityx.is_over = function(position, entity)
  return position >= entity.position and position < entity.position + entity.size
end

local NO_ENTITY = "<none>"
local NO_NAME = "<no name>"

--- Get best possible in-game naming; prefers .name, then .codename, then the default value
--- @param entity entity?
--- @return string
entityx.name = function(entity)
  if not entity then return NO_ENTITY end
  return entity.name or entity.codename or NO_NAME
end

--- Get best possible in-code naming; prefers .codename, then .name, then the default value
--- @param entity entity?
--- @return string
entityx.codename = function(entity)
  if not entity then return NO_ENTITY end
  return entity.codename or entity.name or NO_NAME
end

return entityx
