local audio = {}

--- @class state_audio
--- @field _playlist sound[]
--- @field _playlist_paused boolean
--- @field _current sound
local methods = {}
local mt = {__index = methods}

--- @return state_audio
audio.new = function()
  return setmetatable({
    _playlist = {},
    _playlist_paused = false,
    _current = nil,
  }, mt)
end

--- @param playlist sound[]
methods.set_playlist = function(self, playlist)
  self._current = nil
  self._playlist = playlist
end

methods._update = function(self)
  if State.player then
    love.audio.setPosition(unpack(State.player.position))
  else
    love.audio.setPosition(-1000, -1000, 0)
  end

  local last_track = self._current

  if last_track and last_track.source:isPlaying()
    or #self._playlist == 0
    or self._playlist_paused
  then return end

  while true do
    self._current = Random.choice(self._playlist)
    if #self._playlist == 1 or self._current ~= last_track then break end
  end
  self._current:play()
end

--- @param value any
methods.set_paused = function(self, value)
  value = not not value
  if self._playlist_paused == value then return end

  self._playlist_paused = value

  if value then
    if self._current then
      self._current.source:pause()
    end
    Log.info("Paused ambient")
  else
    Log.info("Unpaused ambient")
  end
end

methods.reset = function(self)
  self._current.source:pause()
end

Ldump.mark(audio, {}, ...)
return audio
