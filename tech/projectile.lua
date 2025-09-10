local sprite = require("engine.tech.sprite")


local projectile = {}

local TIMEOUT = 4

--- @param entity entity entity to be launched
--- @param target entity
--- @param speed number
--- @return promise
projectile.launch = function(entity, target, speed)
  local promise = Promise.new()
  State:add(entity, {
    drift = Vector.zero,
    ai = {
      observe = function(entity)
        local target_position = target.position + V(.5, .5)
        entity.drift = (target_position - entity.position):normalized_mut():mul_mut(speed)
        entity.rotation = math.atan2(entity.drift.y, entity.drift.x)
        if Period(TIMEOUT, promise) or (target_position - entity.position):abs() < .25 then
          promise:resolve()
          State:remove(entity)
        end
      end,
    }
  })

  return promise
end

Ldump.mark(projectile, {}, ...)
return projectile
