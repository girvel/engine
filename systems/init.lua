return {
  -- love.keypressed
  require("engine.systems.ui_keypressed"),
  require("engine.systems.debug_exit"),

  -- love.mousemoved
  require("engine.systems.ui_mousemoved"),

  -- love.mousepressed
  require("engine.systems.ui_mousepressed"),

  -- love.update
  require("engine.systems.update_sound"),
  require("engine.systems.update_rails"),
  require("engine.systems.acting"),
  require("engine.systems.animation"),
  require("engine.systems.ui_update"),
  require("engine.systems.drifting"),     -- small
  require("engine.systems.timed_death"),  -- small
  require("engine.systems.running"),      -- small

  -- love.draw
  require("engine.systems.drawing"),
}
