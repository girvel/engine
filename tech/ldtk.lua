local ldtk = {}

--- @class level_config
--- @field grid_layers string[]
--- @field grid_complex_layers table<string, boolean>

ldtk.load = function(path)
  local module = require(path)
  return {
    config = assert(module.config, "missing .config field in level init module"),
    entities = {
      {
        sprite = {
          image = love.graphics.newImage("engine/assets/sprites/moose_dude.png"),
        },
        layer = "solids",
        position = V(64, 64),
        view = "grids",
      },
      {
        sprite = {
          image = love.graphics.newImage("engine/assets/sprites/moose_dude.png"),
        },
        layer = "solids",
        position = V(32, 32),
        view = "grids",
      },
    },
    size = V(128, 128),
  }
end

return Ldump.mark(ldtk, {}, ...)
