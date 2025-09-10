local sprite = require("engine.tech.sprite")


local projectile = {}

local TIMEOUT = 4

--- @param position vector
--- @param target entity
--- @param speed number
--- @return promise
projectile.launch = function(position, target, speed)
  local promise = Promise.new()
  State:add {
    codename = "projectile",
    sprite = sprite.image("assets/sprites/arrow.png"),
    position = position + V(.5, .5),
    layer = "fx_over",
    drift = Vector.zero,
    ai = {
      observe = function(entity)
        local target_position = target.position + V(.5, .5)
        entity.drift = (target_position - entity.position):normalized_mut():mul_mut(speed)
        entity.sprite.rotation = math.atan2(entity.drift.y, entity.drift.x)
        if Period(TIMEOUT, promise) or (target_position - entity.position):abs() < .25 then
          promise:resolve()
          State:remove(entity)
        end
      end,
    }
  }

  return promise
end

Ldump.mark(projectile, {}, ...)
return projectile
