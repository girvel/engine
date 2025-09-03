local async = require "engine.tech.async"
local animated = require "engine.tech.animated"


--- @class ai
--- @field init? fun(base_entity)
--- @field deinit? fun(base_entity)
--- @field control? fun(base_entity)
--- @field observe? fun(base_entity, number)

return Tiny.processingSystem {
  codename = "acting",
  base_callback = "update",
  filter = Tiny.requireAll("ai"),

  onAdd = function(self, entity)
    if entity.ai.init then
      entity.ai.init(entity)
    end
  end,

  onRemove = function(self, entity)
    if entity.ai.deinit then
      entity.ai.deinit(entity)
    end
  end,

  preProcess = function(self, entity, dt)
    if State.combat and Fun.iter(State.combat.list)
      :all(function(a) return Fun.iter(State.combat.list)
        :all(function(b) return a == b or State.hostility:get(a, b) ~= "enemy" end)
      end)
    then
      Log.info(
        "Combat ends as only %s are left standing"
         % table.concat(Fun.iter(State.combat.list)
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
    if State.rails.runner.locked_entities[entity] then return end

    if State.combat then
      self:_process_inside_combat(entity, dt)
    else
      self:_process_outside_combat(entity, dt)
    end
  end,

  _process_inside_combat = function(self, entity, dt)
    -- NEXT timeout (safety)
    local ai = entity.ai

    if ai.observe then
      ai.observe(entity, dt)
    end

    local current = State.combat:get_current()
    if entity ~= current then return end

    if not ai.control then
      self:_update_conditions(entity, 6)
      State.combat:_pass_turn()
    end

    if not ai._control_coroutine then
      ai._control_coroutine = Common.nil_serialized(coroutine.create(ai.control))
    end

    async.resume(ai._control_coroutine, entity, dt)
    if coroutine.status(ai._control_coroutine) == "dead" then
      ai._control_coroutine = nil
      if current.rest then
        current:rest("move")
      end
      State.combat:_pass_turn()

      local current = State.combat:get_current()
      Log.info("%s's turn" % {Name.code(current)})
      -- NEXT reset timeout (safety)
      State:add(animated.fx("engine/assets/sprites/animations/underfoot_circle", current.position))

      self:_update_conditions(entity, 6)
    end
  end,

  _process_outside_combat = function(self, entity, dt)
    local ai = entity.ai

    if ai.observe then
      ai.observe(entity, dt)
    end

    if not ai.control then return end

    if not ai._control_coroutine then
      ai._control_coroutine = Common.nil_serialized(coroutine.create(ai.control))
    end

    async.resume(ai._control_coroutine, entity, dt)

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
