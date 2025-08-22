local DEFAULT_ANIMATION_FPS = 6

return Tiny.processingSystem {
  codename = "animation",
  base_callback = "update",
  filter = Tiny.requireAll("animation"),

  onAdd = function(_, entity)
    entity:animate()
  end,

  --- @param entity animated_mixin
  process = function(_, entity, dt)
    local animation = entity.animation
    if animation.paused then return end

    animation.frame = animation.frame + dt * DEFAULT_ANIMATION_FPS
    if not animation.pack[animation.current] then
      Log.trace(entity)
      Log.trace(animation.pack)
    end
    if math.floor(animation.frame) > #animation.pack[animation.current] then
      entity:animate("idle")
    end
    entity.sprite = animation.pack[animation.current][math.floor(animation.frame)]
  end,
}
