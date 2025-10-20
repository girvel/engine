local mark = require("engine.tech.mark")
local sprite = require("engine.tech.sprite")
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

local blood_mark = function()
  local atlas = love.image.newImageData("engine/assets/sprites/blood_mark.png")
  return {
    codename = "blood_mark",
    boring_flag = true,
    sprite = sprite.image(sprite.utility.select(atlas, math.random(1, 2))),
  }
end

humanoid.add_blood_mark = mark(blood_mark)

humanoid.mixin = function()
  local result = animated.mixin("engine/assets/sprites/animations/humanoid")
  result.transparent_flag = true
  result.cues = humanoid.cues
  result.on_death = humanoid.add_blood_mark
  result.on_half_hp = humanoid.add_blood_mark
  return result
end

Ldump.mark(humanoid, {}, ...)
return humanoid
