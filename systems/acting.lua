local async = require "engine.tech.async"


--- @class ai
--- @field run fun(base_entity, number): boolean?

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
    -- NEXT! timeout
    local current = State.combat:get_current()
    local ai = entity.ai

    if entity ~= current or not ai.run then return end

    if not ai._run_coroutine then
      ai._run_coroutine = coroutine.create(ai.run)
    end

    async.resume(ai._run_coroutine, entity, dt)
    if coroutine.status(ai._run_coroutine) == "dead" then
      ai._run_coroutine = nil
      if current.rest then
        current:rest("move")
      end
      State.combat:_pass_turn()
      Log.info("%s's turn" % {State.combat:get_current()})
      -- NEXT! reset timeout
      -- NEXT FX and SFX for player's turn
    end
  end,

  _process_outside_combat = function(self, entity, dt)
    local ai = entity.ai
    if not ai.run then return end

    if not ai._run_coroutine then
      ai._run_coroutine = coroutine.create(ai.run)
    end

    async.resume(ai._run_coroutine, entity, dt)

    if coroutine.status(ai._run_coroutine) == "dead" then
      ai._run_coroutine = nil
      if entity.rest then
        entity:rest("free")
      end
    end
  end,
}
