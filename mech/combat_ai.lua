local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local iteration = require("engine.tech.iteration")
local animated  = require("engine.tech.animated")


local combat_ai = {}

--- @class combat_ai: ai
local methods = {}
local mt = {__index = methods}

--- @return combat_ai
combat_ai.new = function()
  return setmetatable({}, mt)
end

local HOSTILITY_RANGE = 10
local FOLLOW_RANGE = 20

local find_target

--- @param entity entity
methods.init = function(entity)
  State.hostility:subscribe(function(attacker, target)
    if entity.faction and target == entity and not State.hostility:get(entity, attacker) then
      State.hostility:set(entity.faction, attacker.faction, true)
      State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
      State:start_combat({entity, attacker})
    end
  end)
end

--- @param entity entity
methods.control = function(entity)
  if not State.combat then return end

  local target = find_target(entity, FOLLOW_RANGE)
  if not target then
    State.combat:remove(entity)
    return
  end

  api.travel(entity, target.position)
  api.attack(entity, target)
end

local OBSERVE_PERIOD = .5

--- @param entity entity
--- @param dt number
methods.observe = function(entity, dt)
  if not Random.chance(dt / OBSERVE_PERIOD) then return end

  -- starting/joining combat
  if (not State.combat or not Table.contains(State.combat.list, entity)) then
    local target = find_target(entity, HOSTILITY_RANGE)

    local condition = target
    if target == State.player then
      condition = (
        not State.player.ai.in_cutscene_flag
        and tcod.snapshot(State.grids.solids):is_visible_unsafe(entity.position:unpack())
        and (State.player.position - entity.position):abs() <= HOSTILITY_RANGE
      )
    end

    if condition then
      State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
      State:start_combat({target, entity})
    end
  end
end

--- @return entity?
find_target = function(entity, r)
  for d in iteration.expanding_rhombus(r) do
    local e = State.grids.solids:slow_get(entity.position + d)
    if e and State.hostility:get(entity, e) then
      return e
    end
  end
end

Ldump.mark(combat_ai, {}, ...)
return combat_ai
