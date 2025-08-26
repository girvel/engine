return Tiny.system {
  codename = "update_rails",
  base_callback = "update",
  update = function(self, dt)
    if State.rails then  -- may occur in loading
      State.rails:update(dt)
    end
  end,
}
