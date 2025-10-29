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
      if State.debug then
        Log.trace("found %s", best_p)
        for i in pairs(State.debug_overlay.points) do
          State.debug_overlay.points[i] = nil
        end
        local i = 0
        for dx = -10, 10 do
          for dy = -10, 10 do
            i = i + 1
            if vision_map:is_visible_unsafe(p.x + dx, p.y + dy) then
              State.debug_overlay.points[i] = {
                position = p + V(dx, dy),
                color = (not vision_map:is_transparent_unsafe(p.x + dx, p.y + dy))
                  and Vector.hex("ff0000") or Vector.white,
                view = "grid",
              }
            end
          end
        end
      end
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
