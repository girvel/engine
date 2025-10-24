local water = {}

local build_love_shader
build_love_shader = function(palette_path, palette_real_colors_n)
  local result = love.graphics.newShader(string.format(
    love.filesystem.read("engine/tech/shaders/water.frag"),
    palette_real_colors_n,
    palette_real_colors_n
  ), nil)  --- @diagnostic disable-line

  do
    local palette = {}
    local palette_image_data = love.image.newImageData(palette_path)
    for x = 0, palette_real_colors_n - 1 do
      table.insert(palette, {palette_image_data:getPixel(x, 0)})
    end
    result:send("palette", unpack(palette))
  end

  Ldump.serializer.handlers[result] = function()
    return build_love_shader(palette_path, palette_real_colors_n)
  end
  return result
end

--- @param palette_path string
--- @param palette_real_colors_n number
--- @return shader
water.new = Memoize(function(palette_path, palette_real_colors_n)
  return {
    love_shader = build_love_shader(palette_path, palette_real_colors_n),

    preprocess = function(self, entity, dt)
      local offset = ((love.timer.getTime() * entity.water_velocity) % Constants.cell_size):map(math.floor) / Constants.cell_size
      self.love_shader:send("offset", offset)
      local image = self:_get_reflection_image(entity)
      self.love_shader:send("reflects", image ~= nil)
      if not image then return end
      self.love_shader:send("reflection", image)
    end,

    _get_reflection_image = function(_, entity)
      local reflected = State.grids.solids:slow_get(entity.position + Vector.up)
      if not reflected or reflected.low_flag then return nil end
      return reflected.sprite.image
    end
  }
end)

Ldump.mark(water, {
  new = {build_love_shader = {}},
}, ...)
return water
