local api = require "engine.tech.api"
local screenplayer = {}

--- @class screenplayer
--- @field stack moonspeak_script[]
--- @field characters table<string, entity>
local methods = {}
local mt = {__index = methods}

--- @param path string
--- @return screenplayer
screenplayer.new = function(path, characters)
  return setmetatable({
    stack = {Moonspeak.read(love.filesystem.read(path))},
    characters = characters,
  }, mt)
end

--- @async
methods.lines = function(self)
  local branch = Table.last(self.stack)

  local block = table.remove(branch, 1)
  if block.type == "code" then
    block = table.remove(branch, 1)
  end
  assert(block.type == "lines", "Screenplayer expected lines")

  for _, line in ipairs(block.lines) do
    assert(
      line.source == "narration" or self.characters[line.source],
      "Unknown character %s" % {line.source}
    )
    api.line(self.characters[line.source], line.text)
  end
end

Ldump.mark(screenplayer, {}, ...)
return screenplayer
