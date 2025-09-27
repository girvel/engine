local water = {}

local build_love_shader
build_love_shader = function(palette_path, palette_real_colors_n)
  local result = love.graphics.newShader([[
    uniform vec4 palette[%s];

    vec4 match(vec4 color) {
      float min_distance = 1;
      vec4 closest_color;
      for (int i = 0; i < %s; i++) {
          vec4 current_color = palette[i];
          float distance = (
              pow(current_color.r - color.r, 2) +
              pow(current_color.g - color.g, 2) +
              pow(current_color.b - color.b, 2)
          );

          if (distance < min_distance) {
              min_distance = distance;
              closest_color = current_color;
          }
      }
      return closest_color;
    }

    uniform bool reflects;
    uniform Image reflection;
    uniform vec2 offset;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
      vec2 reflection_coords = texture_coords;
      reflection_coords.y = 1 - reflection_coords.y;

      texture_coords = mod(texture_coords - offset, 1);
      vec4 it = Texel(tex, texture_coords);
      if (!reflects) return it;
      vec4 it2 = Texel(reflection, reflection_coords);
      if (it2.a == 0) return it;
      return match(vec4((it + it2).rgb / 2.5, (it.a + it2.a) / 2));
    }
  ]] % {palette_real_colors_n, palette_real_colors_n})

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
      local offset = ((love.timer.getTime() * entity.water_velocity) % 16):map(math.floor) / 16
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
