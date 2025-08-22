local animated = require("engine.tech.animated")


local humanoid = {}

--- @class humanoid_mixin: animated_mixin
--- @field transparent_flag true
--- @field direction vector

--- @return humanoid_mixin
humanoid.mixin = function()
  local result = animated.mixin("engine/assets/sprites/animations/humanoid")
  result.transparent_flag = true
  return result
end

Ldump.mark(humanoid, {}, ...)
return humanoid
