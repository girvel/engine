local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "drawing",
  base_callback = "draw",
  update = function()
    ui.start()
    State.display:gui()
    ui.finish()
  end,
}
