--- LDtk level parsing
local ldtk = {}

local parser_new

--- Level's init.lua return
--- @class level_definition
--- @field ldtk {path: string, level: string}
--- @field palette table<string, table<string | integer, function>>
--- @field cell_size integer

--- General information about the level
--- @class level_info
--- @field layers string[] grid layers in order
--- @field atlases table<string, love.Image> atlas images for each layer that uses them
--- @field cell_size integer size of a single grid cell in pixels before scaling
--- @field grid_size vector

--- Read LDtk level file
--- @async
--- @param path string
--- @return {level_info: level_info, entities: base_entity[]}
ldtk.load = function(path)
  --- @type level_definition
  local level_module = require(path)

  local raw = Fun.iter(Json.decode(love.filesystem.read(level_module.ldtk.path)).levels)
    :filter(function(l) return l.identifier == level_module.ldtk.level end)
    :nth(1)

  return parser_new():parse(raw, level_module.palette, level_module.cell_size)
end

local get_identifier = function(node)
  return node.__identifier:lower()
end

local get_field = function(instance, field_name)
  return Fun.iter(instance.fieldInstances)
    :filter(function(f) return get_identifier(f) == field_name end)
    :nth(1)
end

parser_new = function()
  return {
    _entities = {},
    _level_info = {
      layers = {},
      atlases = {},
      grid_size = nil,
      cell_size = nil,
    },

    _handlers = {
      tiles = function(this_parser, layer, palette)
        local layer_id = get_identifier(layer)
        local layer_palette = palette[layer_id]

        if not Table.contains(this_parser._level_info.layers, layer_id) then
          table.insert(this_parser._level_info.layers, layer_id)
        end

        this_parser._level_info.atlases[layer_id] = assert(
          layer_palette.ATLAS_IMAGE,
          "Palette for tile layer %q doesn't have .ATLAS_IMAGE" % {layer_id}
        )

        for _, instance in ipairs(layer.gridTiles) do
          local factory = assert(
            layer_palette[instance.t + 1],
            "Entity factory %q is not defined for tile layer %q" % {instance.t + 1, layer_id}
          )

          local e = factory()
          e.position = Vector.own(instance.px) / this_parser._level_info.cell_size + Vector.one
          e.layer = layer_id
          e.view = "grids"

          -- NEXT entity captures (after rails)
          -- local rails_name = -Query(to_capture)[layer_id][result.position]
          -- if rails_name then
          --   captured_entities[rails_name] = result
          -- end
          table.insert(this_parser._entities, e)
        end
      end,

      entities = function(this_parser, layer, palette)
        local layer_id, layer_palette do
          local raw = get_identifier(layer)
          local POSTFIX = "_entities"
          assert(
            raw:ends_with(POSTFIX),
            "Entity layer name %s should end with %q" % {raw, POSTFIX}
          )
          layer_id = raw:sub(1, #raw - #POSTFIX)

          layer_palette = palette[raw]
        end

        if not Table.contains(this_parser._level_info.layers, layer_id) then
          table.insert(this_parser._level_info.layers, layer_id)
        end

        for _, instance in ipairs(layer.entityInstances) do
          local codename = get_identifier(instance)
          local factory = assert(
            layer_palette[codename],
            "Entity factory %q is not defined for factory layer %q" % {codename, layer_id}
          )

          local args_expression = get_field(instance, "args")
          local entity if args_expression then
            entity = factory(assert(loadstring("return " .. args_expression.__value)))
          else
            entity = factory()
          end

          entity.position = Vector.own(instance.__grid) + Vector.one
          entity.layer = layer_id
          entity.view = "grids"

          -- NEXT capturing

          table.insert(this_parser._entities, entity)
        end
      end,
    },

    parse = function(self, raw, palette, cell_size)
      self._level_info.cell_size = cell_size
      self._level_info.grid_size = V(raw.pxWid, raw.pxHei) / self._level_info.cell_size

      for i = #raw.layerInstances, 1, -1 do
        local layer = raw.layerInstances[i]
        self._handlers[layer.__type:utf_lower()](self, layer, palette)
        if i ~= 1 then
          coroutine.yield()
        end
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
