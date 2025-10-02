local tcod = require("engine.tech.tcod")
local actions = require("engine.mech.actions")
local api = require("engine.tech.api")


local tk = {}

--- @param entity entity
--- @param r number
--- @return entity?
tk.find_target = function(entity, r)
  for d in Iteration.rhombus(r) do
    local e = State.grids.solids:slow_get(entity.position + d)
    if e and State.hostility:get(entity, e) and e.hp and e.hp > 0 then
      return e
    end
  end
end

tk.preserve_line_of_fire = function(entity, target)
  local best_p
  for d in Iteration.rhombus(entity.resources.movement) do
    local p = entity.position + d
    if not State.grids.solids:can_fit(p) then goto continue end

    local snapshot = tcod.copy(State.grids.solids)
    snapshot:refresh_fov(p, actions.BOW_ATTACK_RANGE)

    if snapshot:is_visible_unsafe(unpack(target.position)) then
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

--- @class ai_targeting
--- @field scan_period number time period determining target search frequency
--- @field scan_range number radius in which to search for target
--- @field range number radius in which to continue targeting a single entity

--- @class ai_targeting_optional
--- @field scan_period? number time period determining target search frequency
--- @field scan_range? number radius in which to search for target
--- @field range? number radius in which to continue targeting a single entity

Ldump.mark(tk, {}, ...)
return tk
