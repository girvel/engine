local animated = require("engine.tech.animated")


local humanoid = {}

humanoid.cues = {
  blood = function()
    return Table.extend(
      animated.mixin("engine/assets/sprites/animations/blood"),
      {
        name = "Кровь",
        codename = "blood",
        slot = "blood",
        boring_flag = true,
      }
    )
  end,
}

humanoid.mixin = function()
  local result = animated.mixin("engine/assets/sprites/animations/humanoid")
  result.transparent_flag = true
  result.cues = humanoid.cues
  return result
end

Ldump.mark(humanoid, {}, ...)
return humanoid
