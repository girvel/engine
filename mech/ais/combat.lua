local tk = require("engine.mech.ais.tk")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local animated  = require("engine.tech.animated")
local actions   = require("engine.mech.actions")


local combat_ai = {}

--- @class combat_ai: ai
--- @field targeting ai_targeting
--- @field _hostility_subscription function
local methods = {}
local mt = {__index = methods}

--- @type ai_targeting
local DEFAULT_TARGETING = {
  scan_period = .5,
  scan_range = 10,
  range = 20,
}

--- @param targeting? ai_targeting_optional
--- @return combat_ai
combat_ai.new = function(targeting)
  return setmetatable({
    targeting = Table.defaults(targeting, DEFAULT_TARGETING),
  }, mt)
end

--- @param entity entity
methods.init = function(self, entity)
  self._hostility_subscription = State.hostility:subscribe(function(attacker, target)
    if entity.hp > 0 and entity.faction and target == entity then
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      if not State:in_combat(entity) then
        Log.trace("AGGRESSIVE!")
        State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
        State:start_combat({entity, attacker})
      end
    end
  end)
end

--- @param entity entity
methods.deinit = function(self, entity)
  State.hostility:unsubscribe(self._hostility_subscription)
end

--- @param entity entity
methods.control = function(self, entity)
  if not State.combat or State.runner.locked_entities[State.player] then return end

  local target = tk.find_target(entity, self.targeting.range)
  if not target then
    State.combat:remove(entity)
    return
  end

  local bow = entity.inventory.offhand
  if bow and bow.tags.ranged then
    tk.preserve_line_of_fire(entity, target)
    local bow_attack = actions.bow_attack(target)
    while bow_attack:act(entity) do
      async.sleep(.66)
    end
  else
    if entity.hp <= entity:get_max_hp() / 2 then
      api.heal(entity)
    end

    api.travel(entity, target.position)
    api.attack(entity, target)
  end
end

--- @param entity entity
--- @param dt number
methods.observe = function(self, entity, dt)
  if State.runner.locked_entities[State.player] or entity.hp <= 0 then return end

  if not Random.chance(dt / self.targeting.scan_period) then return end

  -- starting/joining combat
  if (not State.combat or not Table.contains(State.combat.list, entity)) then
    local target = tk.find_target(entity, self.targeting.scan_range)

    local condition = not not target
    if target == State.player then
      condition = (
        not State.runner.locked_entities[State.player]
        and tcod.snapshot(State.grids.solids):is_visible_unsafe(unpack(entity.position))
        and (State.player.position - entity.position):abs2() <= self.targeting.scan_range
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
