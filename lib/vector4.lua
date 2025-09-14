local ffi = require("ffi")
local ffi_fix = require("engine.tech.ffi_fix")


local vector4 = {}
local SIZE = 4

ffi.cdef [[
  typedef struct {
    double items[4];
  } Std_doublex4;
]]
local c = ffi_fix.load("libvector")

--- @class vector4
--- @field items number[]
local methods = {}

vector4.mt = {__index = methods}
local vector4_cdata_type = ffi.metatype("Std_doublex4", vector4.mt);

--- @return vector4
vector4.new = function(...)
  local n = select("#", ...)
  assert(n == SIZE)

  local result = vector4_cdata_type()  --[[@as vector4]]
  for i = 1, n do
    result.items[i - 1] = select(i, ...)
  end

  return result
end

local NUMBER_LENGTH = 2

--- Creates vector from its hexadecimal representation; each coordinate is between 0 and 1
--- @param hex string
--- @return vector4
vector4.hex = function(hex)
  assert(#hex == 6 or #hex == 8)

  local result = vector4_cdata_type()  --[[@as vector4]]
  local d = 16 ^ NUMBER_LENGTH - 1
  for i = 1, #hex, NUMBER_LENGTH do
    result.items[(i - 1) / NUMBER_LENGTH] = tonumber(hex:sub(i, i + NUMBER_LENGTH - 1), 16) / d
  end

  if #hex == 6 then
    result.items[3] = 1
  end

  return result
end

vector4.white = vector4.new(1, 1, 1, 1)
vector4.black = vector4.new(0, 0, 0, 1)

--- @return number, number, number, number
methods.unpack = function(self)
  return self.items[0], self.items[1], self.items[2], self.items[3]
end

vector4.mt.__tostring = function(self)
  local result = "{"
  for i = 0, SIZE - 1 do
    if i > 0 then
      result = result .. "; "
    end
    result = result .. self.items[i]
  end
  return result .. "}"
end

Ldump.mark(vector4, {mt = "const"}, ...)
return vector4
