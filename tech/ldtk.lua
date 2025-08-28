local railing = require "engine.tech.railing"
--- LDtk level parsing
local ldtk = {}

local parser_new, load_scenes

--- Level's init.lua return
--- @class level_definition
--- @field ldtk {path: string, level: string}
--- @field palette table<string, table<string | integer, function>>
--- @field cell_size integer
--- @field rails? {factory: fun(...): rails, scenes: scene[]}

--- General information about the level
--- @class level_info
--- @field grid_layers string[] grid layers in order
--- @field atlases table<string, love.Image> atlas images for each grid_layer that uses them
--- @field cell_size integer size of a single grid cell in pixels before scaling
--- @field grid_size vector

--- Read LDtk level file
--- @async
--- @param path string
--- @return {level_info: level_info, entities: entity[], rails: rails}
ldtk.load = function(path)
  --- @type level_definition
  local level_module = require(path)

  local raw = Json.decode(love.filesystem.read(level_module.ldtk.path)).levels
  return parser_new():parse(
    raw, level_module.palette, level_module.cell_size, level_module.rails
  )
end

local get_identifier = function(node)
  return node.__identifier:lower()
end

local get_field = function(instance, field_name)
  return Fun.iter(instance.fieldInstances)
    :filter(function(f) return get_identifier(f) == field_name end)
    :nth(1)
end

local handle_tiles_or_intgrid = function(is_tiles)
  return function(this_parser, layer, palette, offset)
    local layer_id = get_identifier(layer)
    local layer_palette = assert(
      palette[layer_id],
      "Missing palette element %q" % {layer_id}
    )

    if not Table.contains(this_parser._level_info.grid_layers, layer_id) then
      table.insert(this_parser._level_info.grid_layers, layer_id)
    end

    this_parser._level_info.atlases[layer_id] = assert(
      layer_palette.ATLAS_IMAGE,
      "Palette for tile layer %q doesn't have .ATLAS_IMAGE" % {layer_id}
    )

    local to_iterate if is_tiles then
      to_iterate = layer.gridTiles
    else
      to_iterate = layer.autoLayerTiles
    end

    for _, instance in ipairs(to_iterate) do
      local factory = assert(
        layer_palette[instance.t + 1],
        "Entity factory %q is not defined for tile layer %q" % {instance.t + 1, layer_id}
      )

      local e = factory()
      e.position = Vector.own(instance.px)
        :div_mut(this_parser._level_info.cell_size)
        :add_mut(Vector.one)
        :add_mut(offset)
      e.grid_layer = layer_id

      -- NEXT entity captures (after rails)
      -- local rails_name = -Query(to_capture)[layer_id][result.position]
      -- if rails_name then
      --   captured_entities[rails_name] = result
      -- end
      table.insert(this_parser._entities, e)
    end
  end
end

parser_new = function()
  return {
    _entities = {},
    _level_info = {
      grid_layers = {},
      atlases = {},
      grid_size = nil,
      cell_size = nil,
    },

    _handlers = {
      tiles = handle_tiles_or_intgrid(true),
      intgrid = handle_tiles_or_intgrid(false),

      entities = function(this_parser, layer, palette, offset)
        local layer_id, layer_palette do
          local raw = get_identifier(layer)
          local POSTFIX = "_entities"
          assert(
            raw:ends_with(POSTFIX),
            "Entity layer name %s should end with %q" % {raw, POSTFIX}
          )
          layer_id = raw:sub(1, #raw - #POSTFIX)

          layer_palette = assert(
            palette[raw],
            "Missing palette element %q" % {raw}
          )
        end

        if not Table.contains(this_parser._level_info.grid_layers, layer_id) then
          table.insert(this_parser._level_info.grid_layers, layer_id)
        end

        for _, instance in ipairs(layer.entityInstances) do
          local codename = get_identifier(instance)
          local factory = assert(
            layer_palette[codename],
            "Entity factory %q is not defined for factory layer %q" % {codename, layer_id}
          )

          local args_expression = get_field(instance, "args")
          local entity if args_expression then
            entity = factory(assert(loadstring("return " .. args_expression.__value))())
          else
            entity = factory()
          end

          entity.position = Vector.own(instance.__grid)
            :add_mut(Vector.one)
            :add_mut(offset)
          entity.grid_layer = layer_id

          -- NEXT capturing

          table.insert(this_parser._entities, entity)
        end
      end,
    },

    parse = function(self, raw, palette, cell_size, rails_config)
      self._level_info.cell_size = cell_size
      self._level_info.grid_size = Vector.zero

      local total_layers = Fun.iter(raw):map(function(l) return #l.layerInstances end):sum()
      local average_layers = total_layers / #raw

      for j, level in ipairs(raw) do
        local offset = V(level.worldX, level.worldY) / cell_size
        local end_point = offset + V(level.pxWid, level.pxHei) / cell_size
        self._level_info.grid_size = Vector.use(math.max, self._level_info.grid_size, end_point)

        for i = #level.layerInstances, 1, -1 do
          local layer = level.layerInstances[i]
          self._handlers[layer.__type:utf_lower()](self, layer, palette, offset)
          -- TODO time-based yield?
          coroutine.yield(.5 * (j * average_layers - i) / total_layers)
        end
      end

      local rails = rails_config.factory(railing.runner(rails_config.scenes))
      -- NEXT (rails) handle positions & entities

      return {
        entities = self._entities,
        level_info = self._level_info,
        rails = rails,
      }
    end,
  }
end

Ldump.mark(ldtk, {}, ...)
return ldtk
