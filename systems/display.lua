return Tiny.system {
  codename = "display",
  base_callback = "draw",
  update = function(self)
    love.graphics.print("Hello, world!")
  end,
}
