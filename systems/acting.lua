local combat = require("engine.state.combat")
local async = require "engine.tech.async"
local animated = require "engine.tech.animated"


--- @class ai
--- @field _control_coroutine? thread
local sample_methods = {}

--- @param entity entity
sample_methods.init = function(self, entity) end

--- @param entity entity
sample_methods.deinit = function(self, entity) end

--- @async
--- @param entity entity
sample_methods.control = function(self, entity) end

--- @async
--- @param entity entity
--- @param dt number
sample_methods.observe = function(self, entity, dt) end


local MOVE_TIMEOUT = 6
local AI_RANGE = 50

return Tiny.processingSystem {
  codename = "acting",
  base_callback = "update",
  filter = Tiny.requireAll("ai"),

  _active_ais = nil,
  _start_time = nil,

  onAdd = function(self, entity)
    if entity.ai.init then
      entity.ai:init(entity)
    end
  end,

  onRemove = function(self, entity)
    if entity.ai.deinit then
      entity.ai:deinit(entity)
    end
  end,

  preProcess = function(self, entity, dt)
    self._start_time = love.timer.getTime()
    self._active_ais = {}

    -- a safety measure
    if State.combat then
      while true do
        local current = State.combat:get_current()
        if State:exists(current) then break end
        -- in coherent code should always break here on the first iteration
        State.combat:remove(current)
      end
    end

    if State.combat and Fun.iter(State.combat.list)
      :all(function(a) return Fun.iter(State.combat.list)
        :all(function(b) return a == b or State.hostility:get(a, b) ~= "enemy" end)
      end)
    then
      Log.info(
        "Combat ends as only %s are left standing",
         table.concat(Fun.iter(State.combat.list)
          :map(Name.code)
          :totable(), ", ")
      )

      for _, e in ipairs(State.combat.list) do
        e:rest("short")
      end

      State.combat = nil
    end
  end,

  process = function(self, entity, dt)
    if State.runner.locked_entities[entity] then
      if entity.rest and State.period:absolute(1, entity, "resource_restoration") then
        entity:rest("move")
      end
      return
    end

    if State.combat then
      self:_process_inside_combat(entity, dt)
    elseif (entity.position - State.player.position):abs2() <= AI_RANGE then
      self:_process_outside_combat(entity, dt)
    end
  end,

  postProcess = function(self, dt)
    State.stats.active_ais = self._active_ais
    State.stats.ai_frame_time = love.timer.getTime() - self._start_time
  end,

  _move_start_t = nil,

  _process_inside_combat = function(self, entity, dt)
    local ai = entity.ai

    table.insert(self._active_ais, Name.code(entity))
    if ai.observe then
      ai:observe(entity, dt)
    end

    local current = State.combat:get_current()
    if entity ~= current then return end

    if not ai.control then
      self:_update_conditions(entity, 6)
      State.combat:_pass_turn()
    end

    if not ai._control_coroutine then
      ai._control_coroutine = Common.nil_serialized(coroutine.create(ai.control))
      self._move_start_t = love.timer.getTime()
    end

    async.resume(ai._control_coroutine, ai, entity)

    local is_timeout_reached = current ~= State.player
      and love.timer.getTime() - self._move_start_t > MOVE_TIMEOUT

    if is_timeout_reached then
      Log.warn("%s's combat move timed out", Name.code(current))
    end

    if is_timeout_reached or coroutine.status(ai._control_coroutine) == "dead" then
      ai._control_coroutine = nil
      if current.rest then
        current:rest("move")
      end
      State.combat:_pass_turn()

      current = State.combat:get_current()
      Log.info("%s's turn", Name.code(current))
      State:add(animated.fx("engine/assets/sprites/animations/underfoot_circle", current.position))

      self:_update_conditions(entity, 6)
    end
  end,

  _process_outside_combat = function(self, entity, dt)
    local ai = entity.ai

    table.insert(self._active_ais, Name.code(entity))
    if ai.observe then
      ai:observe(entity, dt)
    end

    if not ai.control then
      if entity.rest and State.period:absolute(1, entity, "resource_restoration") then
        entity:rest("move")
      end
      return
    end

    if not ai._control_coroutine then
      ai._control_coroutine = Common.nil_serialized(coroutine.create(ai.control))
    end

    async.resume(ai._control_coroutine, ai, entity, dt)

    if coroutine.status(ai._control_coroutine) == "dead" then
      ai._control_coroutine = nil
      if entity.rest then
        entity:rest("move")
      end
    end

    self:_update_conditions(entity, dt)
  end,

  _update_conditions = function(self, entity, dt)
    if not entity.conditions then return end

    local indexes_to_remove = {}
    for i, condition in ipairs(entity.conditions) do
      condition.life_time = condition.life_time - dt
      if condition.life_time <= 0 then
        table.insert(indexes_to_remove, i)
      end
    end

    Table.remove_breaking_in_bulk(entity.conditions, indexes_to_remove)
  end,
}
