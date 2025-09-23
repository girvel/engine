local sprite = require("engine.tech.sprite")


local animated = {}

--- @alias animation_pack table<string, sprite_image[]>

--- @class animation
--- @field pack animation_pack
--- @field paused boolean
--- @field current string
--- @field frame number
--- @field _end_promise promise

--- @class _animated_methods
local methods = {}

local load_pack

--- @param path string
--- @param n? integer if nil, interprets animation atlas as directional; else, uses nth cell from each frame
--- @return table
animated.mixin = function(path, n)
  local pack do
    local base_pack = load_pack(path)
    if n then
      pack = base_pack[n]
    elseif #base_pack == 1 then
      pack = base_pack[1]
    else
      assert(#base_pack == 4)
      pack = {}
      for i, direction_name in ipairs {"up", "left", "down", "right"} do
        for animation_name, frames in pairs(base_pack[i]) do
          pack[animation_name .. "_" .. direction_name] = frames
        end
      end
    end
  end

  return Table.extend({
    animation = {
      pack = pack,
      paused = false,
      _end_promise = nil,
    },
    sprite = select(2, next(pack))[1],
  }, methods)
end

--- @param entity entity
--- @param path string
animated.change_pack = function(entity, path)
  entity.animation.pack = load_pack(path)
  entity:animate()
end

--- @param path string
--- @param position vector
--- @param is_over? boolean
animated.fx = function(path, position, is_over)
  local result = animated.mixin(path)

  local _, _, head = path:find("/?([^/]+)$")
  result.codename = head and (head .. "_fx") or "unnamed_fx"
  result.boring_flag = true
  result.position = position
  result.layer = is_over and "fx_over" or "fx_under"

  result:animate():next(function() State:remove(result) end)

  return result
end

--- @param self entity
--- @param animation_name? string
--- @param assertive? boolean whether to assert that animation exists
--- @return promise
methods.animate = function(self, animation_name, assertive)
  animation_name = animation_name or "idle"
  local animation = self.animation

  if animation._end_promise then
    animation._end_promise:resolve()
    animation._end_promise = nil
  end
  self:animation_set_paused(false)

  if self.direction then
    local dirname = Vector.name_from_direction(self.direction)
    animation.current = animation_name .. "_" .. dirname
    if not animation.pack[animation.current] then
      assert(not assertive, ("Missing %s for entity %s"):format(animation_name, Name.code(self)))
      animation.current = "idle_" .. dirname
    end
  else
    animation.current = animation_name
    if not animation.pack[animation.current] then
      assert(not assertive, ("Missing %s for entity %s"):format(animation_name, Name.code(self)))
      animation.current = "idle"
    end
  end

  animation.frame = 1

  if self.inventory then
    for _, item in pairs(self.inventory) do
      if item.animate and not item.animated_independently_flag then
        item:animate(animation_name)
      end
    end
  end

  animation._end_promise = Promise.new()
  return animation._end_promise
end

--- @param self entity
--- @param value boolean
methods.animation_set_paused = function(self, value)
  self.animation.paused = value

  if self.inventory then
    for _, item in pairs(self.inventory) do
      if item.animation and not item.animated_independently_flag then
        item.animation.paused = value
      end
    end
  end
end

--- @param folder_path string
--- @return animation_pack[]
load_pack = Memoize(function(folder_path)
  local info = love.filesystem.getInfo(folder_path)
  assert(info, "No folder %q, unable to load animation" % {folder_path})
  assert(info.type == "directory", "%q is not a folder, unable to load animation" % {folder_path})

  local w, h, parts_n
  local result = {}
  for _, file_name in ipairs(love.filesystem.getDirectoryItems(folder_path)) do
    local animation_name, frame_i do
      if not file_name:ends_with(".png") then goto continue end
      _, _, animation_name, frame_i = file_name:sub(1, -5):find("^(.+)_(%d+)$")
      frame_i = assert(
        tonumber(frame_i),
        "%q not in format <animation name>_<frame index>.png" % {file_name}
      )  --[[@as number]]
    end

    local full_path = folder_path .. "/" .. file_name
    local data = love.image.newImageData(full_path)

    do
      local next_w, next_h = data:getDimensions()
      if not w then
        assert(not h)
        w = next_w
        h = next_h
        parts_n = w * h / 16 / 16
        for i = 1, parts_n do
          result[i] = {}
        end
      else
        assert(
          next_w == w,
          ("%q's width %s is not equal to previous encountered %s"):format(full_path, next_w, w)
        )
        assert(
          next_h == h,
          ("%q's height %s is not equal to previous encountered %s"):format(full_path, next_h, h)
        )
      end
    end

    local image = love.graphics.newImage(data)
    for i = 1, parts_n do
      local pack = result[i]
      pack[animation_name] = pack[animation_name] or {}
      pack[animation_name][frame_i] = sprite.image(
        sprite.utility.cut_out(image, sprite.utility.get_atlas_quad(i, 16, w, h))
      )
    end

    ::continue::
  end

  return result
end)

Ldump.mark(animated, {}, ...)
return animated
