local DEFAULT_ANIMATION_FPS = 6

return Tiny.processingSystem {
  codename = "animation",
  base_callback = "update",
  filter = Tiny.requireAll("animation"),

  onAdd = function(_, entity)
    if not entity.animation.current then
      entity:animate()
    end
  end,

  --- @param entity entity
  process = function(_, entity, dt)
    local animation = entity.animation
    if animation.paused then return end

    if not animation.current:starts_with("idle") or #animation.pack[animation.current] > 1 then
      animation.frame = animation.frame + dt * DEFAULT_ANIMATION_FPS
      if math.floor(animation.frame) > #animation.pack[animation.current] then
        entity:animate("idle")
      end
    end
    entity.sprite = animation.pack[animation.current][math.floor(animation.frame)]
  end,
}
