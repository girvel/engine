local sprite = {}

--- @class sprite_image
--- @field type "image"
--- @field image love.Image

--- @param base string|love.ImageData
--- @return sprite_image
sprite.image = function(base)
  -- TODO anchors (when inventory)
  return {
    type = "image",
    image = love.graphics.newImage(base),
  }
end

Ldump.mark(sprite, {}, ...)
return sprite
