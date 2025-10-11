--- @class generation_data
--- @field entities entity[]
--- @field runner_entities table<string, entity>
--- @field atlases table<string, love.Image>

--- @param palette palette
--- @param preload_entities preload_entity[]
--- @return generation_data
local generate_entities = function(palette, preload_entities)
  return {

  }
end

Ldump.mark(generate_entities, "const", ...)
return generate_entities
