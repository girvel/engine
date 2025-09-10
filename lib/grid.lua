local vector = require("engine.lib.vector")

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
--- @return any
methods.iter = function(self)
  return Fun.iter(pairs(self._inner_array))
end

--- @generic T
--- @param self grid<T>
--- @param start vector
--- @param max_radius? integer
--- @return vector?
methods.find_free_position = function(self, start, max_radius)
  -- TODO OPT can be optimized replacing slow_get with fast_get + min/max
  if self[start] == nil then return start end

  max_radius = math.min(
    max_radius or math.huge,
    math.max(
      start[1] - 1,
      start[2] - 1,
      self.size[1] - start[1],
      self.size[2] - start[2]
    ) * 2
  )

  for r = 1, max_radius do
    for x = 0, r - 1 do
      local v = vector.new(x, x - r) + start
      if not self:slow_get(v, true) then return v end
    end

    for x = r, 1, -1 do
      local v = vector.new(x, r - x) + start
      if not self:slow_get(v, true) then return v end
    end

    for x = 0, 1 - r, -1 do
      local v = vector.new(x, x + r) + start
      if not self:slow_get(v, true) then return v end
    end

    for x = -r, 1 do
      local v = vector.new(x, -r - x) + start
      if not self:slow_get(v, true) then return v end
    end
  end

  return nil
end

--- @generic T
--- @param self grid<T>
--- @param x integer
--- @param y integer
--- @return integer
methods._get_inner_index = function(self, x, y)
  return x + (y - 1) * self.size[1]
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

return grid
