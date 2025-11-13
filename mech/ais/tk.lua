local healing_word = require("engine.mech.spells.healing_word")
local animate_dead = require("engine.mech.spells.animate_dead")
local fighter = require("engine.mech.class.fighter")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local api = require("engine.tech.api")


local tk = {}

--- @param entity entity
--- @param r number
--- @param vision_map tcod_map
--- @return entity?
tk.find_target = function(entity, r, vision_map)
  vision_map:refresh_fov(entity.position, r)
  for d in Iteration.rhombus(r) do
    local e = State.grids.solids:slow_get(entity.position + d)
    if e
      and State.hostility:get(entity, e) == "enemy"
      and e.hp and e.hp > 0
      and vision_map:is_visible_unsafe(unpack(e.position))
      and (not State.runner.locked_entities[e])
    then
      return e
    end
  end
end

--- @param entity entity
--- @param target entity
--- @param vision_map tcod_map
tk.preserve_line_of_fire = function(entity, target, vision_map)
  local best_p
  for d in Iteration.rhombus(entity.resources.movement) do
    local p = entity.position + d
    if not State.grids.solids:can_fit(p) then goto continue end

    vision_map:refresh_fov(p, actions.BOW_ATTACK_RANGE)

    if vision_map:is_visible_unsafe(unpack(target.position)) then
      best_p = p
      break
    end
    vision_map:free()

    ::continue::
  end

  if best_p then
    api.travel(entity, best_p, true)
  else
    api.travel(entity, target.position, true)
  end
end

--- @async
--- @param entity entity
tk.heal = function(entity)
  if entity.hp <= entity:get_max_hp() / 2 and fighter.second_wind:act(entity) then
    async.sleep(.2)
  end

  do
    if animate_dead.base:is_available(entity) then
      Log.trace("Raise dead is available to %s", entity)
      for v in Iteration.rhombus(20) do
        local p = v:add_mut(entity.position)
        local target = State.grids.marks:slow_get(p)
        local spell = animate_dead.new(target)
        if entity.codename:find("priest") and target then
          Log.traces(Inspect(target))
        end
        if spell:is_available(entity) then
          if not spell:act(entity) then break end
          entity.animation._end_promise:wait()
          if not animate_dead.base:is_available(entity) then
            break
          end
        end
      end
    elseif entity.codename:find("priest") then
      Log.trace("Raise dead is unavailable to %s;\n%s\n%s", entity, Inspect(entity.resources), Inspect(animate_dead.base))
    end
  end

  for spell_level = 2, 1, -1 do
    local base = healing_word.base(spell_level)
    if not base:is_available(entity) then goto continue end

    Log.trace("healing_word_%s is available for %s", spell_level, entity)
    for v in Iteration.rhombus(base.radius) do
      local p = v:add_mut(entity.position)
      local target = State.grids.solids:slow_get(p)
      if target and target.hp and target.hp < target:get_max_hp() and State.hostility:get(entity, target) == "ally" then
        Log.trace("Cast healing_word_%s on %s", spell_level, target)
        if not healing_word.new(spell_level, target):act(entity) then break end
        entity.animation._end_promise:wait()
        if not base:is_available(entity) then break end
      end
    end

    ::continue::
  end
end


--- @class ai_targeting
--- @field scan_period number time period determining target search frequency
--- @field scan_range number radius in which to search for target
--- @field support_range number radius in which to support members of the faction in combat
--- @field range number radius in which to continue targeting a single entity

--- @class ai_targeting_optional
--- @field scan_period? number time period determining target search frequency
--- @field scan_range? number radius in which to search for target
--- @field support_range? number radius in which to support members of the faction in combat
--- @field range? number radius in which to continue targeting a single entity

Ldump.mark(tk, {}, ...)
return tk
