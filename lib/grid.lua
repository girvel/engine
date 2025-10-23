local vector = require("engine.lib.vector")
local iteration = require("engine.lib.iteration")

--- indexing starts from 1
local grid = {}

--- @param size vector
--- @param factory? fun(): any
--- @return grid
grid.new = function(size, factory)
  assert(size)
  local inner_array = {}
  if factory then
    for i = 1, size[1] * size[2] do
        inner_array[i] = factory()
    end
  end
  return setmetatable({
    size = size,
    _inner_array = inner_array,
  }, grid.mt)
end

--- @param matrix any[][]
--- @param size vector
--- @return grid
grid.from_matrix = function(matrix, size)
  local result = grid.new(size)
  for x = 1, size[1] do
    for y = 1, size[2] do
      result._inner_array[result:_get_inner_index(x, y)] = matrix[y][x]
    end
  end
  return result
end

--- @class grid<T>: { [vector]: T }
--- @field size vector
--- @field _inner_array any[]
local methods = {}

--- @param self grid
--- @param v vector
--- @return boolean
methods.can_fit = function(self, v)
  return vector.zero < v and self.size >= v
end

--- @generic T, D
--- @param self grid<T>
--- @param v vector
--- @param default? D
--- @return T|D
methods.slow_get = function(self, v, default)
  assert(getmetatable(v) == vector.mt)
  if not self:can_fit(v) then return default end
  return self[v]
end

--- @generic T
--- @param self grid<T>
--- @param x integer
--- @param y integer
--- @return T
methods.unsafe_get = function(self, x, y)
  return self._inner_array[self:_get_inner_index(x, y)]
end

--- @generic T
--- @param self grid<T>
--- @param x integer
--- @param y integer
--- @param value T
methods.unsafe_set = function(self, x, y, value)
  self._inner_array[self:_get_inner_index(x, y)] = value
end

--- @generic T
--- @param self grid<T>
--- @return any
methods.iter = function(self)
  return Fun.iter(pairs(self._inner_array))
end

--- @generic T
--- @param self grid<T>
--- @param start vector
--- @param max_radius? integer
--- @return fun(): vector
methods.find_free_positions = function(self, start, max_radius)
  return coroutine.wrap(function()
    for d in iteration.rhombus(max_radius) do
      local p = d:add_mut(start)
      if not self:slow_get(p, true) then
        coroutine.yield(p)
      end
    end
  end)
end

--- @generic T
--- @param self grid<T>
--- @param start vector
--- @param max_radius? integer
--- @return vector?
methods.find_free_position = function(self, start, max_radius)
  return self:find_free_positions(start, max_radius)() or nil
end

--- @param x integer
--- @param y integer
--- @return integer
methods._get_inner_index = function(self, x, y)
  return x + (y - 1) * self.size[1]
end

--- @param i integer
--- @return integer, integer
methods._get_outer_index = function(self, i)
  return Math.loopmod(i, self.size.x), math.floor((i - 1) / self.size.x) + 1
end

grid.mt = {
  __index = function(self, v)
    local method = methods[v]
    if method then return method end

    assert(
      getmetatable(v) == vector.mt,
      ("Attempt to index grid with %s which is neither vector nor a method name"):format(v)
    )
    assert(self:can_fit(v), ("%s does not fit in grid border %s"):format(v, self.size))
    return self._inner_array[self:_get_inner_index(unpack(v))]
  end,

  __newindex = function(self, v, value)
    assert(self:can_fit(v), tostring(v) .. " does not fit into grid size " .. tostring(self.size))
    self._inner_array[self:_get_inner_index(unpack(v))] = value
  end,
}

--- @class iteration_bfs
--- @field _base grid<any>
--- @field _seen grid<true>
--- @field _next vector[]
--- @field _last vector?
--- @operator call:vector?,any
local bfs_methods = {}
iteration._bfs_mt = {__index = bfs_methods}

--- @param start vector
--- @return iteration_bfs
methods.bfs = function(self, start)
  local result = setmetatable({
    _base = self,
    _seen = grid.new(self.size),
    _next = {start},
  }, iteration._bfs_mt)
  result._seen[start] = true
  return result
end

--- @param self iteration_bfs
--- @return vector?, any
iteration._bfs_mt.__call = function(self)
  if self._last then
    for _, d in ipairs(vector.directions) do
      local p = self._last + d
      if self._base:can_fit(p) and not self._seen[p] then
        self._seen[p] = true
        table.insert(self._next, p)
      end
    end
  end

  self._last = table.remove(self._next, 1)
  return self._last, self._base[self._last]
end

bfs_methods.discard = function(self)
  self._last = nil
end


return grid
