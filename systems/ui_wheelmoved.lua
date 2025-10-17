local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_wheelmoved",
  base_callback = "wheelmoved",
  update = function(self, x, y)
    ui.handle_wheelmove(x, y)
  end,
}
