local sprite = require("engine.tech.sprite")


local animated = {}

--- @class animated_mixin
--- @field animation {pack: table<string, sprite_image[]>, paused: boolean, current: string, frame: number, _end_promise: promise}
--- @field sprite sprite_image
local methods = {}

local load_pack

--- @return animated_mixin
animated.mixin = function(path)
  return Table.extend({
    animation = {
      pack = load_pack(path),
      paused = false,
      current = "idle",
      frame = 1,
      _end_promise = nil,
    },
    sprite = {},
  }, methods)
end

--- @param animation_name? string
--- @return promise
methods.animate = function(self, animation_name)
  animation_name = animation_name or "idle"
  local animation = self.animation

  if animation._end_promise then
    animation._end_promise:resolve()
    animation._end_promise = nil
  end
  self:animation_set_paused(false)

  if self.direction then
    animation.current = animation_name .. "_" .. Vector.name_from_direction(self.direction)
  end

  if not animation.pack[animation.current] then
    animation.current = animation_name
  end

  animation.frame = 1

  -- NEXT animate inventory

  animation._end_promise = Promise.new()
  return animation._end_promise
end

--- @param value boolean
methods.animation_set_paused = function(self, value)
  self.animation.paused = value
  -- NEXT pause items (inventory)
end

-- NEXT atlas animations (when direction)
load_pack = Memoize(function(folder_path)
  local info = love.filesystem.getInfo(folder_path)
  assert(info, "No folder %q, unable to load animation" % {folder_path})
  assert(info.type == "directory", "%q is not a folder, unable to load animation" % {folder_path})

  local result = {}
  for _, file_name in ipairs(love.filesystem.getDirectoryItems(folder_path)) do
    local animation_name, frame_i do
      if not file_name:ends_with(".png") then goto continue end
      _, _, animation_name, frame_i = file_name:sub(1, -5):find("^(.+)_(%d+)$")
      frame_i = assert(tonumber(frame_i))
    end

    if not result[animation_name] then
      result[animation_name] = {}
    end

    result[animation_name][frame_i] = sprite.image(folder_path .. "/" .. file_name)

    ::continue::
  end

  return Log.trace(result)
end)

Ldump.mark(animated, {}, ...)
return animated
