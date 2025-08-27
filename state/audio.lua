local audio = {}

--- @class state_audio
--- @field _playlist sound[]
--- @field _paused boolean
--- @field _current sound
local methods = {}
local mt = {__index = methods}

--- @return state_audio
audio.new = function()
  return setmetatable({
    _playlist = {},
    _paused = false,
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
  if last_track and last_track.source:isPlaying() or #self._playlist == 0 then return end

  while true do
    self._current = Random.choice(self._playlist)
    if #self._playlist == 1 or self._current ~= last_track then break end
  end
  self._current:play()
end

Ldump.mark(audio, {}, ...)
return audio
