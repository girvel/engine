local api = require "engine.tech.api"
local screenplayer = {}

--- @class screenplayer
--- @field stack (moonspeak_script|moonspeak_options)[]
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

local get_block

--- @async
methods.lines = function(self)
  local block = get_block(self, "lines")  --[[@as moonspeak_lines]]

  for _, line in ipairs(block.lines) do
    assert(
      line.source == "narration" or self.characters[line.source],
      "Unknown character %s" % {line.source}
    )
    api.line(self.characters[line.source], line.text)
  end
end

--- @return table<integer, string>
methods.start_options = function(self)
  local block = get_block(self, "options")  --[[@as moonspeak_options]]
  table.insert(self.stack, block)

  return Fun.iter(block.options)
    :map(function(b) return b.text end)
    :totable()
end

methods.finish_options = function(self)
  assert(Table.last(self.stack).type == "options")
  table.remove(self.stack)
end

methods.start_option = function(self, n)
  local options = Table.last(self.stack)
  assert(options.type == "options")

  table.insert(self.stack, assert(options.options[n].branch))
end

methods.finish_option = function(self)
  assert(not Table.last(self.stack).type)
  table.remove(self.stack)
  assert(Table.last(self.stack).type == "options")
end

methods.finish = function(self)
  assert(#self.stack == 1, "Screenplayer contains %s unclosed scopes" % {#self.stack - 1})
  assert(#self.stack[1] == 0, "Expected script to end, got %s more entries" % {#self.stack[1]})
end

get_block = function(player, type)
  local branch = Table.last(player.stack)
  local block = table.remove(branch, 1)
  if block.type == "code" then
    block = table.remove(branch, 1)
  end
  assert(block.type == type, "Screenplayer expected %s, got %s" % {type, block.type})
  return block
end

Ldump.mark(screenplayer, {}, ...)
return screenplayer
