local ui = require("engine.tech.ui")


local debug_overlay = {}

debug_overlay.draw = function(dt)
  ui.text("%.2f" % {1 / love.timer.getAverageDelta()})

  if State.rails then
    local enabled = Fun.pairs(State.rails.runner.scenes)
      :map(function(k, v) return k end)
      :totable()

    ui.text("enabled:")
    for k, v in pairs(State.rails.runner.scenes) do
      if not v.disabled then
        ui.text("- " .. k)
      end
    end

    ui.text("running:")
    for _, v in ipairs(State.rails.runner._scene_runs) do
      ui.text("- " .. v.name)
    end
  end
end

Ldump.mark(debug_overlay, {}, ...)
return debug_overlay
