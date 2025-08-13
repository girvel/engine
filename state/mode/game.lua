local ui = require("engine.tech.ui")


local game = {}

game.gui = function()
  ui.text("<game>")
end

return Ldump.mark(game, {}, ...)
