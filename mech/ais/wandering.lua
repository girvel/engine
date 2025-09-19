local tk = require("engine.mech.ais.tk")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local iteration = require("engine.tech.iteration")
local api       = require("engine.tech.api")


local wandering = {}

--- @class wandering_ai: ai
--- @field _frequency_k number
--- @field _target? entity
local methods = {}
wandering.mt = {__index = methods}

--- @param frequency_k? number
--- @return wandering_ai
wandering.new = function(frequency_k)
  return setmetatable({_frequency_k = frequency_k or 1}, wandering.mt)
end

--- @param entity entity
methods.init = function(entity)
  State.hostility:subscribe(function(attacker, target)
    if entity.faction and target == entity then
      local ai = entity.ai  --[[@as wandering_ai]]
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      ai._target = attacker
      ai._control_coroutine = nil
    end
  end)
end

-- TODO common looking constants with ais.combat
local TARGET_SCAN_PERIOD = .5
local TARGET_RANGE = 20
local TARGET_SEARCH_RANGE = 10

--- @param entity entity
--- @param dt number
methods.observe = function(entity, dt)
  local ai = entity.ai  --[[@as wandering_ai]]
  if (not ai._target or (ai._target.position - entity.position):abs2() > TARGET_RANGE)
    and Period(TARGET_SCAN_PERIOD, ai, "target_scan")
  then
    ai._target = tk.find_target(entity, TARGET_SEARCH_RANGE)
  end
end

--- @param entity entity
methods.control = function(entity)
  local ai = entity.ai  --[[@as wandering_ai]]

  if ai._target then
    local max_distance = 0
    local run_to
    for p in iteration.rhombus_edge(entity.resources.movement) do
      p:add_mut(entity.position)
      local d = (p - ai._target.position):abs2()
      if State.grids.solids:can_fit(p) and d > max_distance then
        max_distance = d
        run_to = p
      end
    end

    api.travel(entity, run_to)
    async.sleep(.5)
  else
    async.sleep(math.random(0.5, 7) / ai._frequency_k)
    actions.move(Random.choice(Vector.directions)):act(entity)
  end
end

Ldump.mark(wandering, {mt = "const"}, ...)
return wandering
