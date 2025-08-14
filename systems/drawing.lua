local ui = require("engine.tech.ui")

return Tiny.processingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and entity.view ~= "grids"
  end,

  preProcess = function()
    State.mode:draw_grid()
  end,

  process = function(_, entity)
    State.mode:draw_entity(entity)
  end,

  postProcess = function()
    ui.start()
    State.mode:draw_gui()
    ui.finish()
  end,
}
