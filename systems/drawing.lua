local ui = require("engine.tech.ui")

return Tiny.processingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and not entity.grid_layer
  end,

  preProcess = function(_, dt)
    State.mode:draw_grid(dt)
  end,

  process = function(_, entity, dt)
    State.mode:draw_entity(entity, dt)
  end,

  postProcess = function(_, dt)
    ui.start()
    State.mode:draw_gui(dt)
    ui.finish()
  end,
}
