local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "display",
  base_callback = "draw",
  update = function()
    local choice = ui.choice({
      "New game",
      "Load game",
    })

    if choice == 1 then
      Log.info("Start a new game")
    elseif choice == 2 then
      Log.info("Load a save")
    end

    ui.finish()
  end,
}
