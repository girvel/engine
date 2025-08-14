local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_keypressed",
  base_callback = "keypressed",
  update = function(self, key)
    ui.handle_keypress(key)
  end,
}
