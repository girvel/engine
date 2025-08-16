local ldtk = {}

local parser_new

-- TODO types
-- --- @class level_definition
-- --- @field ldtk {path: string, level: string}
-- --- @field palette table<string, table<string, function>>
-- --- @field config level_config
-- 
-- --- @class level_config
-- --- @field grid_layers string[]
-- --- @field grid_complex_layers table<string, boolean>
-- --- @field cell_size integer
-- 
-- --- @class level_info
-- --- @field config level_config
-- --- @field size vector
-- --- @field atlas_layers string[]
-- 
-- --- @param path string
-- --- @return {level_info: level_info, entities: base_entity[]}

ldtk.load = function(path)
  -- --- @type level_definition
  local level_module = require(path)

  local raw = Fun.iter(Json.decode(love.filesystem.read(level_module.ldtk.path)).levels)
    :filter(function(l) return l.identifier == level_module.ldtk.level end)
    :nth(1)

  return parser_new():parse(raw, level_module.palette)
end

local get_identifier = function(node)
  return node.__identifier:lower()
end

parser_new = function()
  return {
    _entities = {},
    _level_info = {
      layers = {},
      atlases = {},
      cell_size = nil,
      grid_size = nil,
    },

    _handlers = {
      tiles = function(this_parser, layer, palette)
        local layer_id = get_identifier(layer)
        local layer_palette = palette[layer_id]

        table.insert(this_parser._level_info.layers, layer_id)
        this_parser._level_info.atlases[layer_id] = assert(
          layer_palette.ATLAS_IMAGE,
          "Palette for atlas-containing layer %s doesn't have .ATLAS_IMAGE" % {layer_id}
        )

        for _, instance in ipairs(layer.gridTiles) do
          local factory = assert(
            layer_palette[instance.t + 1],
            "Entity factory %s is not defined for layer %s" % {instance.t, layer_id}
          )

          local e = Table.extend(factory(), {
            position = Vector.own(instance.px) / this_parser._level_info.cell_size + Vector.one,
            layer = layer_id,
            view = "grids",
          })

          -- TODO entity captures (after rails)
          -- local rails_name = -Query(to_capture)[layer_id][result.position]
          -- if rails_name then
          --   captured_entities[rails_name] = result
          -- end
          table.insert(this_parser._entities, e)
        end
      end,
    },

    parse = function(self, raw, palette)
      self._level_info.cell_size = raw.layerInstances[1].__gridSize
      self._level_info.grid_size = V(raw.pxWid, raw.pxHei) / self._level_info.cell_size
      for _, layer in ipairs(raw.layerInstances) do
        self._handlers[layer.__type:utf_lower()](self, layer, palette)
      end
      return {
        entities = self._entities,
        level_info = self._level_info,
      }
    end,
  }
end

Ldump.mark(ldtk, {}, ...)
return ldtk
