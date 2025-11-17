local safety = require "engine.tech.safety"


local systems = {
  -- love.keypressed
  {path = "engine/systems/ui_keypressed.lua"},
  {path = "engine/systems/debug_exit.lua"},

  -- love.mousemoved
  {path = "engine/systems/ui_mousemoved.lua"},

  -- love.mousepressed
  {path = "engine/systems/ui_mousepressed.lua"},

  -- love.mousereleased
  {path = "engine/systems/ui_mousereleased.lua"},

  -- love.update
  {path = "engine/systems/genesis.lua"},
  {path = "engine/systems/update_sound.lua", live = true},
  {path = "engine/systems/update_runner.lua", live = true},  -- together with acting
  {path = "engine/systems/acting.lua", live = true},
  {path = "engine/systems/animation.lua", live = true},
  {path = "engine/systems/ui_update.lua"},
  {path = "engine/systems/drifting.lua", live = true},
  {path = "engine/systems/timed_death.lua", live = true},
  {path = "engine/systems/running.lua", live = true},

  -- love.draw
  {path = "engine/systems/drawing.lua"},
}

return Fun.iter(systems)
  :map(function(e)
    local system = assert(love.filesystem.load(e.path))()
    if e.live then
      system = safety.live_system(system)
    end
    return safety.for_system(system)
  end)
  :totable()
