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
