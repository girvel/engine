return {
  -- love.keypressed
  require("engine.systems.ui_keypressed"),

  -- love.mousemoved
  require("engine.systems.ui_mousemoved"),

  -- love.mousepressed
  require("engine.systems.ui_mousepressed"),

  -- love.update
  require("engine.systems.acting"),
  require("engine.systems.animation"),
  require("engine.systems.ui_update"),

  -- love.draw
  require("engine.systems.drawing"),
  require("engine.systems.draw_fps"),
}
