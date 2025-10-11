local preload = require("engine.tech.ldtk.preload")
local generate_entities = require("engine.tech.ldtk.generate_entities")
local read_json         = require("engine.tech.ldtk.read_json")


local ldtk = {}

----------------------------------------------------------------------------------------------------
-- [Section] External API
----------------------------------------------------------------------------------------------------

--- @alias palette table<string, table<string | integer, function>>

--- Level's init.lua return
--- @class level_definition
--- @field ldtk_path string
--- @field palette palette
--- @field rails rails
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
  local json = read_json(definition.ldtk_path)
  coroutine.yield(.4)
  local preload_data = preload(json)
  coroutine.yield(.5)
  local generation_data = generate_entities(definition.palette, preload_data.entities)

  return {
    level_info = {
      atlases = generation_data.atlases,
      grid_size = preload_data.size,
    },
    entities = generation_data.entities,
    rails = definition.rails,
    runner_entities = generation_data.runner_entities,
    runner_positions = preload_data.positions,
    runner_scenes = definition.scenes,
  }
end

----------------------------------------------------------------------------------------------------
-- [Section] Implementation
----------------------------------------------------------------------------------------------------

Ldump.mark(ldtk, {}, ...)
return ldtk
