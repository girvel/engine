local async = require("engine.tech.async")
local actions = require("engine.mech.actions")


local wandering_ai = {}

--- @class wandering_ai
local methods = {}
wandering_ai.mt = {__index = methods}

--- @param frequency_k? number
--- @return wandering_ai
wandering_ai.new = function(frequency_k)
  return setmetatable({_frequency_k = frequency_k or 1,}, wandering_ai.mt)
end

methods.control = function(entity)
  async.sleep(math.random(0.5, 7) / entity.ai._frequency_k)
  actions.move(Random.choice(Vector.directions)):act(entity)
end

Ldump.mark(wandering_ai, {mt = "const"}, ...)
return wandering_ai
