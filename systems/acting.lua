local async = require "engine.tech.async"


--- @class ai
--- @field control fun(base_entity)
--- @field observe fun(base_entity, number)

return Tiny.processingSystem {
  codename = "acting",
  base_callback = "update",
  filter = Tiny.requireAll("ai"),

  process = function(self, entity, dt)
    if State.combat then
      self:_process_inside_combat(entity, dt)
    else
      self:_process_outside_combat(entity, dt)
    end
  end,

  _process_inside_combat = function(self, entity, dt)
    -- NEXT! timeout (when implementing AIs/putting safety in)
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
      ai._control_coroutine = async.nil_serialized(coroutine.create(ai.control))
    end

    async.resume(ai._control_coroutine, entity, dt)
    if coroutine.status(ai._control_coroutine) == "dead" then
      ai._control_coroutine = nil
      if current.rest then
        current:rest("move")
      end
      State.combat:_pass_turn()
      Log.info("%s's turn" % {Entity.codename(State.combat:get_current())})
      -- NEXT! reset timeout (when implementing AIs/putting safety in)
      -- NEXT FX and SFX for player's turn

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
      ai._control_coroutine = async.nil_serialized(coroutine.create(ai.control))
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
