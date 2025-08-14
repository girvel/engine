local ldtk = {}

ldtk.load = function()
  return {
    entities = {
      {
        sprite = {
          image = love.graphics.newImage("engine/assets/sprites/moose_dude.png"),
        },
        position = V(64, 64),
      },
    },
  }
end

return Ldump.mark(ldtk, {}, ...)
