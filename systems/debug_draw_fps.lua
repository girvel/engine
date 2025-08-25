return Tiny.system {
  codename = "debug_draw_fps",
  base_callback = "draw",
  update = function()
    if State.debug then
      love.graphics.print("%.2f" % {1 / love.timer.getAverageDelta()})
    end
  end,
}
