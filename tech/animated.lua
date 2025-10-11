local sprite = require("engine.tech.sprite")


local animated = {}

--- @alias animation_pack table<string, sprite_image[]>

--- @alias animation_name "idle"|"move"|"hand_attack"|"offhand_attack"|"gesture"|"fast_gesture"|"clap"|"lying"|"interact"|"throw"|"bow_attack"|"hanging"

--- @class animation
--- @field pack animation_pack
--- @field paused boolean
--- @field current animation_name|string
--- @field next animation_name
--- @field frame number
--- @field _end_promise promise

--- @class _animated_methods
local methods = {}

local load_pack

--- @alias atlas_n integer|nil|"no_atlas"

--- @param path string
--- @param atlas_n atlas_n if nil, interprets animation atlas as directional; if "no_atlas", uses the frame as a whole; else, uses nth cell from each frame
--- @return table
animated.mixin = function(path, atlas_n)
  local pack = load_pack(path, atlas_n)
  return Table.extend({
    animation = {
      pack = pack,
      paused = false,
      next = "idle",
      _end_promise = nil,
    },
    sprite = select(2, next(pack))[1],
  }, methods)
end

--- @param entity entity
--- @param path string
--- @param atlas_n atlas_n
animated.change_pack = function(entity, path, atlas_n)
  entity.animation.pack = load_pack(path, atlas_n)
  entity:animate()
end

--- @param path string
--- @param position vector
--- @param is_over? boolean whether to display in fx_over or fv_under layer
animated.fx = function(path, position, is_over)
  local result = animated.mixin(path, "no_atlas")

  local _, _, head = path:find("/?([^/]+)$")
  result.codename = head and (head .. "_fx") or "unnamed_fx"
  result.boring_flag = true
  result.position = position
  result.layer = is_over and "fx_over" or "fx_under"

  result:animate():next(function() State:remove(result) end)

  return result
end

--- @param self entity
--- @param animation_name? string|animation_name
--- @param assertive? boolean whether to assert that animation exists
--- @param looped? boolean
--- @return promise
methods.animate = function(self, animation_name, assertive, looped)
  local animation = self.animation
  animation_name = animation_name or animation.next

  if animation._end_promise then
    animation._end_promise:resolve()
    animation._end_promise = nil
  end
  self:animation_set_paused(false)

  local dirname = self.direction and Vector.name_from_direction(self.direction)
  if dirname then
    animation.current = animation_name .. "_" .. dirname
  else
    animation.current = animation_name
  end

  if animation.pack[animation.current] then
    if looped then
      animation.next = animation_name
    end
  else
    if assertive then
      Error("Missing %s for entity %s", animation_name, self)
    end

    if dirname then
      animation.current = animation.next .. "_" .. dirname
    else
      animation.current = animation.next
    end
  end

  animation.frame = 1

  if self.inventory then
    for _, item in pairs(self.inventory) do
      if item.animate and not item.animated_independently_flag then
        item:animate(animation_name, false, looped)
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
local load_pack_raw = Memoize(function(folder_path, is_atlas)
  local info = love.filesystem.getInfo(folder_path)

  if not info then
    Error("No folder %q, unable to load animation", folder_path)
    return {}
  end

  if info.type ~= "directory" then
    Error("%q is not a folder, unable to load animation", folder_path)
    return {}
  end

  local w, h, parts_n
  local result = {}
  for _, file_name in ipairs(love.filesystem.getDirectoryItems(folder_path)) do
    local animation_name, frame_i do
      if not file_name:ends_with(".png") then goto continue end
      _, _, animation_name, frame_i = file_name:sub(1, -5):find("^(.+)_(%d+)$")
      frame_i = tonumber(frame_i)  --[[@as number]]

      if not frame_i then
        Error("%q not in format <animation name>_<frame index>.png", file_name)
        goto continue
      end
    end

    local full_path = folder_path .. "/" .. file_name
    local data = love.image.newImageData(full_path)

    do
      local next_w, next_h = data:getDimensions()
      if not w then
        assert(not h)
        w = next_w
        h = next_h

        if is_atlas then
          parts_n = w * h / Constants.cell_size / Constants.cell_size
          for i = 1, parts_n do
            result[i] = {}
          end
        else
          result[1] = {}
        end
      else
        if next_w ~= w then
          Error("%q's width %s is not equal to previous encountered %s", full_path, next_w, w)
        end
        if next_h ~= h then
          Error("%q's height %s is not equal to previous encountered %s", full_path, next_h, h)
        end
      end
    end

    if is_atlas then
      for i = 1, parts_n do
        local pack = result[i]
        pack[animation_name] = pack[animation_name] or {}
        pack[animation_name][frame_i] = sprite.image(
          sprite.utility.select(data, i)
        )
      end
    else
      local pack = result[1]
      pack[animation_name] = pack[animation_name] or {}
      pack[animation_name][frame_i] = sprite.image(data)
    end

    ::continue::
  end

  return result
end)

load_pack = function(path, atlas_n)
  local base_pack = load_pack_raw(path, atlas_n ~= "no_atlas")
  if atlas_n then
    if atlas_n == "no_atlas" then atlas_n = 1 end
    return base_pack[atlas_n]
  end

  if #base_pack ~= 4 then
    Error("Directional animation atlas %s should contain 4 cells, got %s", path, #base_pack)
  end

  local pack = {}
  for i, direction_name in ipairs {"up", "left", "down", "right"} do
    for animation_name, frames in pairs(base_pack[i]) do
      pack[animation_name .. "_" .. direction_name] = frames
    end
  end
  return pack
end

Ldump.mark(animated, {}, ...)
return animated
