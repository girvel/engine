local tk = require("engine.mech.ais.tk")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local iteration = require("engine.tech.iteration")
local animated  = require("engine.tech.animated")
local actions   = require("engine.mech.actions")


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

--- @param entity entity
methods.init = function(entity)
  State.hostility:subscribe(function(attacker, target)
    if entity.faction and target == entity and not State.hostility:get(entity, attacker) then
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
      State:start_combat({entity, attacker})
    end
  end)
end

local preserve_line_of_fire = function(entity, target)
  local best_p
  for d in iteration.rhombus(entity.resources.movement) do
    local p = entity.position + d
    if not State.grids.solids:can_fit(p) then goto continue end

    local snapshot = tcod.copy(State.grids.solids)
    snapshot:refresh_fov(p, actions.BOW_ATTACK_RANGE)

    if snapshot:is_visible_unsafe(unpack(target.position)) then
      best_p = p
      if State.debug then
        Log.trace("found", best_p)
        for i in pairs(State.debug_overlay.points) do
          State.debug_overlay.points[i] = nil
        end
        local i = 0
        for dx = -10, 10 do
          for dy = -10, 10 do
            i = i + 1
            if snapshot:is_visible_unsafe(p.x + dx, p.y + dy) then
              State.debug_overlay.points[i] = {
                position = p + V(dx, dy),
                color = (not snapshot:is_transparent_unsafe(p.x + dx, p.y + dy))
                  and Vector.hex("ff0000") or Vector.white,
                view = "grid",
              }
            end
          end
        end
      end
      break
    end
    snapshot:free()

    ::continue::
  end

  if best_p then
    api.travel(entity, best_p)
  else
    api.travel(entity, target.position)
  end
end

--- @param entity entity
methods.control = function(entity)
  if not State.combat or State.rails.runner.locked_entities[State.player] then return end

  local target = tk.find_target(entity, FOLLOW_RANGE)
  if not target then
    State.combat:remove(entity)
    return
  end

  local bow = entity.inventory.offhand
  if bow and bow.tags.ranged then
    preserve_line_of_fire(entity, target)
    local bow_attack = actions.bow_attack(target)
    while bow_attack:act(entity) do
      async.sleep(.66)
    end
  else
    api.travel(entity, target.position)
    api.attack(entity, target)
  end
end

local OBSERVE_PERIOD = .5

--- @param entity entity
--- @param dt number
methods.observe = function(entity, dt)
  if State.rails.runner.locked_entities[State.player] then return end
  if not Random.chance(dt / OBSERVE_PERIOD) then return end

  -- starting/joining combat
  if (not State.combat or not Table.contains(State.combat.list, entity)) then
    local target = tk.find_target(entity, HOSTILITY_RANGE)

    local condition = not not target
    if target == State.player then
      condition = (
        not State.rails.runner.locked_entities[State.player]
        and tcod.snapshot(State.grids.solids):is_visible_unsafe(unpack(entity.position))
        and (State.player.position - entity.position):abs2() <= HOSTILITY_RANGE
      )
    end

    if condition then
      State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
      State:start_combat({target, entity})
    end
  end
end

Ldump.mark(combat_ai, {}, ...)
return combat_ai
