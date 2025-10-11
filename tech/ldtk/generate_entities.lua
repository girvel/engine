local level = require "engine.tech.level"


--- @class generation_data
--- @field entities entity[]
--- @field runner_entities table<string, entity>
--- @field atlases table<string, love.Image>

--- @param palette palette
--- @param preload_entities table<layer|string, preload_entity[]>
--- @return generation_data
local generate_entities = function(palette, preload_entities)
  local start_t = love.timer.getTime()
  local result = {
    entities = {},
    runner_entities = {},
    atlases = {},
  }

  for layer, stream in pairs(preload_entities) do
    if #stream == 0 then goto continue end

    local subpalette = palette[layer]
    if not subpalette then
      Error("No subpalette for layer %q", layer)
      goto continue
    end

    local is_visible = Table.contains(level.layers, layer)
    local is_grid_layer = is_visible and Table.contains(level.grid_layers, layer)

    if subpalette.ATLAS_IMAGE then
      if not is_grid_layer then
        Error("Layer %q is not a grid_layer, no ATLAS_IMAGE required", layer)
      end
      result.atlases[layer] = subpalette.ATLAS_IMAGE
    end

    for _, entry in ipairs(stream) do
      local factory = subpalette[entry.identifier]
      if not factory then
        Error("Missing entity factory %q in layer %q", entry.identifier, layer)
        goto continue_stream
      end

      local entity = factory(entry.args and Common.eval(entry.args))

      if entry.rails_name then
        if not entity then
          Error("Entity capture at %s@%s attempted, but factory returned no entity",
            layer, entry.position)
        else
          result.runner_entities[entry.rails_name] = entity
        end
      end

      if not entity then goto continue_stream end

      if entity.player_flag then
        State.player = entity
      end

      entity.position = entry.position
      if is_grid_layer then
        entity.grid_layer = layer
      elseif is_visible then
        entity.layer = layer
      end

      table.insert(result.entities, entity)

      ::continue_stream::
    end

    ::continue::
  end

  Log.info("Generated entities in %.2f s", love.timer.getTime() - start_t)
  return result
end

Ldump.mark(generate_entities, "const", ...)
return generate_entities
