local level = require("engine.tech.level")
local combat = require("engine.state.combat")
local ldtk = require("engine.tech.ldtk")
local tcod = require("engine.tech.tcod")


local state = {}

--- @class state
--- @field mode state_mode
--- @field perspective state_perspective
--- @field combat state_combat?
--- @field quests state_quests
--- @field hostility state_hostility
--- @field rails rails
--- @field grids table<string, grid>
--- @field grid_size vector
--- @field level level_info
--- @field player player
--- @field debug boolean is debug mode enabled; see engine.kernel.cli
--- @field _world table
--- @field _entities table
local methods = {}
state.mt = {__index = methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    mode = require("engine.state.mode").new(),
    perspective = require("engine.state.perspective").new(),
    quests = require("engine.state.quests").new(),
    hostility = require("engine.state.hostility").new(),

    _world = Tiny.world(unpack(systems)),
    _entities = {},
  }, state.mt)
end

--- Modifies entity
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param ... table extensions
--- @return T
methods.add = function(self, entity, ...)
  --- @cast entity entity

  Table.extend(entity, ...)
  self._world:add(entity)
  self._entities[entity] = true
  if entity.position and entity.layer then
    level.put(entity)
  end
  if entity.inventory then
    Fun.iter(entity.inventory)
      :each(function(slot, it) self:add(it) end)
  end
  -- if entity.on_add then
  --   entity:on_add()
  -- end
  return entity
end

--- @generic T: table
--- @param self state
--- @param entity T
--- @param silently? boolean
--- @return T
methods.remove = function(self, entity, silently)
  --- @cast entity table
  if not silently and not entity.boring_flag then
    Log.debug("State:remove(%s)" % Entity.codename(entity))
  end

  self._world:remove(entity)
  self._entities[entity] = nil

  if entity.position and entity.layer then
    level.remove(entity)
  end

  if entity.inventory then
    for _, item in pairs(entity.inventory) do
      self:remove(item, silently)
    end
  end

  if self.combat then
    self.combat:remove(entity)
  end

  -- if entity.on_remove then
  --   entity:on_remove()
  -- end

  return entity
end

methods.exists = function(self, entity)
  return self._entities[entity]
end

methods.reset = function(self)
  Log.info("State:reset()")
  local to_remove = Table.shallow_copy(self._entities)
  for e, _ in pairs(to_remove) do
    State:remove(e, true)
  end
end

--- @async
--- @param path string
methods.load_level = function(self, path)
  Log.info("Loading level %s" % {path})
  local start_time = love.timer.getTime()

  local load_data = ldtk.load(path)
  local read_time = love.timer.getTime()
  Log.info("Read level files in %.2f s" % {read_time - start_time})

  self.level = load_data.level_info
  Log.info("State.level is", self.level)

  self.rails = load_data.rails

  self.grids = Fun.iter(self.level.layers)
    :map(function(layer) return layer, Grid.new(self.level.grid_size) end)
    :tomap()

  self.grids.solids = tcod.observer(assert(
    self.grids.solids,
    "Missing \"solids\" layer; required for FOV and pathing to work"
  ))

  local BATCH_SIZE = 1024
  for i, e in ipairs(load_data.entities) do
    e = self:add(e)
    if e.player_flag then self.player = e end
    -- if e.on_load then e:on_load() end

    if i % BATCH_SIZE == 0 then
      coroutine.yield(.5 + .5 * (i / #load_data.entities))
    end
  end

  local end_time = love.timer.getTime()
  Log.info("Added entities in %.2f s, total time %.2f s" % {
    end_time - read_time, end_time - start_time,
  })
end

--- @param list entity[]
methods.start_combat = function(self, list)
  Log.info("State:start_combat()")

  list = {unpack(list)}
  if self.combat then
    list = Fun.iter(list)
      :filter(function(e) return not Table.contains(self.combat.list, e) end)
      :totable()
  end

  local initiatives = {}
  for _, e in ipairs(list) do
    initiatives[e] = e:get_initiative_roll():roll()
  end

  table.sort(list, function(a, b) return initiatives[a] > initiatives[b] end)
  local repr = table.concat(Fun.iter(list):map(Entity.codename):totable(), ", ")

  if self.combat then
    Log.info("Joining the combat: %s" % {repr})
    Table.concat(self.combat.list, list)
  else
    Log.info("Combat starts: %s" % {repr})
    self.combat = combat.new(list)
  end
end

Ldump.mark(state, {}, ...)
return state
