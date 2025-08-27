local sound = {}

--- @class sound
--- @field source love.Source
--- @field _path string
local methods = {}
local mt = {__index = methods}

--- @param path string
--- @param volume? number
--- @return sound
sound.new = function(path, volume)
  local source = love.audio.newSource(path, "static")
  if volume then source:setVolume(volume) end
  if source:getChannelCount() == 1 then
    source:setRelative(true)
  end
  return setmetatable({
    source = source,
  }, mt)
end

--- Creates a fully independent copy of the sound
--- @param self sound
--- @return sound
methods.clone = function(self)
  return setmetatable({
    source = self.source:clone(),
    _path = self._path,
  }, sound._mt)
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

--- @generic T: sound
--- @param self T
--- @param value boolean
--- @return T
methods.set_looping = function(self, value)
  --- @cast self sound
  self.source:setLooping(value)
  return self
end

--- Load all sounds from a directory
--- @param dir_path string
--- @param volume? number
--- @return sound[]
sound.multiple = function(dir_path, volume)
  return Fun.iter(love.filesystem.getDirectoryItems(dir_path))
    :map(function(path) return sound(dir_path .. "/" .. path, volume) end)
    :totable()
end

--- @enum (key) sound_size
sound.sizes = {
  small = {1, 10},
  medium = {7, 20},
  large = {15, 30},
}

Ldump.mark(sound, {}, ...)
return sound
