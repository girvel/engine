local sound    = require "engine.tech.sound"


local ai = {}

--- @class player_ai
--- @field finish_turn boolean?
--- @field _next_actions action[]
--- @field _action_promises promise[]
local methods = {}
ai.mt = {__index = methods}

--- @return player_ai
ai.new = function()
  return setmetatable({
    finish_turn = nil,
    _next_actions = {},
    _action_promises = {},
  }, ai.mt)
end

local YOUR_TURN = sound.multiple("engine/assets/sounds/your_move", .2)

--- @param entity player
methods.control = function(entity)
  if State.combat then
    YOUR_TURN:play()
  end

  while true do
    for i, a in ipairs(entity.ai._next_actions) do
      local ok = a:act(entity)
      entity.ai._action_promises[i]:resolve(ok)
    end
    entity.ai._next_actions = {}
    entity.ai._action_promises = {}

    if not State.combat or entity.ai.finish_turn then break end
    coroutine.yield()
  end
  entity.ai.finish_turn = false
end

--- @param entity player
--- @param dt number
methods.observe = function(entity, dt)
  if State.combat and not Table.contains(State.combat.list, entity) then
    State:start_combat({entity})
  end
end

--- @param action action
--- @return promise
methods.plan_action = function(self, action)
  local promise = Promise.new()
  table.insert(self._next_actions, action)
  table.insert(self._action_promises, promise)
  return promise
end

Ldump.mark(ai, {mt = "const"}, ...)
return ai
