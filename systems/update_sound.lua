return Tiny.system {
  codename = "update_sound",
  base_callback = "update",
  update = function(self, dt)
    if State.player then
      love.audio.setPosition(unpack(State.player.position))
    end
  end,
}
