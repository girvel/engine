local railing = require "engine.tech.railing"
--- LDtk level parsing
local ldtk = {}

local parser_new

--- Level's init.lua return
--- @class level_definition
--- @field ldtk {path: string, level: string}
--- @field palette table<string, table<string | integer, function>>
--- @field cell_size integer
--- @field layers string[] global layers in order
--- @field rails? {factory: (fun(...): rails), scenes: scene[]}

--- General information about the level
--- @class level_info
--- @field grid_layers string[] grid layers in order
--- @field layers string[] global layers in order
--- @field atlases table<string, love.Image> atlas images for each grid_layer that uses them
--- @field cell_size integer size of a single grid cell in pixels before scaling
--- @field grid_size vector

--- Read LDtk level file
--- @async
--- @param path string
--- @return {level_info: level_info, entities: entity[], rails: rails}
ldtk.load = function(path)
  return parser_new():parse(path)
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

      local rails_name = this_parser._to_capture[layer_id][e.position]
      if rails_name then
        this_parser._were_captured[rails_name] = true
        this_parser._captures.entities[rails_name] = e
      end

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
    _captures = {
      positions = {},
      entities = {},
    },
    _to_capture = nil,
    _were_captured = nil,
    _should_be_captured = nil,

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

          local rails_name = this_parser._to_capture[layer_id][entity.position]
          if rails_name then
            this_parser._were_captured[rails_name] = true
            this_parser._captures.entities[rails_name] = entity
            assert(not get_field(instance, "rails_name"))
          else
            local f = get_field(instance, "rails_name")
            if f then
              this_parser._captures.entities[f.__value] = entity
            end
          end

          table.insert(this_parser._entities, entity)
        end
      end,
    },

    _read_positions = function(self, layer, offset)
      self._should_be_captured = {}
      self._were_captured = {}

      for _, instance in ipairs(layer.entityInstances) do
        if get_identifier(instance) == "entity_capture" then
          local name = get_field(instance, "rails_name").__value:lower()
          self._to_capture
            [get_field(instance, "layer").__value:lower()]
            [Vector.own(instance.__grid) + Vector.one + offset] = name
          table.insert(self._should_be_captured, name)
        else
          self._captures.positions[instance.fieldInstances[1].__value:lower()]
            = Vector.own(instance.__grid):add_mut(Vector.one):add_mut(offset)
        end
      end
    end,

    parse = function(self, path)
      --- @type level_definition
      local level_module = require(path)

      local raw = Json.decode(love.filesystem.read(level_module.ldtk.path)).levels

      self._level_info.cell_size = level_module.cell_size
      self._level_info.layers = level_module.layers
      self._level_info.grid_size = Vector.zero

      for _, level in ipairs(raw) do
        local offset = V(level.worldX, level.worldY) / level_module.cell_size
        local end_point = offset + V(level.pxWid, level.pxHei) / level_module.cell_size
        self._level_info.grid_size = Vector.use(math.max, self._level_info.grid_size, end_point)
      end

      self._to_capture = Fun.iter(level_module.layers)
        :map(function(l) return l, Grid.new(self._level_info.grid_size) end)
        :tomap()

      local total_layers_n = Fun.iter(raw):map(function(l) return #l.layerInstances end):sum()
      local average_layers_n = total_layers_n / #raw

      for j, level in ipairs(raw) do
        local offset = V(level.worldX, level.worldY) / level_module.cell_size
        local positions_layer = Fun.iter(level.layerInstances)
          :filter(function(layer) return get_identifier(layer) == "positions" end)
          :nth(1)

        if positions_layer then
          self:_read_positions(positions_layer, offset)
          coroutine.yield(.5 * j * average_layers_n / total_layers_n)
        end

        for i = #level.layerInstances, 1, -1 do
          local layer = level.layerInstances[i]
          if get_identifier(layer) ~= "positions" then
            self._handlers[layer.__type:utf_lower()](self, layer, level_module.palette, offset)
            -- TODO time-based yield moment?
            coroutine.yield(.5 * (j * average_layers_n - i) / total_layers_n)
          end
        end

        do
          local were_not_captured = Fun.iter(self._should_be_captured)
            :filter(function(name) return not self._were_captured[name] end)
            :totable()

          assert(
            #were_not_captured == 0,
            "Entity captures %s did not catch anything" % {table.concat(were_not_captured, ", ")}
          )
        end
      end

      local rails = level_module.rails.factory(railing.runner(
        level_module.rails.scenes, self._captures.positions, self._captures.entities
      ))
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
