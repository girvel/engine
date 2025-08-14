local ui = require("engine.tech.ui")

return Tiny.processingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = Tiny.requireAll("sprite", "position"),

  process = function(_, entity)
    State.mode:draw_entity(entity)
  end,

  postProcess = function()
    ui.start()
    State.mode:draw_gui()
    ui.finish()
  end,
}
