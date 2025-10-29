local tk = require("engine.mech.ais.tk")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local animated  = require("engine.tech.animated")
local actions   = require("engine.mech.actions")


local combat_ai = {}

--- @alias combat_ai combat_ai_strict|table

--- @class combat_ai_strict: ai_strict
--- @field targeting ai_targeting
--- @field _hostility_subscription function
--- @field _vision_map tcod_map
local methods = {}
combat_ai.mt = {__index = methods}

--- @type ai_targeting
local DEFAULT_TARGETING = {
  scan_period = .5,
  scan_range = 10,
  support_range = 15,
  range = 20,
}

--- @param targeting? ai_targeting_optional
--- @return combat_ai
combat_ai.new = function(targeting)
  return setmetatable({
    targeting = Table.defaults(targeting, DEFAULT_TARGETING),
  }, combat_ai.mt)
end

--- @param entity entity
methods.init = function(self, entity)
  self._hostility_subscription = State.hostility:subscribe(function(attacker, target)
    if entity.hp <= 0 then return end
    if State.hostility:get(entity, attacker) == "ally" then return end

    if State.hostility:get(entity, target) == "ally"
      and (target.position - entity.position):abs2() <= self.targeting.support_range
    then
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      if not State:in_combat(entity) then
        State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
        State:start_combat({entity, attacker})
      end
    end
  end)

  self._vision_map = tcod.map(State.grids.solids)
end

--- @param entity entity
methods.deinit = function(self, entity)
  State.hostility:unsubscribe(self._hostility_subscription)
  self._vision_map:free()
end

--- @param entity entity
methods.control = function(self, entity)
  if not State.combat or State.runner.locked_entities[State.player] then return end

  local target = tk.find_target(entity, self.targeting.range, self._vision_map)
  if not target then
    State.combat:remove(entity)
    return
  end

  local bow = entity.inventory.offhand
  if bow and bow.tags.ranged then
    tk.preserve_line_of_fire(entity, target, self._vision_map)
    local bow_attack = actions.bow_attack(target)
    while bow_attack:act(entity) do
      async.sleep(.66)
    end
  else
    if entity.hp <= entity:get_max_hp() / 2 then
      api.heal(entity)
    end

    api.travel(entity, target.position, true)
    api.attack(entity, target)
  end
end

--- @param entity entity
--- @param dt number
methods.observe = function(self, entity, dt)
  if State.runner.locked_entities[State.player] or entity.hp <= 0 then return end
  if not Random.chance(dt / self.targeting.scan_period) then return end

  if State.combat then
    if Table.contains(State.combat.list, entity) then return end

    for _, e in ipairs(State.combat.list) do
      if State.hostility:get(entity, e) == "ally"
        and (entity.position - e.position):abs2() <= self.targeting.support_range
      then
        State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
        State:start_combat({entity})
      end
    end
  end

  local target = tk.find_target(entity, self.targeting.scan_range, self._vision_map)
  if target then
    State:add(animated.fx("engine/assets/sprites/animations/aggression", entity.position))
    State:start_combat({target, entity})
  end
end

Ldump.mark(combat_ai, {}, ...)
return combat_ai
