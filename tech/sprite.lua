local ffi = require("ffi")


local sprite = {utility = {}}

local pull_anchors

--- @alias sprite sprite_image | sprite_atlas

--- @class sprite_image
--- @field type "image"
--- @field image love.Image
--- @field anchors table<anchor, vector?>

--- @param base string|love.ImageData
--- @return sprite_image
sprite.image = function(base)
  if type(base) == "string" then
    base = love.image.newImageData(base)
  end

  local anchors = pull_anchors(base)
  return {
    type = "image",
    anchors = anchors,
    image = love.graphics.newImage(base),
  }
end

--- @class sprite_atlas NOTICE shared pointer, do not mutate
--- @field type "atlas"
--- @field quad love.Quad
--- @field image love.Image

--- @return sprite_atlas
sprite.from_atlas = Memoize(function(index, cell_size, atlas_image)
  local quad = sprite.utility.get_atlas_quad(index, cell_size, atlas_image:getDimensions())
  return {
    type = "atlas",
    quad = quad,
    image = love.graphics.newImage(sprite.utility.cut_out(atlas_image, quad)),
  }
end)

--- @param index integer
--- @param cell_size integer
--- @param atlas_w integer
--- @param atlas_h integer
sprite.utility.get_atlas_quad = function(index, cell_size, atlas_w, atlas_h)
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

--- @param image love.Image
--- @param quad love.Quad
--- @return love.ImageData
sprite.utility.cut_out = function(image, quad)
  local canvas = image_to_canvas(image)
  return canvas:newImageData(0, nil, quad:getViewport())
end

--- @enum (key) anchor
local anchors = {
  parent       = Vector.hex("ff0000"):mul_mut(256):map(math.floor),
  hand         = Vector.hex("fb0000"):mul_mut(256):map(math.floor),
  offhand      = Vector.hex("f70000"):mul_mut(256):map(math.floor),
  head         = Vector.hex("f30000"):mul_mut(256):map(math.floor),
  right_pocket = Vector.hex("ef0000"):mul_mut(256):map(math.floor),
}

local color_eq = function(v, color)
  return (
    math.abs(v[1] - color.r) <= 2 and
    math.abs(v[2] - color.g) <= 2 and
    math.abs(v[3] - color.b) <= 2 and
    (not v[4] or math.abs(v[4] - color.a) <= 2)
  )
end

ffi.cdef [[
  typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
  } Color;
]]

--- @param base love.ImageData
pull_anchors = function(base)
  local w, h = base:getDimensions()
  local pixels = ffi.cast("Color*", base:getFFIPointer())

  local main_color
  for i = 0, w * h - 1 do
    local color = pixels[i]
    if color.a > 0
      and Fun.iter(anchors):all(function(_, a) return not color_eq(a, color) end)
    then
      main_color = color
      break
    end
  end

  local result = {}

  for x = 0, w - 1 do
    for y = 0, h - 1 do
      local i = y * w + x
      local color = pixels[i]
      local anchor_name = Fun.iter(anchors)
        :filter(function(_, v) return color_eq(v, color) end)
        :nth(1)

      if anchor_name then
        result[anchor_name] = V(x, y)
        pixels[i].r = main_color.r
        pixels[i].g = main_color.g
        pixels[i].b = main_color.b
        pixels[i].a = main_color.a
      end
    end
  end

  return result
end

Ldump.mark(sprite, {}, ...)
return sprite
