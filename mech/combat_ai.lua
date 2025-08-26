local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local iteration = require("engine.tech.iteration")


local combat_ai = {}

--- @class combat_ai: ai
local methods = {}
local mt = {__index = methods}

--- @return combat_ai
combat_ai.new = function()
  return setmetatable({}, mt)
end

local VISION_RANGE = 10

--- @param entity entity
methods.control = function(entity)
  if not State.combat then return end

  local target
  for d in iteration.expanding_rhombus(VISION_RANGE) do
    local e = State.grids.solids:slow_get(entity.position + d)
    if e and State.hostility:get(entity, e) then
      target = e
      goto found
    end
  end

  State.combat:remove(entity)
  do return end
  ::found::

  api.travel(entity, target.position)
  api.attack(entity, target)
end

local OBSERVE_PERIOD = .5

--- @param entity entity
--- @param dt number
methods.observe = function(entity, dt)
  if not Random.chance(dt / OBSERVE_PERIOD) then return end

  -- starting/joining combat
  if (not State.combat or not Table.contains(State.combat.list, entity))
    and State.hostility:get(entity, State.player)
    and tcod.snapshot(State.grids.solids):is_visible_unsafe(unpack(entity.position))
    and not State.player.ai.in_cutscene_flag
    and (State.player.position - entity.position):abs() <= VISION_RANGE
  then
    State:start_combat({State.player, entity})
  end
end

Ldump.mark(combat_ai, {}, ...)
return combat_ai
