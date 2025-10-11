local preload = require("engine.tech.ldtk.preload")


local ldtk = {}

----------------------------------------------------------------------------------------------------
-- [Section] External API
----------------------------------------------------------------------------------------------------

--- Level's init.lua return
--- @class level_definition
--- @field ldtk_path string
--- @field palette table<string, table<string | integer, function>>
--- @field rails_factory (fun(...): rails)
--- @field scenes runner_scenes

--- General information about the level
--- @class level_info
--- @field atlases table<string, love.Image> atlas images for each grid_layer that uses them
--- @field grid_size vector

--- @class load_result
--- @field level_info level_info
--- @field entities entity[]
--- @field rails rails
--- @field runner_entities table<string, entity>
--- @field runner_positions table<string, vector>
--- @field runner_scenes runner_scenes

--- Read LDtk level file
--- @async
--- @param path string
--- @return load_result
ldtk.load = function(path)
  local definition = love.filesystem.load(path .. "/init.lua")() --[[@as level_definition]]
  local preload_data = preload(definition.ldtk_path)
  Error(preload_data)
end

----------------------------------------------------------------------------------------------------
-- [Section] Implementation
----------------------------------------------------------------------------------------------------

Ldump.mark(ldtk, {}, ...)
return ldtk
