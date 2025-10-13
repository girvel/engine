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

    local current_pack = animation.pack[animation.current]
    if not current_pack then
      Error("%s is missing animation %s", Name.code(entity), animation.current)
    end

    -- even if animation is 1 frame idle, still should play out for 1-frame FXs
    animation.frame = animation.frame + dt * DEFAULT_ANIMATION_FPS
    if math.floor(animation.frame) > #current_pack then
      entity:animate(animation.next)
      current_pack = animation.pack[animation.current]
    end
    entity.sprite = current_pack[math.floor(animation.frame)]
  end,
}
