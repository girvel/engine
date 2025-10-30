local async = require("engine.tech.async")
local level = require("engine.tech.level")
local combat = require("engine.state.combat")
local ldtk = require("engine.tech.ldtk")
local tcod = require("engine.tech.tcod")
local sprite = require("engine.tech.sprite")


local state = {}

--- @class state
--- @field mode state_mode
--- @field runner state_runner
--- @field perspective state_perspective
--- @field combat state_combat?
--- @field quests state_quests
--- @field hostility state_hostility
--- @field audio state_audio
--- @field debug_overlay state_debug
--- @field period state_period
--- @field uid state_uid
--- @field stats state_stats
--- @field shader shader?
--- @field debug boolean
--- @field args table CLI args
--- @field rails rails
--- @field grids table<grid_layer, grid<entity>>
--- @field grid_size vector
--- @field level level_info
--- @field player player
--- @field is_loaded boolean is level fully loaded
--- @field _world table
--- @field _entities table<entity, true>
--- @field _entities_to_add entity[]
--- @field _entities_to_remove [entity, boolean][]
local methods = {}
state.mt = {__index = methods}

--- @param systems table[]
--- @return state
state.new = function(systems, args)
  return setmetatable({
    mode = require("engine.state.mode").new(),
    runner = require("engine.state.runner").new(),
    perspective = require("engine.state.perspective").new(),
    quests = require("engine.state.quests").new(),
    hostility = require("engine.state.hostility").new(),
    audio = require("engine.state.audio").new(),
    debug_overlay = require("engine.state.debug_overlay").new(args.debug),
    period = require("engine.state.period").new(),
    uid = require("engine.state.uid").new(),
    stats = require("engine.state.stats").new(),
    debug = args.debug,

    args = args,

    is_loaded = false,

    _world = Tiny.world(unpack(systems)),
    _entities = {},
    _entities_to_add = {},
    _entities_to_remove = {},
  }, state.mt)
end

--- Schedules entity to be added
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param ... table extensions
--- @return T
methods.add = function(self, entity, ...)
  --- @cast entity entity

  Table.extend(entity, ...)
  table.insert(self._entities_to_add, entity)
  if entity.inventory then
    for _, it in pairs(entity.inventory) do
      self:add(it)
    end
  end
  return entity
end

--- Schedules entity to be removed
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param silently? boolean
--- @return T
methods.remove = function(self, entity, silently)
  --- @cast entity entity
  table.insert(self._entities_to_remove, {entity, silently})
  return entity
end

--- @param entity entity?
--- @return boolean
methods.exists = function(self, entity)
  return self._entities[entity]
end

--- Removes & adds scheduled entities
methods.flush = function(self)
  for _, pair in ipairs(self._entities_to_remove) do
    local entity, silently = unpack(pair)
    if entity.on_remove then
      entity:on_remove()
    end

    if not silently and not entity.boring_flag then
      Log.debug("Removing %s", Name.code(entity))
    end

    self._world:remove(entity)
    self._entities[entity] = nil

    if entity.position and entity.grid_layer then
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
  end
  self._entities_to_remove = {}
  self._world:refresh()

  for _, entity in ipairs(self._entities_to_add) do
    self._world:add(entity)
    self._entities[entity] = true
    if entity.position and entity.grid_layer then
      level.put(entity)
    end
    if entity.on_add then
      entity:on_add()
    end
  end
  self._entities_to_add = {}
  self._world:refresh()
end

methods.reset = function(self)
  Log.info("State:reset()")
  local to_remove = Table.shallow_copy(self._entities)
  for e, _ in pairs(to_remove) do
    State:remove(e, true)
  end

  self.audio:reset()
end

--- @async
--- @param path string
methods.load_level = function(self, path)
  async.lag_threshold = .5
  self.is_loaded = false
  Log.info("Loading level %s", path)
  local start_t = love.timer.getTime()

  local load_data = ldtk.load(path)
  local read_t = love.timer.getTime()
  local last_yield_t = read_t

  self.level = load_data.level_info
  Log.info("State.level == %s", self.level)

  self.rails = load_data.rails

  Table.extend(self.runner.entities, load_data.runner_entities)
  Table.extend(self.runner.positions, load_data.runner_positions)
  self.runner:add(load_data.runner_scenes)

  self.grids = Fun.iter(level.grid_layers)
    :map(function(layer) return layer, Grid.new(self.level.grid_size) end)
    :tomap()

  self.grids.solids = tcod.observer(assert(
    self.grids.solids,
    "Missing \"solids\" grid_layer; required for FOV and pathing to work"
  ))

  for layer, grid in pairs(self.grids) do
    State:add({
      codename = layer .. "_grid_container",
      sprite = sprite.grid(grid),
      layer = layer,
      position = Vector.zero,
    })
  end

  for i, e in ipairs(load_data.entities) do
    e = self:add(e)
    if e.player_flag then self.player = e --[[@as player]] end
    -- if e.on_load then e:on_load() end

    if i % 500 == 0 and love.timer.getTime() - last_yield_t >= Constants.yield_period then
      coroutine.yield(.8 + .2 * (i / #load_data.entities))
      last_yield_t = love.timer.getTime()
    end
  end

  self.perspective.camera_offset = V(self.perspective:center_camera(unpack(self.player.position)))

  coroutine.yield(1)
  local end_t = love.timer.getTime()
  Log.info("Added %s entities in %.2f s", #load_data.entities, end_t - read_t)
  Log.info("Total time %.2f s", end_t - start_t)

  self.is_loaded = true
  async.lag_threshold = .1
end

--- @param list entity[]
methods.start_combat = function(self, list)
  list = Fun.iter(list)
    :filter(function(e) return not self:in_combat(e) and self:exists(e) end)
    :totable()

  if #list == 0 then return end

  self.runner:run_task_sync(function()
    list = Fun.iter(list)
      :filter(function(e) return not self:in_combat(e) and self:exists(e) end)
      :totable()
    if #list == 0 then return end

    local initiatives = {}
    for _, e in ipairs(list) do
      initiatives[e] = e:get_initiative_roll():roll()
    end

    table.sort(list, function(a, b) return initiatives[a] > initiatives[b] end)
    local repr = table.concat(Fun.iter(list):map(Name.code):totable(), ", ")

    for _, e in ipairs(list) do
      if e.ai then
        e.ai._control_coroutine = nil
      end
    end

    if State.combat then
      Log.info("Joining the combat: %s", repr)
      Table.concat(State.combat.list, list)
    else
      Log.info("--- Combat starts: %s ---", repr)
      State.combat = combat.new(list)
    end
  end, "start_combat")
end

--- @param entity entity
methods.in_combat = function(self, entity)
  return State.combat and Table.contains(State.combat.list, entity)
end

Ldump.mark(state, {}, ...)
return state
