local animated = require("engine.tech.animated")


local humanoid = {}

humanoid.mixin = function()
  local result = animated.mixin("engine/assets/sprites/animations/humanoid")
  result.transparent_flag = true
  return result
end

Ldump.mark(humanoid, {}, ...)
return humanoid
