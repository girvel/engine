local safety = require "engine.tech.safety"


local result = {
  -- love.keypressed
  require("engine.systems.ui_keypressed"),
  require("engine.systems.debug_exit"),

  -- love.mousemoved
  require("engine.systems.ui_mousemoved"),

  -- love.mousepressed
  require("engine.systems.ui_mousepressed"),

  -- love.mousereleased
  require("engine.systems.ui_mousereleased"),

  -- love.wheelmoved
  require("engine.systems.ui_wheelmoved"),

  -- love.update
  require("engine.systems.genesis"),
  safety.live_system(require("engine.systems.update_sound")),
  safety.live_system(require("engine.systems.update_runner")),  -- together with acting
  safety.live_system(require("engine.systems.acting")),
  safety.live_system(require("engine.systems.animation")),
  require("engine.systems.ui_update"),
  safety.live_system(require("engine.systems.drifting")),     -- small
  safety.live_system(require("engine.systems.timed_death")),  -- small
  safety.live_system(require("engine.systems.running")),      -- small

  -- love.draw
  require("engine.systems.drawing"),
}

Fun.iter(result):each(safety.for_system)

return result
