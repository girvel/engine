local ui = require("engine.tech.ui")


local game = {}

game.draw_gui = function()
  ui.text("<game>")
end

return Ldump.mark(game, {}, ...)
