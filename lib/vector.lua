local vector = {}

--- @class vector: number[]
--- @field x number alias for `[1]`
--- @field y number alias for `[2]`
--- @field z number alias for `[3]`
--- @field w number alias for `[4]`
--- @field r number alias for `[1]`
--- @field g number alias for `[2]`
--- @field b number alias for `[3]`
--- @field a number alias for `[4]`
--- @operator add(vector): vector
--- @operator sub(vector): vector
--- @operator mul(number): vector
--- @operator div(number): vector
--- @operator unm(): vector
local vector_methods = {}
vector.mt = {}

--- @param ... number
--- @return vector
vector.new = function(...)
  return vector.own({...})
end

--- @param t number[]
--- @return vector
vector.own = function(t)
  return setmetatable(t, vector.mt)
end

--- @param size integer
--- @param f fun(): number
vector.filled = function(size, f)
  local result = {}
  for i = 1, size do
    result[i] = f()
  end
  return vector.own(result)
end

vector.zero = vector.new(0, 0)
vector.one = vector.new(1, 1)
vector.up = vector.new(0, -1)
vector.down = vector.new(0, 1)
vector.left = vector.new(-1, 0)
vector.right = vector.new(1, 0)

--- @alias direction_name "up" | "left" | "down" | "right"

vector.direction_names = {"up", "left", "down", "right"}
vector.directions = {vector.up, vector.left, vector.down, vector.right}
vector.extended_directions = {
  vector.up, vector.left, vector.down, vector.right,
  vector.new(1, 1), vector.new(1, -1), vector.new(-1, -1), vector.new(-1, 1)
}

--- @param v vector
--- @return string?
vector.name_from_direction = function(v)
  if v == vector.up then return "up" end
  if v == vector.down then return "down" end
  if v == vector.left then return "left" end
  if v == vector.right then return "right" end
end

--- @param f fun(n: number): number
--- @param ... vector
--- @return vector
vector.use = function(f, ...)
  local zip = {}
  for i = 1, select("#", ...) do
    for j, value in ipairs(select(i, ...)) do
      if i == 1 then
        zip[j] = {}
      end
      zip[j][i] = value
    end
  end
  local result = {}
  for _, v in ipairs(zip) do
    table.insert(result, f(unpack(v)))
  end
  return vector.own(result)
end

vector.mt.__eq = function(self, other)
  if #self ~= #other then return false end
  for i = 1, #self do
    if self[i] ~= other[i] then return false end
  end
  return true
end

vector.mt.__add = function(self, other)
  return self:copy():add_mut(other)
end

vector.mt.__sub = function(self, other)
  return self:copy():sub_mut(other)
end

vector.mt.__mul = function(self, other)
  if type(self) == "number" then
    self, other = other, self
  end
  return self:copy():mul_mut(other)
end

vector.mt.__div = function(self, other)
  if type(self) == "number" then
    self, other = other, self
  end
  return self:copy():div_mut(other)
end

vector.mt.__unm = function(self)
  return vector.new(unpack(self)):unm_mut()
end

vector.mt.__tostring = function(self)
  local result = "{"
  for i, value in ipairs(self) do
    if i > 1 then
      result = result .. "; "
    end
    result = result .. value
  end
  return result .. "}"
end

vector.mt.__le = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(self) do
    if value > other[i] then return false end
  end
  return true
end

vector.mt.__lt = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(self) do
    if value >= other[i] then return false end
  end
  return true
end

vector.mt.__ge = function(self, other)
  return other <= self
end

vector.mt.__gt = function(self, other)
  return other < self
end


--- @generic T
--- @param self T
--- @return T
vector_methods.copy = function(self)
  return vector.new(unpack(self))
end

--- @generic T
--- @param self T
--- @param other vector
--- @return T
vector_methods.add_mut = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(other) do
    self[i] = self[i] + value
  end
  return self
end

--- @generic T
--- @param self T
--- @param other vector
--- @return T
vector_methods.sub_mut = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(other) do
    self[i] = self[i] - value
  end
  return self
end

--- @generic T
--- @param self T
--- @param other number
--- @return T
vector_methods.mul_mut = function(self, other)
  for i = 1, #self do
    self[i] = self[i] * other
  end
  return self
end

--- @generic T
--- @param self T
--- @param other number
--- @return T
vector_methods.div_mut = function(self, other)
  for i = 1, #self do
    self[i] = self[i] / other
  end
  return self
end

--- @generic T
--- @param self T
--- @return T
vector_methods.unm_mut = function(self)
  for i, value in ipairs(self) do
    self[i] = -value
  end
  return self
end

--- @param self vector
--- @param f fun(n: number): number
--- @return vector
vector_methods.map_mut = function(self, f)
  for i, value in ipairs(self) do
    self[i] = f(value)
  end
  return self
end

--- @param self vector
--- @param f fun(n: number): number
--- @return vector
vector_methods.map = function(self, f)
  return self:copy():map_mut(f)
end

--- @param self vector
--- @return number
vector_methods.abs = function(self)
  local result = 0
  for _, value in ipairs(self) do
    result = result + math.abs(value)
  end
  return result
end

local sign = function(x)
  if x > 0 then return 1 end
  if x < 0 then return -1 end
  return 0
end

--- @param self vector
--- @return vector
vector_methods.normalized2 = function(self)
  assert(#self == 2)
  if math.abs(self[1]) > math.abs(self[2]) then
    return vector({sign(self[1]), 0})
  elseif self[2] ~= 0 then
    return vector({0, sign(self[2])})
  else
    error("Can not normalize Vector.zero")
  end
end

--- @param self vector
--- @return vector
vector_methods.normalized = function(self)
  local abs = self:abs()
  if abs == 0 then return vector.fill(#self, function() return 0 end) end
  return self / abs
end

local SWIZZLE_BASES = {
  {
    x = 1,
    y = 2,
    z = 3,
    w = 4,
  },
  {
    r = 1,
    g = 2,
    b = 3,
    a = 4,
  },
}

vector.mt.__index = function(self, key)
  local method = vector_methods[key]
  if method then return method end

  for _, base in ipairs(SWIZZLE_BASES) do
    local index = base[key]
    if index then
      return self[index]
    end
  end

  error(("No .%s in vector"):format(key))
end

return vector
