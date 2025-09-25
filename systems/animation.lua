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

    local current_pack = assert(
      animation.pack[animation.current],
      ("%s is missing animation %s"):format(Name.code(entity), animation.current)
    )

    if not animation.current:starts_with("idle") or #current_pack > 1 then
      animation.frame = animation.frame + dt * DEFAULT_ANIMATION_FPS
      if math.floor(animation.frame) > #current_pack then
        entity:animate("idle")
      end
    end
    entity.sprite = current_pack[math.floor(animation.frame)]
  end,
}
