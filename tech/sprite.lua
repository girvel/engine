local sprite = {}

local get_atlas_quad, cut_out

--- @alias sprite sprite_image | sprite_atlas

--- @class sprite_image NOTICE shared pointer, do not mutate
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

--- @class sprite_atlas NOTICE shared pointer, do not mutate
--- @field type "atlas"
--- @field quad love.Quad
--- @field image love.Image

--- @return sprite_atlas
sprite.from_atlas = Memoize(function(index, cell_size, atlas_image)
  local quad = get_atlas_quad(index, cell_size, atlas_image:getDimensions())
  return {
    type = "atlas",
    quad = quad,
    image = cut_out(atlas_image, quad),
  }
end)

get_atlas_quad = function(index, cell_size, atlas_w, atlas_h)
  local w = atlas_w
  local x = (index - 1) * cell_size
  return love.graphics.newQuad(
    x % w, math.floor(x / w) * cell_size, cell_size, cell_size, atlas_w, atlas_h
  )
end

local image_to_canvas = Memoize(function(image)
  local result = love.graphics.newCanvas(image:getDimensions())
  love.graphics.setCanvas(result)
  love.graphics.draw(image)
  love.graphics.setCanvas()
  return result
end)

cut_out = function(image, quad)
  local canvas = image_to_canvas(image)
  return love.graphics.newImage(canvas:newImageData(0, nil, quad:getViewport()))
end

Ldump.mark(sprite, {}, ...)
return sprite
