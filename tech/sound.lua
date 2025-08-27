--- Module for storing and producing sounds
---
--- Wraps LOVE functions in a convenient API; also, implements serializion of dynamically changed
--- sources.
local sound = {}

--- @alias sound_event "hit"|"walk"

--- @class sound
--- @field source love.Source
--- @field _path string
local methods = {}
local mt = {__index = methods}

--- @param path string
--- @param volume? number
--- @return sound
sound.new = Memoize(function(path, volume)
  local source = love.audio.newSource(path, "static")
  if volume then source:setVolume(volume) end
  if source:getChannelCount() == 1 then
    source:setRelative(true)
  end
  return setmetatable({
    source = source,
    _path = path,
  }, mt)
end)

--- @class sound_multiple: { [integer]: sound }
local multiple_methods = {}
local multiple_mt = {__index = multiple_methods}

--- Load all sounds from a directory
--- @param dir_path string
--- @param volume? number
--- @return sound_multiple
sound.multiple = Memoize(function(dir_path, volume)
  return setmetatable(Fun.iter(love.filesystem.getDirectoryItems(dir_path))
    :map(function(path) return sound.new(dir_path .. "/" .. path, volume) end)
    :totable(), multiple_mt)
end)

--- @enum (key) sound_size
sound.sizes = {
  small = {1, 10},
  medium = {7, 20},
  large = {15, 30},
}

--- Creates a fully independent copy of the sound
--- @param self sound
--- @return sound
methods.clone = function(self)
  return setmetatable({
    source = self.source:clone(),
  }, mt)
end

--- @generic T: sound
--- @param self T
--- @param position vector
--- @param size? sound_size
--- @return T
methods.place = function(self, position, size)
  --- @cast self sound
  local limits = assert(
    sound.sizes[size or "small"],
    "Incorrect sound size %s; sounds can be small, medium or large" % tostring(size)
  )

  self.source:setRelative(false)
  self.source:setPosition(unpack(position))
  self.source:setAttenuationDistances(unpack(limits))
  self.source:setRolloff(2)
  return self
end

--- @generic T: sound
--- @param self T
--- @return T
methods.play = function(self)
  --- @cast self sound
  self.source:play()
  return self
end

--- @generic T: sound
--- @param self T
--- @return T
methods.stop = function(self)
  --- @cast self sound
  self.source:stop()
  return self
end

mt.__serialize = function(self)
  local path = self._path
  local volume = self.source:getVolume()
  local looping = self.source:isLooping()
  local relative, x, y, rolloff, ref, max
  if self.source:getChannelCount() == 1 then
    relative = self.source:isRelative()
    x, y = self.source:getPosition()
    rolloff = self.source:getRolloff()
    ref, max = self.source:getAttenuationDistances()
  end

  return function()
    local result = sound.new(path, volume)
    result.source:setLooping(looping or false)
    if result.source:getChannelCount() == 1 then
      result.source:setRelative(relative)
      result.source:setPosition(x, y, 0)
      result.source:setRolloff(rolloff)
      result.source:setAttenuationDistances(ref, max)
    end
    return result
  end
end


--- @generic T: sound
--- @param self T
--- @param value boolean
--- @return T
methods.set_looping = function(self, value)
  --- @cast self sound
  self.source:setLooping(value)
  return self
end

--- @param position vector
multiple_methods.play_at = function(self, position)
  return Random.choice(self):clone():place(position):play()
end

multiple_methods.play = function(self)
  return Random.choice(self):clone():play()
end

Ldump.mark(sound, {}, ...)
return sound
