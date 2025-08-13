local ui = require("engine.tech.ui")


local loading_screen = {}

loading_screen.draw_gui = function()
  local t = love.timer.getTime()
  ui.text("." * (t % 4))
end

return Ldump.mark(loading_screen, {}, ...)
