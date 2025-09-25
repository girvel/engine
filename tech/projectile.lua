local sprite = require("engine.tech.sprite")


local projectile = {}

local TIMEOUT = 4

--- @param parent entity
--- @param entity item entity to be launched
--- @param target entity|vector
--- @param speed number
--- @return promise
projectile.launch = function(parent, entity, target, speed)
  local promise = Promise.new()
  State:add(entity, {
    layer = "fx_over",
    -- TODO item.get_anchor, considering slot may == "hands" or anchors may mismatch returning
    --   Vector.zero
    position = parent.position + parent.sprite.anchors[entity.anchor or entity.slot] / 16,
    direction = Vector.right,
    drift = Vector.zero,
    ai = {
      observe = function(entity)
        local target_position = (getmetatable(target) == Vector.mt and target or target.position)
          + V(.5, .5)

        entity.drift = (target_position - entity.position):normalized_mut():mul_mut(speed)
        entity.rotation = math.atan2(entity.drift.y, entity.drift.x)
        if Period(TIMEOUT, promise) or (target_position - entity.position):abs() < .25 then
          promise:resolve()
          State:remove(entity)
        end
      end,
    }
  })
  entity:animate(nil, true)

  return promise
end

Ldump.mark(projectile, {}, ...)
return projectile
