local api = require "engine.tech.api"
local screenplay = {}

--- @class screenplay
--- @field stack (moonspeak|moonspeak_options)[]
--- @field characters table<string, entity>
local methods = {}
local mt = {__index = methods}

--- @param path string
--- @param characters table<string, entity>
--- @return screenplay
screenplay.new = function(path, characters)
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

--- @nodiscard
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

  assert(options.options[n].branch)
  table.insert(self.stack, options.options[n].branch)
end

methods.finish_option = function(self)
  assert(not Table.last(self.stack).type)
  table.remove(self.stack)
  assert(Table.last(self.stack).type == "options")
end

methods.start_branches = function(self)
  local block = get_block(self, "branches")  --[[@as moonspeak_branches]]
  table.insert(self.stack, block)
end

methods.finish_branches = function(self)
  assert(Table.last(self.stack).type == "branches")
  table.remove(self.stack)
end

methods.start_branch = function(self, n)
  local branches = Table.last(self.stack)  --[[@as moonspeak_branches]]
  assert(branches.type == "branches")
  assert(branches.branches[n].branch)
  table.insert(self.stack, branches.branches[n].branch)
end

methods.finish_branch = function(self)
  assert(not Table.last(self.stack).type)
  table.remove(self.stack)
  assert(Table.last(self.stack).type == "branches")
end

--- @return string
methods.literal = function(self)
  local block = get_block(self, "literal")  --[[@as moonspeak_literal]]
  return block.text
end

methods.finish = function(self)
  assert(#self.stack == 1, "Screenplay contains %s unclosed scopes;\nstack = %s" % {
    #self.stack - 1, Inspect(self.stack)
  })
  assert(#self.stack[1] == 0, "Expected script to end, got %s more entries;\nstack[1] = %s" % {
    #self.stack[1], Inspect(self.stack[1])
  })
end

get_block = function(player, type)
  local branch = Table.last(player.stack)
  local block = table.remove(branch, 1)
  if block.type == "code" then
    block = table.remove(branch, 1)
  end
  assert(block.type == type, "Screenplay expected %s, got %s" % {type, block.type})
  return block
end

Ldump.mark(screenplay, {}, ...)
return screenplay
