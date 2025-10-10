return Tiny.system {
  codename = "update_shadows",
  base_callback = "update",
  update = function(self, dt)
    local start = State.perspective.vision_start
    local finish = State.perspective.vision_finish
    for x = start.x, finish.x do
      for y = start.y, finish.y do
        State.grids.shadows:unsafe_get(x, y).color = V(1, 1, 1, State.shadow:unsafe_get(x, y))
      end
    end
  end,
}
